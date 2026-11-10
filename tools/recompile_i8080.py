#!/usr/bin/env python3
"""Рекомпиляция КОДА ИГРЫ Z80 -> i8080 (Вектор-06Ц, КР580ВМ80А) — Basket.

Форк tools/recompile_i8080.py из spirits-v06c (там же история правил и
грабель).  Отличия Basket: вход один — disasm/v06/game.asm
(tools/disasm_v06.py); ВСЕ данные остаются на своих адресах (адаптер и
сборщик ссылаются на переменные игры), двигается только код: он ложится в
бывшие участки кода и в доказанно свободные зоны (cfg/current_memory_map.json
dead_*/sprite_trim_gap_*).

  python3 tools/recompile_i8080.py            # -> src/i8080/game.asm, build/i8080/
  python3 tools/recompile_i8080.py --audit    # плюс разбор флагов и мёртвого кода

Вход  — disasm/msx/v06/{spirits2_head,spirits2_tail,resident}.asm, дизасм
        игры В РАСКЛАДКЕ ВЕКТОРА (эталон Z80, tools/verify_v06.py).
Выход — src/i8080/game.asm: те же метки, тот же смысл, подмножество i8080.

ГЛАВНОЕ ПРАВИЛО (docs/recompilation.md, §1): образ ПЕРЕСОБИРАЕТСЯ ПО
МЕТКАМ.  Код растёт (jr -> jp, эмуляция IX/IY, развёртки CB), поэтому
адреса меняются, и всё, что раньше указывало на КОНКРЕТНЫЙ АДРЕС кода
игры — врезки сборщика, таблицы SCR_PATCH адаптера, стенды, — обязано
брать адрес из карты `build/i8080/labels.json` / `src/v06/game_labels.inc`.
Карта полная: у каждой исходной команды есть метка `Z_<адрес Z80>`.

Три файла сливаются в один: только так `equ` одного куска на метку
другого превращается в настоящую ссылку и переезжает сам.
"""
from __future__ import annotations

import shutil
import argparse
import json
import re
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "disasm/v06"
FILES = ["game"]
OUT_ASM = ROOT / "src/i8080/game.asm"
OUTDIR = ROOT / "build/i8080"

# ---------------------------------------------------------------------------
# РАЗБОР ДИЗАСМА
# ---------------------------------------------------------------------------
RX_EQU = re.compile(r"^([\w.$]+):\s*equ\s+(\S+)")
RX_LAB = re.compile(r"^([\w.$]+):\s*$")
RX_DIR = re.compile(r"^\s+(\S+)(?:\s+(.*?))?\s*$")
RX_ADDR = re.compile(r"^;\s*([0-9A-F]{4})(?:\s+((?:[0-9A-F]{2} )*[0-9A-F]{2}))?")


class Item:
    __slots__ = ("kind", "addr", "mn", "ops", "raw", "cmt", "nbytes", "labels",
                 "file", "line", "lines", "size", "native")

    def __init__(self, **kw):
        for k in self.__slots__:
            setattr(self, k, kw.get(k))


def parse(name: str):
    """(equs, items) одного куска дизасма."""
    equs, items, pending = [], [], []
    for lineno, line in enumerate(
            (SRC / f"{name}.asm").read_text(encoding="utf-8").splitlines(), 1):
        ci = line.find(";")
        code = line[:ci] if ci >= 0 else line
        cmt = line[ci:] if ci >= 0 else ""
        if not code.strip():
            continue
        m = RX_EQU.match(code)
        if m:
            equs.append((m.group(1), m.group(2)))
            continue
        m = RX_LAB.match(code.rstrip())
        if m:
            pending.append(m.group(1))
            continue
        m = RX_DIR.match(code)
        if not m:
            sys.exit(f"{name}.asm:{lineno}: не разобрана строка {line!r}")
        mn = m.group(1).lower()
        ops = (m.group(2) or "").strip()
        am = RX_ADDR.match(cmt.strip())
        addr = int(am.group(1), 16) if am else None
        by = am.group(2).split() if (am and am.group(2)) else None
        if mn == "org":
            items.append(Item(kind="org", addr=int(ops, 0), labels=[],
                              file=name, line=lineno))
            continue
        if mn in ("db", "dw"):
            n = len(by) if by else None
            if n is None:              # длину db/dw считаем сами
                n = sum((2 if mn == "dw" else 1)
                        for _ in split_ops(ops))
            items.append(Item(kind="data", addr=addr, mn=mn, ops=ops, raw=code,
                              cmt=cmt, nbytes=n, labels=pending, file=name,
                              line=lineno))
            pending = []
            continue
        if by is None:
            sys.exit(f"{name}.asm:{lineno}: у команды нет байтов в комментарии")
        pending = [x for x in pending if x != "Z_%04X" % addr]   # recompiler adds Z_
        items.append(Item(kind="code", addr=addr, mn=mn, ops=split_ops(ops),
                          raw=code, cmt=cmt, nbytes=len(by), labels=pending,
                          file=name, line=lineno))
        pending = []
    if pending:
        sys.exit(f"{name}.asm: метки в конце файла без команды: {pending}")
    return equs, items


def split_ops(s: str):
    """Разбить операнды по запятым ВНЕ скобок."""
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


# ---------------------------------------------------------------------------
# РАСКЛАДКА: что приколочено к адресу и какие куски свободны
# ---------------------------------------------------------------------------
# ГОЛОВА 02A0..0446 ЧИТАЕТСЯ КАК ГРАФИКА.  res:23E9 кладёт в операнд
# 2:CD36 базу LOW_TILE_SRC = 0x01F4 и печатает логотип «topo SOFT»
# индексами из D_240E: адрес глифа = база + (индекс-1)*8.  Индексы
# 0x18, 0x21..0x30, 0x3B, 0x41..0x43 дают ровно эти четыре куска — то
# есть БАЙТЫ КОМАНД головы служат образами знакомест.  Их нельзя ни
# переводить, ни двигать: кладём как db на свои адреса.
PIN = []

# Данные Basket не двигаются: FIXED и свободные куски считаются по дизасму
# (configure_layout), а не задаются руками.
FIXED: list = []
REGIONS: list = []
TAIL_REGIONS: list = []
RT_REGION = None

# Ячейки рантайма — в мёртвой зоне 92FF..9329 (tools/build_v06_rom.py
# DEAD_CODE), из раскладки кода исключены.
# ОБРАБОТЧИК ПРЕРЫВАНИЯ ИГРЫ (36F3, вход через GAME_ISR_HOOK) зовёт код с
# хелперами (ix+d) и il_ldir.  Их ячейки общие с основным потоком: прерывание
# посреди развёртки испортило бы il_tmp/il_tmp2/il_f/il_a/il_d.  Z80 сохранял
# IX/IY сам (`push ix`/`push iy` — это ячейки z80_ix/z80_iy); остальное
# сохраняется здесь: после `push de` и до `pop de` — сами `push ix`/`push iy`
# в переводе идут через il_tmp.
ISR_SAVE = {
    0x36FD: ("after", ["ld hl,(il_tmp)", "push hl", "ld hl,(il_tmp2)", "push hl",
                       "ld hl,(il_f)", "push hl", "ld hl,(il_a)", "push hl"]),
    0x370F: ("before", ["pop hl", "ld (il_a),hl", "pop hl", "ld (il_f),hl",
                        "pop hl", "ld (il_tmp2),hl", "pop hl", "ld (il_tmp),hl"]),
}
# РУЧНЫЕ ЗАМЕНЫ: самомодификация в развёрнутую команду.  3846 (MSX D5DE,
# опрос клавиши): `ld (Z_385D+1),a` вписывает номер бита во второй байт
# `bit 0,(hl)`; у i8080 `bit` развёрнут, и запись портила бы соседний байт.
# Здесь маска бита считается в il_d, A после — как у Z80 (байт 46h|бит<<3).
HAND = {
    0x385A: ["ld (il_a),a", "rrca", "rrca", "rrca", "and 7", "push bc", "ld c,a",
             "ld a,1", "inc c", "{u}_l:", "dec c", "jp z,{u}_d", "add a,a", "jp {u}_l",
             "{u}_d:", "ld (il_d),a", "pop bc"],
    0x385D: ["ld a,(il_d)", "and (hl)", "ld a,(il_a)"],
}
RT_VARS_ADDR = 0x9300
RT_VARS_HI = 0x9320

# Зоны, где адаптер (src/v06/*.asm) сидит внутри окна игры: туда код игры не
# кладём (те же, что ADAPTER_HOLES в tools/disasm_v06.py).
HOLES = [(0x34BD, 0x352A), (0xA0D0, 0xA132), (0xA521, 0xA534)]

OVERLAP: dict = {}
OPERAND_PATCH: dict = {}


def proven_free():
    """Доказанно свободные куски (classify_memory_v06) — под код."""
    m = json.loads((ROOT / "cfg/current_memory_map.json").read_text())
    out = []
    for r in m["regions"]:
        if r.get("class") == "reclaimable_padding" and r.get("prove_free"):
            lo, hi = int(r["lo"], 16), int(r["hi"], 16) - 1
            if hi - lo >= 15:
                out.append((lo, hi))
    return sorted(out)


PROVEN: list = []


def in_proven(it) -> bool:
    return any(lo <= it.addr and it.addr + it.nbytes - 1 <= hi for lo, hi in PROVEN)


def configure_layout(items):
    """FIXED = все данные на своих местах; куски под код = бывший код +
    свободные зоны, минус ячейки рантайма и дыры адаптера."""
    global FIXED, REGIONS, RT_REGION, PROVEN
    # Данные внутри доказанно свободных зон (нули, их никто не читает) не
    # держат адрес и не переносятся: зона целиком идёт под код.
    PROVEN = proven_free()
    data = sorted((it.addr, it.addr + it.nbytes - 1) for it in items
                  if it.kind == "data" and it.addr is not None and not in_proven(it))
    FIXED = merge(data)
    code = sorted((it.addr, it.addr + it.nbytes - 1) for it in items
                  if it.kind == "code" and it.addr is not None)
    free = merge(code + proven_free())
    cut = [(RT_VARS_ADDR, RT_VARS_HI)] + HOLES + FIXED
    free = subtract(free, cut)
    free = [r for r in free if r[1] - r[0] >= 7]
    big = max(free, key=lambda r: r[1] - r[0])
    RT_REGION = big
    REGIONS = [r for r in free if r != big]


def merge(rs):
    out = []
    for lo, hi in sorted(rs):
        if out and lo <= out[-1][1] + 1:
            out[-1] = (out[-1][0], max(out[-1][1], hi))
        else:
            out.append((lo, hi))
    return out


def subtract(rs, cuts):
    out = []
    for lo, hi in rs:
        segs = [(lo, hi)]
        for c0, c1 in cuts:
            nxt = []
            for a, b in segs:
                if c1 < a or c0 > b:
                    nxt.append((a, b))
                    continue
                if a < c0:
                    nxt.append((a, c0 - 1))
                if c1 < b:
                    nxt.append((c1 + 1, b))
            segs = nxt
        out += segs
    return out


# ---------------------------------------------------------------------------
# ЯЧЕЙКИ РАНТАЙМА
# ---------------------------------------------------------------------------
# z80_ix/z80_iy — регистры-индексы; il_tmp/il_tmp2 — сохранение HL;
# il_a — сохранение A; il_f — сохранение AF хелперами; z80_af_alt —
# теневой AF для `ex af,af'`; z80_r — замена регистру R (см. RND).
CELLS = ["z80_ix", "z80_iy", "il_tmp", "il_tmp2", "il_f", "z80_af_alt",
         "z80_bc2", "z80_de2", "z80_hl2"]
CELLS8 = ["il_a", "il_d", "z80_r"]

# ---------------------------------------------------------------------------
# РАЗВОРАЧИВАНИЕ КОМАНД Z80, КОТОРЫХ У i8080 НЕТ
# ---------------------------------------------------------------------------
_UID = [0]


def uniq(stem: str) -> str:
    _UID[0] += 1
    return f"il_{stem}{_UID[0]}"


R8 = ("a", "b", "c", "d", "e", "h", "l")


def is_idx(ops, mn):
    """('z80_ix'|'z80_iy') если команда трогает индексный регистр."""
    t = (mn + " " + ",".join(ops)).lower()
    if re.search(r"\(ix|\bix\b|\bixh\b|\bixl\b", t):
        return "z80_ix"
    if re.search(r"\(iy|\biy\b|\biyh\b|\biyl\b", t):
        return "z80_iy"
    return None


def shift_body(op):
    """Тело сдвига над A.  ВНИМАНИЕ: у i8080 RAR/RAL ставят ТОЛЬКО CY,
    Z80 же у sla/srl/rr/rl считает ещё Z/S/P от результата.  Где игра
    читает Z после сдвига, к телу добавляется `or a` (см. need_z)."""
    return {"sla": ["add a,a"],
            "sll": ["add a,a", "or 0x01"],
            "rlc": ["rlca"],
            "rrc": ["rrca"],
            "rl":  ["rla"],
            "rr":  ["rra"],
            "srl": ["or a", "rra"],
            "sra": ["ld (il_d),a", "add a,a", "ld a,(il_d)", "rra"]}[op]


def x_shift(op, reg, need_z):
    body = shift_body(op)
    if need_z and op in ("srl", "rr", "rl", "rlc", "rrc"):
        # Z/S/P пересчитываются `or a`, но он СБРАСЫВАЕТ CY.  Годится
        # только там, где CY после сдвига не читают (это и проверяет
        # разбор флагов).
        body = body + ["or a"]
    if reg == "a":
        return body
    if reg == "(hl)":
        return ["ld (il_a),a", "ld a,(hl)", *body, "ld (hl),a", "ld a,(il_a)"]
    return ["ld (il_a),a", f"ld a,{reg}", *body, f"ld {reg},a", "ld a,(il_a)"]


def keep_cy(seq):
    """Wrap an `and`-based BIT so CY survives (Z80 BIT keeps it): the
    sequence runs twice, the CY=1 branch ends with scf (STC: CY only)."""
    u, d = uniq("KC"), uniq("KD")
    i = next(k for k, x in enumerate(seq) if x.startswith("and "))
    return ([f"jp c,{u}"] + seq + [f"jp {d}", f"{u}:"] + seq[:i + 1] + ["scf"] +
            seq[i + 1:] + [f"{d}:"])


def x_bit(n, reg):
    """bit n,r: Z = (бит == 0).  A и HL целы; CY ПОРТИТСЯ (`and` его
    сбрасывает), у Z80 bit CY сохраняет — проверяется разбором флагов."""
    mask = "0x%02X" % (1 << int(n, 0))
    if reg == "a":
        return ["ld (il_a),a", f"and {mask}", "ld a,(il_a)"]
    if reg == "(hl)":
        return ["ld (il_a),a", "ld a,(hl)", f"and {mask}", "ld a,(il_a)"]
    return ["ld (il_a),a", f"ld a,{reg}", f"and {mask}", "ld a,(il_a)"]


def x_resset(op, n, reg):
    b = int(n, 0)
    alu = ("and 0x%02X" % (0xFF ^ (1 << b))) if op == "res" else "or 0x%02X" % (1 << b)
    if reg == "a":
        return ["push af", alu, "ld (il_a),a", "pop af", "ld a,(il_a)"]
    if reg == "(hl)":
        return ["push af", "ld a,(hl)", alu, "ld (hl),a", "pop af"]
    return ["push af", f"ld a,{reg}", alu, f"ld {reg},a", "pop af"]


def x_adcsbc_hl(op, rp, need_z):
    """adc/sbc hl,rp побайтно.  Z у Z80 — от ВСЕХ 16 бит; цепочка даёт
    Z только от старшего байта, поэтому при живом Z доклеивается
    пересчёт (CY восстанавливается через scf)."""
    # A у Z80 не меняется (в Basket 39A3 это счётчик цикла деления):
    # сохраняется в il_a, восстановление флагов не трогает.
    hi, lo = rp[0], rp[1]
    a = "adc" if op == "adc" else "sbc"
    seq = ["ld (il_a),a", "ld a,l", f"{a} a,{lo}", "ld l,a", "ld a,h", f"{a} a,{hi}", "ld h,a"]
    if not need_z:
        return seq + ["ld a,(il_a)"]
    done, cset = uniq("AS"), uniq("ASC")
    return seq + [f"jp nz,{done}", f"jp c,{cset}", "ld a,l", "or a",
                  f"jp {done}", f"{cset}:", "ld a,l", "or a", "scf",
                  f"{done}:", "ld a,(il_a)"]


def x_ld16(ops):
    """ld bc/de,(nn) и ld (nn),bc/de через HL (HL и флаги целы)."""
    dst, src = ops[0], ops[1]
    dl, sl = dst.lower(), src.lower()
    mem = lambda t: t.startswith("(") and t.endswith(")")
    if dl in ("bc", "de") and mem(src):
        nn = src[1:-1].strip()
        return ["push hl", f"ld hl,({nn})", f"ld {dl[0]},h", f"ld {dl[1]},l",
                "pop hl"]
    if sl in ("bc", "de") and mem(dst):
        nn = dst[1:-1].strip()
        return ["push hl", f"ld h,{sl[0]}", f"ld l,{sl[1]}", f"ld ({nn}),hl",
                "pop hl"]
    if sl == "sp" and mem(dst):                      # ld (nn),sp: HL, flags kept
        return ["ld (il_tmp),hl", "push af", "ld hl,2", "add hl,sp",
                f"ld {dst},hl", "pop af", "ld hl,(il_tmp)"]
    if dl == "sp" and mem(src):                      # ld sp,(nn)
        return ["ld (il_tmp),hl", f"ld hl,{src}", "ld sp,hl", "ld hl,(il_tmp)"]
    return None


def x_exaf():
    """ex af,af' через теневую ячейку.  HL сохраняется (il_tmp2)."""
    return ["ld (il_tmp2),hl", "push af", "pop hl", "ld (il_f),hl",
            "ld hl,(z80_af_alt)", "push hl", "pop af", "ld hl,(il_f)",
            "ld (z80_af_alt),hl", "ld hl,(il_tmp2)"]


# ---------------------------------------------------------------------------
# IX/IY
# ---------------------------------------------------------------------------
# ДВА СПОСОБА, ВЫБОР ПО ГОРЯЧЕСТИ (docs/recompilation.md, §4).
#   * РАЗВЁРТКА НА МЕСТЕ — для сайтов, которые профиль (tools/prof_pc_v06js.js)
#     исполняет чаще HOT_IX раз за итерацию.  10+|d| байт, ~55+5|d| тактов,
#     НИ A, НИ ФЛАГИ не портятся: адрес набирается цепочкой `inc hl`/`dec hl`,
#     а они у i8080 флагов не ставят.  При |d| > INC_MAX цепочка дороже
#     сложения, и тогда идёт сложение с сохранением AF через стек.
#   * ХЕЛПЕР — для холодных: `rst`/`call` + inline-байт смещения, 2..4 байта.
#     Контракт тот же (HL, A, флаги целы; DE/BC не трогаются), цена ~190 тактов.
INC_MAX = 6
FORCE_CHEAP = False          # only for the d-prologue rewrite (x_idx_pro)
IDX_RE = re.compile(r"\((i[xy])\s*([+-]\s*[^)]+)?\)", re.I)


def idx_disp(op):
    """Смещение из операнда вида (ix+0x04)/(iy-0x03) как ЧИСЛО."""
    m = IDX_RE.search(op)
    if not m:
        return None
    d = (m.group(2) or "0").replace(" ", "")
    return int(d, 0) if d else 0


def walk(cell, d):
    """HL = (cell) + d цепочкой inc/dec — без порчи A и флагов."""
    step = "inc hl" if d >= 0 else "dec hl"
    return [f"ld hl,({cell})"] + [step] * abs(d)


def addto(d):
    """HL += d сложением (портит A и ФЛАГИ)."""
    if d == 0:
        return []
    return ["ld a,l", f"add a,{d & 0xFF}", "ld l,a",
            "ld a,h", f"adc a,{(d >> 8) & 0xFF}", "ld h,a"]


def x_idx_inline(mn, ops, cell):
    """Развёртка (ix+d) на месте."""
    full = (mn + " " + ",".join(ops)).lower()
    # --- операции над самим регистром-индексом
    if mn == "push":
        return ["ld (il_tmp),hl", f"ld hl,({cell})", "push hl", "ld hl,(il_tmp)"]
    if mn == "pop":
        return ["ld (il_tmp),hl", "pop hl", f"ld ({cell}),hl", "ld hl,(il_tmp)"]
    if mn == "ld" and ops[0].lower() in ("ix", "iy"):
        return ["ld (il_tmp),hl", f"ld hl,{ops[1]}", f"ld ({cell}),hl",
                "ld hl,(il_tmp)"]
    if mn == "ld" and len(ops) == 2 and ops[1].lower() in ("ix", "iy") \
            and ops[0].startswith("("):                   # ld (nn),ix
        return ["ld (il_tmp),hl", f"ld hl,({cell})", f"ld {ops[0]},hl",
                "ld hl,(il_tmp)"]
    if mn == "ld" and len(ops) == 2 and ops[1].lower() in ("ixl", "iyl"):
        return [f"ld {ops[0]},({cell})"] if ops[0].lower() == "a" else None
    if mn == "ld" and ops[0].lower() in ("ixh", "iyh"):
        return ["push af", f"ld a,{ops[1]}", f"ld ({cell}+1),a", "pop af"]
    if mn == "ld" and ops[0].lower() in ("ixl", "iyl"):
        return ["push af", f"ld a,{ops[1]}", f"ld ({cell}),a", "pop af"]
    if mn in ("inc", "dec") and ops[0].lower() in ("ix", "iy"):
        return ["ld (il_tmp),hl", f"ld hl,({cell})", mn + " hl",
                f"ld ({cell}),hl", "ld hl,(il_tmp)"]
    if mn == "add" and ops[0].lower() in ("ix", "iy"):
        rp = ops[1].lower()
        add = "add hl,hl" if rp in ("ix", "iy") else f"add hl,{rp}"
        return ["ld (il_tmp),hl", f"ld hl,({cell})", add, f"ld ({cell}),hl",
                "ld hl,(il_tmp)"]
    if mn == "jp":
        return [f"ld hl,({cell})", "jp (hl)"]
    # --- обращение к ячейке (ix+d)
    mi = next((i for i, o in enumerate(ops) if IDX_RE.search(o)), None)
    if mi is None:
        return None
    d = idx_disp(ops[mi])
    cheap = abs(d) <= INC_MAX or FORCE_CHEAP
    pre = ["ld (il_tmp2),hl"] + (walk(cell, d) if cheap
                                else [f"ld hl,({cell})"] + addto(d))
    post = ["ld hl,(il_tmp2)"]
    if mn == "ld" and mi == 1 and ops[0].lower() in ("h", "l"):   # ld h|l,(ix+d)
        # HL is restored from il_tmp2 afterwards: the byte goes into that copy
        # (a plain `ld l,(hl)` was overwritten by the restore: 9607, 05.11).
        off = "" if ops[0].lower() == "l" else "+1"
        if cheap:
            return (["ld (il_a),a"] + pre + ["ld a,(hl)", f"ld (il_tmp2{off}),a"] +
                    post + ["ld a,(il_a)"])
        return (["push af"] + pre + ["ld a,(hl)", f"ld (il_tmp2{off}),a"] + post +
                ["pop af"])
    if mn == "ld" and mi == 1:                       # ld r,(ix+d)
        r = ops[0].lower()
        body = ["ld a,(hl)"] if r == "a" else [f"ld {r},(hl)"]
        return (pre + body + post) if cheap else \
            (["push af"] + pre + (["ld a,(hl)", "ld (il_a),a"] if r == "a"
                                  else [f"ld {r},(hl)"]) + post +
             (["pop af", "ld a,(il_a)"] if r == "a" else ["pop af"]))
    if mn == "ld" and mi == 0:                       # ld (ix+d),r | n
        s = ops[1].strip()
        sl = s.lower()
        if cheap:
            if sl in ("h", "l"):
                off = "" if sl == "l" else "+1"
                return (["ld (il_a),a", "ld (il_tmp2),hl"] + walk(cell, d) +
                        [f"ld a,(il_tmp2{off})", "ld (hl),a"] + post +
                        ["ld a,(il_a)"])
            return pre + [f"ld (hl),{s}"] + post
        if sl == "a":
            return (["push af", "ld (il_a),a", "ld (il_tmp2),hl",
                     f"ld hl,({cell})"] + addto(d) +
                    ["ld a,(il_a)", "ld (hl),a"] + post + ["pop af"])
        if sl in ("h", "l"):
            off = "" if sl == "l" else "+1"
            return (["push af", "ld (il_tmp2),hl", f"ld hl,({cell})"] +
                    addto(d) + [f"ld a,(il_tmp2{off})", "ld (hl),a"] + post +
                    ["pop af"])
        return (["push af", "ld (il_tmp2),hl", f"ld hl,({cell})"] + addto(d) +
                [f"ld (hl),{s}"] + post + ["pop af"])
    if mn in ("inc", "dec"):                          # флаги = результат
        if cheap:
            return (["ld (il_a),a", "ld (il_tmp2),hl"] + walk(cell, d) +
                    [f"{mn} (hl)"] + post + ["ld a,(il_a)"])
        return (["ld (il_a),a", "ld (il_tmp2),hl", f"ld hl,({cell})"] +
                addto(d) + [f"{mn} (hl)"] + post + ["ld a,(il_a)"])
    if mn in ("add", "adc", "sub", "sbc", "and", "xor", "or", "cp"):
        alu = {"add": "add a,", "adc": "adc a,", "sub": "sub ", "sbc": "sbc a,",
               "and": "and ", "xor": "xor ", "or": "or ", "cp": "cp "}[mn]
        if cheap:
            return pre + [f"{alu}(hl)"] + post
        return (["ld (il_a),a", "ld (il_tmp2),hl", f"ld hl,({cell})"] +
                addto(d) + ["ld a,(il_a)", f"{alu}(hl)"] + post)
    if mn == "bit":
        if cheap:
            return (["ld (il_a),a", "ld (il_tmp2),hl"] + walk(cell, d) +
                    ["ld a,(hl)", "and 0x%02X" % (1 << int(ops[0], 0))] + post + ["ld a,(il_a)"])
    if mn in ("res", "set"):
        nb = int(ops[0], 0)
        alu = ("and 0x%02X" % (0xFF ^ (1 << nb))) if mn == "res" else "or 0x%02X" % (1 << nb)
        if cheap:
            return (["push af", "ld (il_tmp2),hl"] + walk(cell, d) +
                    ["ld a,(hl)", alu, "ld (hl),a"] + post + ["pop af"])
        return (["push af", "ld (il_tmp2),hl", f"ld hl,({cell})"] + addto(d) +
                ["ld a,(hl)", alu, "ld (hl),a"] + post + ["pop af"])
    if mn == "bit":                                    # far displacement
        return (["ld (il_a),a", "ld (il_tmp2),hl", f"ld hl,({cell})"] + addto(d) +
                ["ld a,(hl)", "and 0x%02X" % (1 << int(ops[0], 0))] + post + ["ld a,(il_a)"])
    return None


ALU = {"add": "add a,", "adc": "adc a,", "sub": "sub ", "sbc": "sbc a,",
       "and": "and ", "xor": "xor ", "or": "or ", "cp": "cp "}
TWO = ("stn", "set", "res", "bit")      # формы с ДВУМЯ inline-байтами
_ix_used: set = set()
_ix_cnt: dict = {}
_ix_rst: dict = {}
# Basket: soft VDP RSTs and RST 00 are free; page 0 jumps to the helpers.
# RST 18 is the game's character output. Page 0 is also read as data once:
# the silent tune 7F49 copies 30 bytes from 0000 into the voice states
# AC25.. (tools/block_equiv.js, AA85); its three voices are off (pointer 0,
# AB35 skips them) and the next tune copies its own, so the RST bytes there
# change nothing audible.
RST_SLOTS: list = [0x08, 0x10, 0x20, 0x28, 0x30, 0x00]
RST_RND = None              # с 0100, и 0008..0037 пришлось бы класть кодом


def ix_form(mn, ops):
    """Имя компактной формы или None (тогда только развёртка на месте)."""
    if mn in ("push", "pop", "jp"):
        return None
    if any(o.lower() in ("ix", "iy", "ixh", "iyh", "ixl", "iyl") for o in ops):
        return None
    mi = next((i for i, o in enumerate(ops) if IDX_RE.search(o)), None)
    if mi is None:
        return None
    if mn == "ld":
        if mi == 1:
            r = ops[0].lower()
            return "ld" + r if r in R8 else None
        s = ops[1].strip().lower()
        return ("st" + s) if s in R8 else "stn"
    if mn in ("inc", "dec", "bit", "res", "set") or mn in ALU:
        return mn
    return None


# D-PROLOGUES (after scubadive-i8080 genspec): a cold site whose (ix+d) is
# called often on the i8080 image keeps its operation in place and calls a
# shared prologue il_p_<ix|iy>_<d>: il_tmp2 = HL, HL = IX+d, A and flags
# intact.  ~95+5|d| cycles instead of ~270; +3 bytes per site, one prologue
# per distinct d.  Sites are taken by gain per byte within PRO_BYTES.
# Off by default (06.11): PRO_BYTES=150 took 16 sites (24 calls/iter) and
# saved ~9k helper cycles, about 1% of an iteration — less than the memory
# is worth while the sprite pipeline still needs room.
PRO_MIN = float(os.environ.get("PRO_MIN", "0.3"))
PRO_BYTES = int(os.environ.get("PRO_BYTES", "0"))
PRO_SITES: set = set()     # Z80-адреса сайтов, идущих через пролог
_pro_used: set = set()     # (px, d)


def x_idx_pro(mn, ops, cell):
    """Развёртка на месте, где набор адреса заменён вызовом пролога."""
    global FORCE_CHEAP
    FORCE_CHEAP = True
    try:
        body = x_idx_inline(mn, ops, cell)
    finally:
        FORCE_CHEAP = False
    if body is None:
        return None
    for i in range(len(body) - 1):
        if body[i] == "ld (il_tmp2),hl" and body[i + 1] == f"ld hl,({cell})":
            j = i + 2
            while j < len(body) and body[j] in ("inc hl", "dec hl"):
                j += 1
            mi = next(k for k, o in enumerate(ops) if IDX_RE.search(o))
            d = idx_disp(ops[mi])
            px = "ix" if cell == "z80_ix" else "iy"
            _pro_used.add((px, d))
            ds = ("m%d" % -d) if d < 0 else str(d)
            return body[:i] + [f"call il_p_{px}_{ds}"] + body[j:]
    return None


def pro_text():
    out = []
    for px, d in sorted(_pro_used):
        ds = ("m%d" % -d) if d < 0 else str(d)
        if abs(d) <= INC_MAX:
            body = ["ld (il_tmp2),hl"] + walk(f"z80_{px}", d) + ["ret"]
        else:
            body = (["ld (il_tmp2),hl", "push af", f"ld hl,(z80_{px})"] +
                    addto(d) + ["pop af", "ret"])
        out.append(f"il_p_{px}_{ds}:\n" +
                   "".join("                %s\n" % x for x in body))
    return "".join(out)


def est_size(lines):
    """Байты i8080 у строк развёртки (оценка для отбора)."""
    n = 0
    for x in lines:
        if x.endswith(":"):
            continue
        t = x.lower().replace(" ", "")
        if t.startswith(("jp", "call")) or re.search(r"\((?!hl\))[^)]*\)", t) \
                or re.match(r"ld(hl|de|bc|sp),[^(]", t):
            n += 3
        elif re.search(r",(0x)?[0-9a-f]+$", t) or re.match(r"(and|or|xor|cp|sub)(0x)?[0-9]", t):
            n += 2
        else:
            n += 1
    return n


def x_idx_compact(mn, ops, cell, addr=None):
    if addr in PRO_SITES:
        r = x_idx_pro(mn, ops, cell)
        if r is not None:
            return r
    px = "ix" if cell == "z80_ix" else "iy"
    form = ix_form(mn, ops)
    if form is None:
        return x_idx_inline(mn, ops, cell)
    mi = next(i for i, o in enumerate(ops) if IDX_RE.search(o))
    d = idx_disp(ops[mi]) & 0xFF
    _ix_used.add((px, form))
    name = f"il_{px}_{form}"
    op = "rst" if (px, form) in _ix_rst else "call"
    call = f"{op} {name}" if op == "call" else f"rst 0x{_ix_rst[(px, form)]:02X}"
    extra = []
    if form == "stn":
        extra = [ops[1].strip()]
    elif form == "bit":
        extra = ["0x%02X" % (1 << int(ops[0], 0))]
    elif form == "res":
        extra = ["0x%02X" % (0xFF ^ (1 << int(ops[0], 0)))]
    elif form == "set":
        extra = ["0x%02X" % (1 << int(ops[0], 0))]
    return [call, "db " + ", ".join([f"0x{d:02X}"] + extra)]


IL_INFRA = {
"il_pro1": """il_pro1:
                ld      (il_tmp2),hl
                push    af
                pop     hl
                ld      (il_f),hl       ; AF вызывателя: h = a, l = флаги
                pop     hl
                ld      (il_tmp),hl     ; возврат в обёртку
                pop     hl              ; возврат в тело хелпера
                ex      (sp),hl         ; на стеке возврат в тело, hl -> inline-байт
                ld      a,(hl)
                inc     hl
                ex      (sp),hl
                push    hl
                ld      hl,(il_tmp)
                push    hl
                ret
""",
"il_pro2": """il_pro2:
                ld      (il_tmp2),hl
                push    af
                pop     hl
                ld      (il_f),hl
                pop     hl
                ld      (il_tmp),hl
                pop     hl
                ex      (sp),hl
                ld      a,(hl)
                ld      (il_a),a        ; смещение
                inc     hl
                ld      a,(hl)
                ld      (il_d),a        ; маска/значение
                inc     hl
                ex      (sp),hl
                push    hl
                ld      hl,(il_tmp)
                push    hl
                ld      a,(il_a)
                ret
""",
"il_adr": """il_adr:                                 ; hl = (ix|iy), a = смещение СО ЗНАКОМ
                ld      (il_a),a
                add     a,a             ; CY = знак смещения
                ld      a,(il_a)
                jp      c,il_adrn
                add     a,l
                ld      l,a
                ret     nc
                inc     h
                ret
il_adrn:
                add     a,l
                ld      l,a
                ret     c
                dec     h
                ret
""",
"il_ret_hl": """il_ret_hl:                              ; вернуть HL (флаги не трогаются)
                ld      hl,(il_tmp2)
                ret
""",
"il_epi": """il_epi:                                 ; вернуть AF и HL вызывателя
                ld      hl,(il_f)
                push    hl
                pop     af
                ld      hl,(il_tmp2)
                ret
""",
"il_epi_a": """il_epi_a:                               ; флаги и HL вызывателя, a = прочитанное
                ld      hl,(il_f)
                push    hl
                pop     af
                ld      a,(il_a)
                ld      hl,(il_tmp2)
                ret
""",
"il_rnd": """il_rnd:                                 ; ЗАМЕНА `ld a,r` (docs/determinism.md)
                ld      a,(z80_r)       ; у i8080 регистра R нет; ряд ведёт
                add     a,0x9D          ; эта ячейка: +0x9D на чтение,
                ld      (z80_r),a       ; +1 на кадр (V_ISR связки)
                ret
""",
}


def ix_helper(px, form):
    pro = "                call    il_pro%s_%s\n" % ("2" if form in TWO else "", px)
    if form == "lda":
        body = ["ld a,(hl)", "ld (il_a),a", "jp il_epi_a"]
    elif form in ("ldb", "ldc", "ldd", "lde"):
        body = [f"ld {form[2]},(hl)", "jp il_epi"]
    elif form == "ldl":
        body = ["ld a,(hl)", "ld (il_tmp2),a", "jp il_epi"]
    elif form == "ldh":
        body = ["ld a,(hl)", "ld (il_tmp2+1),a", "jp il_epi"]
    elif form == "sta":
        body = ["ld a,(il_f+1)", "ld (hl),a", "jp il_epi"]
    elif form in ("stb", "stc", "std", "ste"):
        body = [f"ld (hl),{form[2]}", "jp il_epi"]
    elif form == "stl":
        body = ["ld a,(il_tmp2)", "ld (hl),a", "jp il_epi"]
    elif form == "sth":
        body = ["ld a,(il_tmp2+1)", "ld (hl),a", "jp il_epi"]
    elif form == "stn":
        body = ["ld a,(il_d)", "ld (hl),a", "jp il_epi"]
    elif form == "set":
        body = ["ld a,(il_d)", "or (hl)", "ld (hl),a", "jp il_epi"]
    elif form == "res":
        body = ["ld a,(il_d)", "and (hl)", "ld (hl),a", "jp il_epi"]
    elif form == "bit":                  # Z80 BIT keeps CY: from the saved F
        u = uniq("BITC")
        body = ["ld a,(il_f)", "rra", "ld a,(il_d)", f"jp c,{u}", "and (hl)",
                "ld a,(il_f+1)", "jp il_ret_hl", f"{u}:", "and (hl)", "scf",
                "ld a,(il_f+1)", "jp il_ret_hl"]
    elif form in ("inc", "dec"):
        body = [f"{form} (hl)", "ld a,(il_f+1)", "jp il_ret_hl"]
    elif form in ALU:
        body = ["ld a,(il_f+1)", f"{ALU[form]}(hl)", "jp il_ret_hl"]
    else:
        raise SystemExit("неизвестная форма " + form)
    sfx = "_b" if (px, form) in _ix_rst else ""
    return (f"il_{px}_{form}{sfx}:\n" + pro +
            "".join(("%s\n" if b.endswith(":") else "                %s\n") % b for b in body))


def ix_wrap(px, two):
    """Пролог тела хелпера (ix+d): один уровень вызова.  На входе стек
    [возврат в тело, возврат на место вызова -> inline-байты].  Выход: HL =
    (ix|iy) + d со знаком, il_tmp2 = HL, il_f = AF вызывателя, il_d = второй
    inline-байт (TWO), на стеке [возврат в тело, место после inline-байтов]."""
    n = "2" if two else ""
    u = uniq("ADRN")
    second = ("                inc     hl\n"
              "                ld      a,(hl)\n"
              "                ld      (il_d),a        ; маска/значение\n"
              "                dec     hl\n"
              "                ld      a,(hl)          ; смещение\n"
              "                inc     hl\n"
              "                inc     hl\n") if two else (
              "                ld      a,(hl)          ; смещение\n"
              "                inc     hl\n")
    return (f"il_pro{n}_{px}:\n"
            "                ld      (il_tmp2),hl\n"
            "                push    af\n"
            "                pop     hl\n"
            "                ld      (il_f),hl       ; AF вызывателя: h = a, l = флаги\n"
            "                pop     hl              ; возврат в тело\n"
            "                ex      (sp),hl         ; hl -> inline-байты\n"
            + second +
            "                ex      (sp),hl         ; на стеке место после байтов\n"
            "                push    hl              ; возврат в тело\n"
            f"                ld      hl,(z80_{px})\n"
            "                or      a\n"
            f"                jp      m,{u}\n"
            "                add     a,l\n"
            "                ld      l,a\n"
            "                ret     nc\n"
            "                inc     h\n"
            "                ret\n"
            f"{u}:\n"
            "                add     a,l\n"
            "                ld      l,a\n"
            "                ret     c\n"
            "                dec     h\n"
            "                ret\n")


def ix_helpers_text():
    out, need = [], set()
    for px, form in sorted(_ix_used):
        two = form in TWO
        need.add(("w", px, two))
        need.add("il_ret_hl")
        if form == "lda":
            need.add("il_epi_a")
        elif form not in ("inc", "dec", "bit") and form not in ALU:
            need.add("il_epi")
    for k in ("il_pro1", "il_pro2"):
        if k in need:
            out.append(IL_INFRA[k])
    for px in ("ix", "iy"):
        for two in (False, True):
            if ("w", px, two) in need:
                out.append(ix_wrap(px, two))
    for k in ("il_adr", "il_ret_hl", "il_epi", "il_epi_a"):
        if k in need:
            out.append(IL_INFRA[k])
    for px, form in sorted(_ix_used):
        out.append(ix_helper(px, form))
    return "".join(out)


# ---------------------------------------------------------------------------
# ГЛАВНОЕ РАЗВОРАЧИВАНИЕ
# ---------------------------------------------------------------------------
UNSUPPORTED: list = []


def expand(it, hot: bool, need_z: bool):
    """Список строк i8080 для команды Z80, или None — команда своя."""
    mn, ops = it.mn, it.ops
    cell = is_idx(ops, mn)
    if mn == "jr":
        return [f"jp {ops[0]}"] if len(ops) == 1 else [f"jp {ops[0]},{ops[1]}"]
    if mn == "djnz":
        return ["dec b", f"jp nz,{ops[0]}"]
    if cell:
        r = x_idx_inline(mn, ops, cell) if hot else x_idx_compact(mn, ops, cell, it.addr)
        if r is None:
            UNSUPPORTED.append(f"{it.addr:04X}: IX/IY {it.raw.strip()}")
            return ["; UNSUPPORTED " + it.raw.strip()]
        return r
    if mn == "bit":
        return x_bit(ops[0], ops[1].lower())
    if mn in ("res", "set"):
        return x_resset(mn, ops[0], ops[1].lower())
    if mn in ("sla", "sra", "srl", "sll", "rl", "rr", "rlc", "rrc"):
        return x_shift(mn, ops[0].lower(), need_z)
    if mn in ("ldir", "lddr"):
        return ["call il_ldir" if mn == "ldir" else "call il_lddr"]
    if mn in ("adc", "sbc") and ops and ops[0].lower() == "hl":
        return x_adcsbc_hl(mn, ops[1].lower(), need_z)
    if mn == "neg":
        return ["cpl", "inc a"]
    if mn in ("reti", "retn"):
        return ["ret"]
    if mn == "ld" and len(ops) == 2 and ops[0].lower() == "a" \
            and ops[1].lower() in ("i", "r"):
        return ["call il_rnd"]
    if mn == "ld":
        r = x_ld16(ops)
        if r is not None:
            return r
    if mn == "ex" and len(ops) == 2 and ops[0].lower() == "af":
        return ["call il_exaf"]
    if mn == "exx":
        return ["call il_exx"]
    if mn == "ldi":
        return ["call il_ldi"]
    if mn == "im" or (mn == "ld" and ops and ops[0].lower() == "i"):
        return []                  # Vector: one frame IRQ via RST 38, no IM / I
    if mn == "rst" and ops and int(ops[0], 0) == 0:
        return []                  # MSX reboot after a message; RST 00 was `ret`, now a helper slot
    return None


# ---------------------------------------------------------------------------
# ФЛАГИ: где после развёртки читают то, что развёртка испортила
# ---------------------------------------------------------------------------
# Разворачивания, которые НЕ повторяют Z80 по флагам, перечислены поимённо;
# для каждого сайта поток прослеживается вперёд до первой команды, которая
# этот флаг либо ЧИТАЕТ (тогда сайт в отчёт), либо ПЕРЕЗАПИСЫВАЕТ.
CC_FLAG = {"z": "Z", "nz": "Z", "c": "C", "nc": "C", "p": "S", "m": "S",
           "pe": "P", "po": "P"}
SETS_ALL = {"add", "adc", "sub", "sbc", "and", "or", "xor", "cp", "inc", "dec",
            "neg", "daa", "rld", "rrd", "sla", "sra", "srl", "sll", "rl", "rr",
            "rlc", "rrc", "bit"}


def flag_effect(it):
    """(reads, writes) — множества флагов ZCSP."""
    mn, ops = it.mn, it.ops
    if mn in ("jp", "jr", "call", "ret") and ops and ops[0].lower() in CC_FLAG:
        return {CC_FLAG[ops[0].lower()]}, set()
    if mn in ("adc", "sbc"):
        return {"C"}, set("ZCSP")
    if mn in ("rla", "rra"):
        return {"C"}, {"C"}
    if mn in ("rlca", "rrca", "scf"):
        return set(), {"C"}
    if mn == "ccf":
        return {"C"}, {"C"}
    if mn == "cpl":
        return set(), set()
    if mn in ("inc", "dec") and len(ops) == 1 and ops[0].lower() in \
            ("bc", "de", "hl", "sp", "ix", "iy"):
        return set(), set()
    if mn in ("inc", "dec"):
        return set(), set("ZSP")
    if mn == "add" and ops and ops[0].lower() in ("hl", "ix", "iy"):
        return set(), {"C"}
    if mn == "bit":                       # Z80 BIT keeps CY
        return set(), set("ZSP")
    if mn in SETS_ALL:
        return set(), set("ZCSP")
    if mn == "djnz":
        return set(), set()
    if mn in ("ldir", "lddr", "ldi", "ldd"):
        return set(), {"P"}
    if mn == "ex" and ops and ops[0].lower() == "af":
        return set(), set("ZCSP")
    return set(), set()


FLOW_BREAK = {"jp", "jr", "ret", "reti", "retn", "halt"}


def build(items):
    """Словари: адрес -> item, метка -> адрес, адрес -> следующий адрес."""
    by_addr = {it.addr: it for it in items if it.addr is not None}
    lab = {}
    for it in items:
        for n in (it.labels or []):
            lab[n] = it.addr
    return by_addr, lab


def targets(it, lab, equs):
    """Адреса, на которые команда может передать управление (кроме
    проваливания).  Символ, который не метка кода, отбрасывается."""
    if it.kind != "code" or it.mn not in ("jp", "jr", "call", "djnz"):
        return []
    op = it.ops[-1] if it.ops else None
    if not op or op.startswith("("):
        return []
    m = re.match(r"^([A-Za-z_][\w]*)(?:\s*\+\s*(0x[0-9A-Fa-f]+|\d+))?$", op)
    if not m:
        return []
    base = m.group(1)
    if base in lab:
        return [lab[base] + (int(m.group(2), 0) if m.group(2) else 0)]
    if base in equs:
        return [equs[base] + (int(m.group(2), 0) if m.group(2) else 0)]
    return []


def is_break(it):
    """Команда безусловно обрывает проваливание?"""
    if it.kind != "code":
        return False
    if it.mn in ("jp", "jr") and len(it.ops) == 1:
        return True
    if it.mn in ("ret", "reti", "retn") and not it.ops:
        return True
    return False


def flag_live(addr, flag, by_addr, lab, equs, order, limit=60):
    """Читается ли flag раньше, чем будет перезаписан (по всем путям)."""
    seen, work = set(), [(addr, 0)]
    while work:
        a, n = work.pop()
        if n > limit or a in seen:
            continue
        seen.add(a)
        it = by_addr.get(a)
        if it is None or it.kind != "code":
            return True                      # ушли в данные — считаем живым
        rd, wr = flag_effect(it)
        if flag in rd:
            return True
        if flag in wr:
            continue
        if it.mn == "call":
            return True                      # за вызовом не следим
        for t in targets(it, lab, equs):
            work.append((t, n + 1))
        if not is_break(it):
            nxt = order.get(a)
            if nxt is None:
                return True
            work.append((nxt, n + 1))
    return False


EXAF_TEXT = """il_exaf:                                ; ex af,af' через теневую ячейку
                ld      (il_tmp2),hl
                push    af
                pop     hl
                ld      (il_f),hl
                ld      hl,(z80_af_alt)
                push    hl
                pop     af
                ld      hl,(il_f)
                ld      (z80_af_alt),hl
                ld      hl,(il_tmp2)
                ret
"""

EXX_TEXT = """il_exx:                                 ; exx: BC/DE/HL <-> z80_bc2/de2/hl2
                ld      (il_tmp),hl
                ld      hl,(z80_hl2)
                ld      (il_tmp2),hl
                ld      hl,(il_tmp)
                ld      (z80_hl2),hl
                ld      hl,(z80_bc2)
                push    hl
                ld      h,b
                ld      l,c
                ld      (z80_bc2),hl
                pop     bc
                ld      hl,(z80_de2)
                ex      de,hl
                ld      (z80_de2),hl
                ld      hl,(il_tmp2)
                ret
il_ldi:                                 ; ldi; P (pe) = BC <> 0, A kept
                ld      (il_a),a
                ld      a,(hl)
                ld      (de),a
                inc     hl
                inc     de
                dec     bc
                ld      a,b
                or      c
                ld      a,0x01
                jp      z,il_ldi_z
                ld      a,0x03
il_ldi_z:
                or      a
                ld      a,(il_a)
                ret
"""

LDIR_TEXT = """il_ldir:                                ; ldir: (hl)->(de), bc байт (0 = 65536)
                push    af              ; Z80 ldir не трогает ни A, ни CY
                ld      a,c
                and     3
                jp      z,il_ldir_q
il_ldir_s:                              ; сначала bc mod 4 по байту
                ld      a,(hl)
                ld      (de),a
                inc     hl
                inc     de
                dec     bc              ; DCX у i8080 ФЛАГОВ НЕ СТАВИТ
                ld      a,c
                and     3
                jp      nz,il_ldir_s
                ld      a,b
                or      c
                jp      z,il_ldir_x
il_ldir_q:                              ; bc кратно 4: bc/4 проходов по 4 байта
                ld      a,b
                or      a
                rra
                ld      b,a
                ld      a,c
                rra
                ld      c,a
                ld      a,b
                or      a
                rra
                ld      b,a
                ld      a,c
                rra
                ld      c,a
il_ldir_l:
                ld      a,(hl)
                ld      (de),a
                inc     hl
                inc     de
                ld      a,(hl)
                ld      (de),a
                inc     hl
                inc     de
                ld      a,(hl)
                ld      (de),a
                inc     hl
                inc     de
                ld      a,(hl)
                ld      (de),a
                inc     hl
                inc     de
                dec     bc
                ld      a,b
                or      c
                jp      nz,il_ldir_l
il_ldir_x:
                pop     af
                ret
il_lddr:
                push    af
il_lddr_l:
                ld      a,(hl)
                ld      (de),a
                dec     hl
                dec     de
                dec     bc
                ld      a,b
                or      c
                jp      nz,il_lddr_l
                pop     af
                ret
"""

HDR = """; СГЕНЕРИРОВАНО tools/recompile_i8080.py — правки вносить ТУДА.
; Код игры Basket Master, перекомпилированный Z80 -> i8080 (Вектор-06Ц, ВМ80А).
; Эталон — disasm/v06/game.asm (раскладка Вектора, гейт tools/disasm_v06.py --verify).
; Метод, врезки, гейты и такты — docs/recompilation.md.
"""


def emit_unit(it, lines, out):
    for n in (it.labels or []):
        out.append(n + ":")
    if it.addr is not None:
        out.append("Z_%04X:" % it.addr)
    if lines is None:                     # своя команда — как есть
        out.append("\t" + it.raw.strip() + "\t" + it.cmt)
    else:
        first = True
        for s in lines:
            out.append((s if s.endswith(":") else "\t" + s) +
                       (("\t" + it.cmt) if first and it.cmt else ""))
            first = False


def asm(src: Path, lst: Path, binf: Path):
    import subprocess
    ASM = Path(os.environ.get("ZASM") or shutil.which("zasm") or str(Path.home() / "projects/kvalley-v06c/tools/bin/sjasm"))
    r = subprocess.run([str(ASM), "--8080", "-b", "-w", "-u", str(src),
                        str(lst), str(binf)], capture_output=True, text=True)
    return r


def symbols(lst: Path):
    out = {}
    for m in re.finditer(r"^(\w+)\s+= \$([0-9A-F]{4}) =",
                         lst.read_text(errors="replace"), re.M):
        out[m.group(1)] = int(m.group(2), 16)
    return out


def load_profile():
    """Исполнений на итерацию по адресу (tools/prof_pc_v06js.js)."""
    p = ROOT / "cfg/recompile/prof-z80.json"
    if not p.is_file():
        # МОЛЧА СОБИРАТЬ ДРУГОЙ ОБРАЗ НЕЛЬЗЯ.  Профиль решает, какие 25
        # ix/iy-сайтов развернуть в inc/dec hl, а какие отдать хелперу; без
        # него ВСЕ считаются холодными, и получается другой game.asm (196
        # строк разницы) — без единого слова в выводе.  Профиль лежит в
        # build/, то есть в .gitignore: в свежем клоне его нет.
        if os.environ.get("PROF") == "none":
            print("recompile_i8080: PROF=none — профиля нет, ВСЕ ix/iy-сайты"
                  " холодные (образ будет отличаться от релизного)")
            return {}
        sys.exit("recompile_i8080: нет профиля cfg/recompile/prof-z80.json —"
                 " без него все ix/iy-сайты считаются холодными и образ выйдет"
                 " ДРУГИМ.\n  снять профиль:  PROF_OUT=build/analysis/prof-z80.json"
                 " node tools/prof_pc_v06js.js build/adapter/spirits.rom 300"
                 "\n  осознанно без профиля:  PROF=none")
    d = json.loads(p.read_text())
    it = max(1, d["iters"])
    return {int(k): v[0] / it for k, v in d["pc"].items()}


def load_cuts():
    p = ROOT / "tools/i8080_dead.json"
    if not p.is_file():
        return [], {}
    d = json.loads(p.read_text())
    return ([(int(a, 16), int(b, 16)) for a, b in d["cut"]],
            {int(k, 16): v for k, v in d.get("reserve", {}).items()})


HOT_IX = 2.0
# (ix+d) sites that are hot on the i8080 image itself (helper calls per
# match iteration, cfg/recompile/hot_ix_i8080.json): expanded in place too.
_hot_p = ROOT / "cfg/recompile/hot_ix_i8080.json"
_hot_d = json.loads(_hot_p.read_text()) if _hot_p.is_file() else {"min": 0, "sites": {}}
HOT_I8080 = {int(k, 16) for k, n in _hot_d["sites"].items() if n >= _hot_d["min"]}
HOT_W = {int(k, 16): n for k, n in _hot_d["sites"].items()}


NATIVE_EQU = []


def load_native():
    """cfg/native_modules.json: {имя: {src, ranges: [[lo, hi]], entries: [..]}}
    (адреса Z80, hex).  NATIVE=0 — без ручных модулей, NATIVE=a,b — только эти."""
    p = ROOT / "cfg/native_modules.json"
    if not p.exists() or os.environ.get("NATIVE") == "0":
        return []
    out = []
    only = os.environ.get("NATIVE")
    only = set(only.split(",")) if only else None
    for name, m in json.loads(p.read_text()).items():
        if name.startswith("_") or (only is not None and name not in only):
            continue
        lines = [ln.rstrip() for ln in (ROOT / m["src"]).read_text(encoding="utf-8").splitlines()]
        lines = [ln.split(";")[0].strip() for ln in lines]
        lines = [ln for ln in lines if ln]
        NATIVE_EQU.extend(re.sub(r"\s+", "\t", ln, 2) for ln in lines if re.match(r"^\w+\s+equ\s", ln))
        lines = [ln for ln in lines if not re.match(r"^\w+\s+equ\s", ln)]
        out.append({"name": name, "src": m["src"], "lines": lines,
                    "ranges": [(int(a, 16), int(b, 16)) for a, b in m["ranges"]],
                    "entries": [int(e, 16) for e in m["entries"]]})
    return out


def main():
    global SRC, OUT_ASM, OUTDIR
    ap = argparse.ArgumentParser()
    ap.add_argument("--audit", action="store_true")
    ap.add_argument("--no-cut", action="store_true")
    ap.add_argument("--pk8", action="store_true",
                    help="вход disasm/msx/pk8 → src/i8080/game_pk8.asm")
    a = ap.parse_args()
    if a.pk8:
        SRC = ROOT / "disasm/msx/pk8"
        OUT_ASM = ROOT / "src/i8080/game_pk8.asm"
        OUTDIR = ROOT / "build/i8080_pk8"
    OUTDIR.mkdir(parents=True, exist_ok=True)

    equs, items = {}, []
    for f in FILES:
        e, its = parse(f)
        for n, v in e:
            equs.setdefault(n, v)
        items += [x for x in its if x.kind != "org"]
    items.sort(key=lambda x: (x.addr if x.addr is not None else 0))
    # байт 1900 общий у хвоста и резидента — оставить одну запись
    ded, seen = [], set()
    for it in items:
        if it.addr in seen:
            continue
        seen.add(it.addr)
        ded.append(it)
    items = ded
    configure_layout(items)
    by_addr, lab = build(items)
    equ_v = {n: int(v, 0) for n, v in equs.items() if n not in lab}
    order = {}
    for i, it in enumerate(items[:-1]):
        order[it.addr] = items[i + 1].addr

    prof = load_profile()
    cuts, resv = load_cuts()
    if a.no_cut:
        cuts = []

    def cut(addr, n):
        return any(lo <= addr and addr + n - 1 <= hi for lo, hi in cuts)

    def in_zone(addr):
        """Зона врезки адаптера, внутрь которой попал адрес (не её начало)."""
        return any(z < addr < z + n for z, n in resv.items())

    def pinned(addr, n):
        return any(lo <= addr <= hi or lo <= addr + n - 1 <= hi for lo, hi in PIN)

    def inside_pin(addr, n):
        return any(lo <= addr and addr + n - 1 <= hi for lo, hi in PIN)

    # --- предпроход: какие компактные формы IX часто встречаются (под rst)
    for it in items:
        if it.kind != "code" or cut(it.addr, it.nbytes) or it.addr in resv \
                or in_zone(it.addr):
            continue
        if is_idx(it.ops, it.mn) and prof.get(it.addr, 0) < HOT_IX:
            f = ix_form(it.mn, it.ops)
            if f:
                px = "ix" if is_idx(it.ops, it.mn) == "z80_ix" else "iy"
                _ix_cnt[(px, f)] = _ix_cnt.get((px, f), 0) + 1
    # --- d-прологи: отбор сайтов по выгоде на байт (вес — образ i8080)
    rst0 = {f for _c, f in sorted(((c, f) for f, c in _ix_cnt.items()),
                                  key=lambda x: (-x[0], x[1]))[:len(RST_SLOTS)]}
    cand, nsite = [], {}
    for it in items:
        if it.kind != "code" or cut(it.addr, it.nbytes) or it.addr in resv \
                or in_zone(it.addr):
            continue
        cell = is_idx(it.ops, it.mn)
        w = HOT_W.get(it.addr, 0)
        if not cell or w < PRO_MIN or prof.get(it.addr, 0) >= HOT_IX \
                or it.addr in HOT_I8080:
            continue
        f = ix_form(it.mn, it.ops)
        if f is None:
            continue
        new = x_idx_pro(it.mn, it.ops, cell)
        if new is None:
            continue
        px = "ix" if cell == "z80_ix" else "iy"
        old_n = (2 if (px, f) in rst0 else 4) + (1 if f in TWO else 0)
        mi = next(i for i, o in enumerate(it.ops) if IDX_RE.search(o))
        cand.append((w / max(est_size(new) - old_n, 1), w,
                     est_size(new) - old_n, (px, idx_disp(it.ops[mi])), it.addr, (px, f)))
    _pro_used.clear()
    used, gain, have = 0, 0.0, set()
    for _r, w, net, pk, addr, pf in sorted(cand, reverse=True):
        d = pk[1]
        extra = 0 if pk in have else (abs(d) + 5 if abs(d) <= INC_MAX else 18)
        if used + net + extra > PRO_BYTES:
            continue
        used += net + extra
        gain += w
        have.add(pk)
        PRO_SITES.add(addr)
        nsite[pf] = nsite.get(pf, 0) + 1
    print("d-прологи (ix+d): %d сайтов, %d прологов, вызовов/итер %.1f из %.1f, +%d б"
          % (len(PRO_SITES), len(have), gain, sum(HOT_W.get(a, 0) for a in HOT_W), used))
    for pf, n in nsite.items():         # эти сайты больше не зовут общую форму
        _ix_cnt[pf] -= n
    for slot, (_c, f) in zip(RST_SLOTS, sorted(
            ((c, f) for f, c in _ix_cnt.items() if c > 0), key=lambda x: (-x[0], x[1]))):
        _ix_rst[f] = slot
    if os.environ.get("RST_STAT"):
        for f, c in sorted(_ix_cnt.items(), key=lambda x: -x[1])[:12]:
            print("форма", f, c, "rst %02X" % _ix_rst[f] if f in _ix_rst else "")

    # --- РУЧНЫЕ МОДУЛИ i8080 (docs/NATIVE_PLAN.md, A2): команды Z80 из их
    # участков не переводятся; вместо них — текст src/native/<модуль>.asm,
    # который сам определяет метки Z_<вход> для всех входов участка.
    native = load_native()
    nat_cut = [(lo, hi) for m in native for lo, hi in m["ranges"]]

    def nat(addr):
        return addr is not None and any(lo <= addr <= hi for lo, hi in nat_cut)

    # --- перевод
    code_addrs = {it.addr for it in items if it.kind == "code" and it.addr is not None}
    audit = []
    stat = {}
    units, fixed = [], []          # (addr, nbytes_orig, kind, lines_or_None, item)
    for it in items:
        if it.addr in resv:
            n = resv[it.addr]
            it.kind = "data"
            it.lines = None
            it.raw = "db\t" + ",".join(["0"] * n)
            it.cmt = "; ЗОНА ВРЕЗКИ АДАПТЕРА, %d б (SCR_PATCH)" % n
            it.nbytes = n
            units.append(it)
            continue
        if it.addr is not None and in_zone(it.addr):
            continue
        if it.addr is not None and cut(it.addr, it.nbytes):
            continue
        if it.kind == "code" and nat(it.addr):
            continue
        if it.kind == "data":
            if it.addr is not None and in_proven(it):
                continue          # нули доказанно свободной зоны
            if pinned(it.addr, it.nbytes) and inside_pin(it.addr, it.nbytes):
                continue          # байты уже лежат в приколоченной копии
            it.lines = None
            if any(lo <= it.addr and it.addr + it.nbytes - 1 <= hi
                   for lo, hi in FIXED):
                fixed.append(it)  # остаётся на своём адресе (страница!)
            else:
                units.append(it)
            continue
        if it.addr in OPERAND_PATCH:
            txt, why = OPERAND_PATCH[it.addr]
            mn, _, o = txt.partition(" ")
            it.mn, it.ops = mn.lower(), split_ops(o)
            it.raw = txt
            it.cmt = (it.cmt or ";") + "  ; ВПЕЧЁННАЯ ВРЕЗКА: " + why
        # ВХОД ПОСРЕДИ КОМАНДЫ: операнд вида `L_1411+0x1` целит в БАЙТ
        # ВНУТРИ команды Z80.  После перевода этого байта на прежнем месте
        # нет — там лежит середина ДРУГОЙ команды, и переход туда срывает
        # PC.  Заглушки Z_xxxx из OVERLAP строились, но никто на них не
        # ссылался: сборка оставляла операнд как `L_1411+0x1`, и ассемблер
        # считал его адресом i8080-кода.  Найдено 2026-09-23 прогоном
        # tools/playthrough_v06js.js: `call L_1411+0x1` собрался в
        # `call 16F9`, то есть в операнд `jnz 16F7`; байт F7 = `rst 0x30`,
        # PC уходил на 0x0030 и игра вставала.  Здесь операнд НАВОДИТСЯ на
        # заглушку.
        if it.mn in ("jp", "jr", "call", "djnz") and it.ops:
            _tg = targets(it, lab, equ_v)
            if _tg and _tg[0] in OVERLAP:
                _new = "Z_%04X" % _tg[0]
                it.ops = it.ops[:-1] + [_new]
                it.raw = re.sub(r"[^\s,]+\s*$", _new, it.raw.rstrip())
                it.cmt = (it.cmt or ";") + "  ; ВХОД ПОСРЕДИ КОМАНДЫ -> " + _new
                audit.append((it.addr, "вход посреди команды наведён на " + _new))
        hot = prof.get(it.addr, 0) >= HOT_IX or it.addr in HOT_I8080
        need_z = False
        if it.mn in ("sla", "sra", "srl", "sll", "rl", "rr", "rlc", "rrc") \
                or (it.mn in ("adc", "sbc") and it.ops
                    and it.ops[0].lower() == "hl"):
            nxt = order.get(it.addr)
            need_z = nxt is not None and flag_live(nxt, "Z", by_addr, lab,
                                                   equ_v, order)
            if need_z and it.mn not in ("adc", "sbc"):
                c_live = nxt is not None and flag_live(nxt, "C", by_addr, lab,
                                                       equ_v, order)
                if c_live:
                    audit.append((it.addr, "сдвиг: живы и Z, и CY — "
                                  + it.raw.strip()))
        lines = expand(it, hot, need_z)
        # BIT keeps CY on the Z80; `and` clears it. Where CY is read later
        # (8D33 scf / bit 4,(ix+0) / ret nz, 05.11) the expansion keeps it.
        if it.mn == "bit" and lines and not any(x.startswith(("rst", "call il_")) for x in lines):
            nxt = order.get(it.addr)
            if nxt is not None and flag_live(nxt, "C", by_addr, lab, equ_v, order):
                lines = keep_cy(lines)
                audit.append((it.addr, "bit сохраняет CY: " + it.raw.strip()))
        if lines is not None:
            k = it.mn
            if is_idx(it.ops, it.mn):
                k = "ix/iy " + ("развёртка" if hot else "хелпер")
            elif k in ("sla", "sra", "srl", "sll", "rl", "rr", "rlc", "rrc"):
                k = "сдвиги CB"
            elif k in ("bit", "res", "set"):
                k = "bit/res/set"
            elif k in ("adc", "sbc"):
                k = "adc/sbc hl"
            elif k == "ex":
                k = "ex af,af'"
            elif k == "ld":
                k = ("ld a,r" if it.ops[1].lower() in ("i", "r")
                     else "ld rr,(nn) / ld (nn),rr")
            stat[k] = stat.get(k, 0) + 1
        if it.addr in HAND:
            u = uniq("HAND")
            lines = [x.replace("{u}", u) for x in HAND[it.addr]]
            audit.append((it.addr, "ручная замена: " + it.raw.strip()))
        # ПРОВАЛИВАНИЕ В АДАПТЕР: Z80-команда, после которой идёт не код
        # игры (дыра адаптера, например 34BA -> 34BD jp BLIT_ADVANCE).  После
        # переезда кода провал ушёл бы в соседний кусок — ставим явный jp.
        if it.kind == "code" and not is_break(it) and it.mn not in ("halt",):
            nxt = it.addr + it.nbytes
            if nxt not in code_addrs:
                own = lines if lines is not None else [it.raw.strip()]
                lines = own + ["jp 0x%04X" % nxt]
                audit.append((it.addr, "провал в не-код %04X: явный jp" % nxt))
        if it.addr in ISR_SAVE:
            pos, extra = ISR_SAVE[it.addr]
            own = lines if lines is not None else [it.raw.strip()]
            lines = own + extra if pos == "after" else extra + own
        it.lines = lines
        units.append(it)
    have = {it.addr for it in units}
    for z, n in sorted(resv.items()):
        if z in have:
            continue
        units.append(Item(kind="data", addr=z, mn="db", ops=None,
                          raw="db\t" + ",".join(["0"] * n), cmt="; ЗОНА ВРЕЗКИ",
                          nbytes=n, labels=[], file="zone", line=0, lines=None))
    units.sort(key=lambda x: x.addr if x.addr is not None else 0)
    for m in native:                     # в поток — на место первого входа
        # по команде на единицу (как у переведённого кода): раскладка кладёт
        # единицы в свободные куски образа, на стыках ставит мост `jp`
        parts, pend = [], []
        for k, ln in enumerate(m["lines"]):
            if ln.endswith(":"):
                pend.append(ln[:-1])
                continue
            mn, _, o = ln.partition(" ")
            parts.append(Item(kind="code", addr=None, mn=mn.lower(), ops=split_ops(o.strip()), raw=ln,
                              cmt="", nbytes=0, labels=pend + ["NAT_%s_%d" % (m["name"], k)],
                              file=m["src"], line=k, lines=[ln]))
            pend = []
        parts[0].native = m
        at = next((i for i, x in enumerate(units) if x.addr is not None and x.addr > m["ranges"][0][0]), len(units))
        units[at:at] = parts
    if UNSUPPORTED:
        print("НЕ ПЕРЕВЕДЕНО (%d):" % len(UNSUPPORTED))
        for x in UNSUPPORTED:
            print("  " + x)
        sys.exit(1)
    print("переведено команд Z80 по классам:")
    for k, v in sorted(stat.items(), key=lambda x: -x[1]):
        print(f"  {k:26s} {v:4d}")
    print(f"  {'ИТОГО':26s} {sum(stat.values()):4d}")
    layout_and_emit(items, units, fixed, lab, equs, audit, a)


def layout_and_emit(items, units, fixed, lab, equs, audit, args):
    # --- заглушки для входов ПОСРЕДИ команды (наложения дизасма)
    stubs = []
    for a, (txt, cont) in OVERLAP.items():
        mn, _, ops = txt.partition(" ")
        it = Item(kind="code", addr=None, mn=mn, ops=split_ops(ops), raw=txt,
                  cmt="; вход посреди команды Z80 %04X" % a, nbytes=0,
                  labels=["Z_%04X" % a], file="overlap", line=0)
        it.lines = (x_idx_inline(mn, it.ops, is_idx(it.ops, mn)) or []) + \
                   ["jp Z_%04X" % cont]
        stubs.append(it)
    units = units + stubs

    head = [HDR, ""]
    for n, v in sorted(equs.items()):
        if n not in lab:
            head.append(f"{n}:\tequ\t{v}")
    head += NATIVE_EQU
    head.append("RT_VARS:\tequ\t0x%04X\t; ячейки рантайма (мёртвая зона 92FF..9329)" % RT_VARS_ADDR)
    for i, n in enumerate(CELLS):
        head.append(f"{n}:\tequ\tRT_VARS+{i * 2}")
    base = len(CELLS) * 2
    for i, n in enumerate(CELLS8):
        head.append(f"{n}:\tequ\tRT_VARS+{base + i}")
    head.append("RT_VARS_END:\tequ\tRT_VARS+%d" % (base + len(CELLS8)))
    head.append("")

    # РАНТАЙМ разбирается на отдельные процедуры: так он укладывается в
    # куски по одной, а не одним неделимым блоком.
    rtx = ix_helpers_text() + pro_text() + IL_INFRA["il_rnd"] + LDIR_TEXT + EXAF_TEXT + EXX_TEXT
    # Рантайм кладётся в общий поток (раскладка разносит его по кускам), но
    # читать его удобнее отдельным файлом — пишем и его.
    (ROOT / "src/i8080/rt.asm").write_text(
        "; СГЕНЕРИРОВАНО tools/recompile_i8080.py — правки вносить ТУДА.\n"
        "; РАНТАЙМ РЕКОМПИЛЯЦИИ Z80 -> i8080: хелперы (ix+d)/(iy+d) с общими\n"
        "; прологом и эпилогом, ldir/lddr, ex af,af', замена регистру R.\n"
        "; Контракт хелперов: беречь HL, A и ФЛАГИ; DE/BC не трогать.\n"
        "; ЭТОТ ФАЙЛ НЕ СОБИРАЕТСЯ отдельно: те же процедуры лежат внутри\n"
        "; src/i8080/game.asm, разложенные по свободным кускам образа\n"
        "; (docs/recompilation.md, §5).  Здесь — чтобы их можно было читать.\n"
        ";\n" + rtx)
    rt_units, cur = [], None
    for ln in rtx.split("\n"):
        m = re.match(r"^([A-Za-z_][\w]*):", ln)
        if m and not ln.startswith((" ", "\t")) and not m.group(1).endswith("_l"):
            cur = Item(kind="code", addr=None, mn="", ops=[], raw="", cmt="",
                       nbytes=0, labels=[], file="rt", line=0, lines=[ln])
            rt_units.append(cur)
        elif cur is not None and ln.strip():
            cur.lines.append(ln)
    for u in rt_units:
        u.labels = [re.match(r"^([A-Za-z_][\w]*):", u.lines[0]).group(1)]
        u.lines = u.lines[1:]
    rt = []

    # --- ПРОХОД 1: линейно; длины берём из листинга по меткам Z_/меткам единиц
    def emit_all(placed):
        """placed: список (org|None, unit|строки).  Блоки от org до org
        выводятся по возрастанию адреса: sjasm не принимает org ниже начала
        сегмента, а куски раскладки идут в порядке заполнения."""
        blocks, cur = [], None
        for org, u in placed:
            if org is not None or cur is None:
                cur = [org if org is not None else -1, []]
                blocks.append(cur)
            cur[1].append((org, u))
        placed = [x for _, b in sorted(blocks, key=lambda b: b[0]) for x in b]
        out = list(head)
        for org, u in placed:
            if org is not None:
                out.append("\torg\t0x%04X" % org)
            if u is None:
                continue
            if isinstance(u, str):
                out.append(u)
            elif isinstance(u, list):
                out += u
            else:
                emit_unit(u, u.lines, out)
        return "\n".join(out) + "\n"

    lin = OUTDIR / "game_lin.asm"
    lin.write_text(emit_all([(0x0489, None)][:0] + [(0x0489, "")] +
                            [(None, u) for u in rt_units + units]
                            + [(x.addr, None) for x in []]
                            + [(None, u) for u in fixed]))
    r = asm(lin, OUTDIR / "game_lin.lst", OUTDIR / "game_lin.bin")
    if "no errors" not in (r.stdout + r.stderr):
        sys.exit("zasm (проход 1):\n" + r.stdout + r.stderr)
    S = symbols(OUTDIR / "game_lin.lst")
    size = {}
    seq = rt_units + units + fixed
    for i, u in enumerate(seq):
        key = "Z_%04X" % u.addr if u.addr is not None else u.labels[0]
        nxt = seq[i + 1] if i + 1 < len(seq) else None
        nk = ("Z_%04X" % nxt.addr if nxt.addr is not None else nxt.labels[0]) \
            if nxt else None
        size[id(u)] = ((S[nk] if nk else
                        0x0489 + (OUTDIR / "game_lin.bin").stat().st_size)
                       - S[key])
    rt_size = sum(size[id(u)] for u in rt_units)
    code_size = sum(size[id(u)] for u in units)
    print(f"проход 1: код игры {code_size} б, рантайм {rt_size} б, "
          f"всего {code_size + rt_size} б")

    # --- РАСКЛАДКА.  Единицы кладутся ПО ПОРЯДКУ в свободные куски; на
    # стыке ставится мост `jp` (3 б), если предыдущая единица проваливается
    # дальше.  В каждом куске, кроме последнего, 3 байта держатся под мост.
    free = [RT_REGION] + list(REGIONS) + TAIL_REGIONS
    units = rt_units + units
    orig = (ROOT / "build/v06/basket.rom").read_bytes()
    pins = sorted(PIN)
    pi = [0]

    def flush_pins(upto, placed):
        """Приколоченные куски (графика логотипа) — своими db на свой org."""
        while pi[0] < len(pins) and pins[pi[0]][0] < upto:
            lo, hi = pins[pi[0]]
            b = orig[lo - 0x100:hi - 0x100 + 1]
            txt = ["\torg\t0x%04X" % lo, "Z_%04X:" % lo]
            for k in range(0, len(b), 16):
                txt.append("\tdb\t" + ",".join("0x%02X" % x for x in b[k:k + 16])
                           + ("\t; ПРИКОЛОЧЕНО: глиф логотипа %04X" % (lo + k)
                              if k == 0 else ""))
            placed.append((None, txt))
            pi[0] += 1

    placed, ri, pos, prev = [(free[0][0], None)], 0, free[0][0], None
    spans = [[free[0][0], free[0][0]]]
    for u in units:
        n = size[id(u)]
        while pos + n - 1 > free[ri][1] - (3 if ri + 1 < len(free) else 0):
            if ri + 1 >= len(free):
                rest = sum(size[id(x)] for x in units[units.index(u):])
                sys.exit("НЕ ВЛЕЗЛО на %s: осталось уложить %d б, свободно %d б"
                         % ("%04X" % u.addr if u.addr else u.labels[0],
                            rest, free[ri][1] - pos + 1))
            nxt = "Z_%04X" % u.addr if u.addr is not None else u.labels[0]
            # МОСТ ВХОДИТ В ЗАНЯТЫЙ КУСОК.  `spans` — это список того, что
            # `tools/build_v06_rom.py` копирует из game.bin в образ; всё
            # остальное между 02A0 и 294B он обнуляет.  Пока конец куска
            # писался ДО моста, три байта `jp` в образ не попадали и
            # превращались в `nop nop nop` + мусор: процедура доезжала до
            # конца куска и проваливалась в чужие байты.  Замер 2026-09-23:
            # так терялись ПЯТЬ мостов (029C, 02A0, 02E6, 03C0, 0486, 1DFA),
            # и один из них — у SCR_ADDR_BIT14, из-за чего эффекты перехода
            # между комнатами получали недосчитанный адрес экрана.  Дефект
            # нашёлся только тогда, когда эти пути впервые исполнили
            # (tools/cmp_lever_msx.py): прежние гейты до них не доходили.
            bridged = prev is not None and not is_break(prev)
            if bridged:
                placed.append((None, "\tjp\t%s\t; мост в следующий кусок" % nxt))
            spans[-1][1] = pos + (3 if bridged else 0)
            ri += 1
            pos = free[ri][0]
            spans.append([pos, pos])
            flush_pins(pos, placed)
            placed.append((pos, None))
        placed.append((None, u))
        pos += n
        prev = u if u.kind == "code" else None
    spans[-1][1] = pos
    for u in fixed:
        placed.append((u.addr, None))
        placed.append((None, u))
        spans.append([u.addr, u.addr + size[id(u)]])
    flush_pins(0x10000, placed)
    print("раскладка кода: " + ", ".join(
        "%04X..%04X" % (lo, hi) for lo, hi in free[:ri]) +
        ", последний %04X..%04X кончился на %04X (свободно %d)"
        % (free[ri][0], free[ri][1], pos - 1, free[ri][1] - pos + 1))
    spare = free[ri][1] - pos + 1 + sum(hi - lo + 1 for lo, hi in free[ri + 1:])
    print("запас: %d байт (%d кусков не заняты: %s)" % (spare, len(free) - ri - 1, ", ".join(
        "%04X..%04X" % (lo, hi) for lo, hi in free[ri + 1:])))
    final = OUT_ASM
    final.write_text(emit_all(placed))
    r = asm(final, OUTDIR / "game.lst", OUTDIR / "game.bin")
    if "no errors" not in (r.stdout + r.stderr):
        sys.exit("zasm (проход 2):\n" + r.stdout + r.stderr)
    print("проход 2: собрано", (OUTDIR / "game.bin").stat().st_size, "байт")
    # --- КАРТА АДРЕСОВ Z80 -> i8080 и занятые куски образа
    S2 = symbols(OUTDIR / "game.lst")
    amap = {}
    for u in units + fixed:
        if u.addr is None:
            continue
        new = S2["Z_%04X" % u.addr]
        amap[u.addr] = new
        # внутренность команды переезжает вместе с ней ТОЛЬКО если команда
        # осталась собой (не развёрнута) или это данные
        if u.lines is None:
            for k in range(1, u.nbytes):
                amap[u.addr + k] = new + k
    for u in units:                      # входы ручных модулей
        m = getattr(u, "native", None) if hasattr(u, "native") else None
        if m:
            for e in m["entries"]:
                if "Z_%04X" % e not in S2:
                    sys.exit("%s: нет метки Z_%04X (вход модуля)" % (m["src"], e))
                amap[e] = S2["Z_%04X" % e]
    # ПРИКОЛОЧЕННЫЕ КУСКИ В КАРТУ НЕ ПОПАДАЮТ.  Байты по их адресам —
    # инертная копия под графику логотипа; исполняемая копия тех же команд
    # уехала вместе со всем кодом, и G_xxxx обязан указывать на НЕЁ.
    (OUTDIR / "labels.json").write_text(json.dumps(
        {"map": {"%04X" % a: "%04X" % v for a, v in sorted(amap.items())},
         "used": [["%04X" % lo, "%04X" % (hi - 1)]
                  for lo, hi in sorted([tuple(x) for x in spans if x[1] > x[0]]
                                       + [(a, b + 1) for a, b in PIN])],
         "data_fixed": [["%04X" % u.addr, "%04X" % (u.addr + size[id(u)] - 1)] for u in fixed],
         "code_size": code_size, "rt_size": rt_size,
         # RST slots of page 0: JP to the compact (ix+d) helper of each form.
         "rst": {"%02X" % slot: ["il_%s_%s_b" % f, "%04X" % S2["il_%s_%s_b" % f]]
                 for f, slot in sorted(_ix_rst.items(), key=lambda x: x[1])
                 if f in _ix_used}}, indent=0))
    print("карта адресов: %d записей -> build/i8080/labels.json" % len(amap))
    if audit:
        print("\nРАЗБОР ФЛАГОВ:")
        for a, m in audit:
            print(f"  {a:04X}  {m}")


if __name__ == "__main__":
    main()
