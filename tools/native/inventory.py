#!/usr/bin/env python3
"""A0 inventory of the game logic: procedures, call graph, adapter calls.

  python3 tools/native/inventory.py [--md docs/native/INVENTORY.md] [--json build/native/inventory.json]

Reads disasm/v06/game.asm (tools/disasm_v06.py: every Z80 instruction of the
port's game window 84D0..B257 and of the relocated system block 3300..3F7F,
one per `Z_xxxx:` label with `; ADDR BYTES` after it).

A procedure starts at a CALL target, a game label of cfg/labels.json, an
RST/ISR/jump-table entry or 84D0; its body is everything reachable from the
entry by fall-through and JP/JR/DJNZ (not CALL), stopping at RET/JP (HL)
and at another procedure's entry (a jump there is a tail call). An
instruction reached from two entries belongs to the lower one (shared
tails are listed). For each procedure: size, instructions, callees (game /
adapter / BIOS-RST), memory it reads and writes by absolute address, and
self-modifying stores into code.
"""
from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASM = ROOT / "disasm/v06/game.asm"
RX_INSN = re.compile(r"^\t(\w+)\s*([^;]*?)\s*;\s*([0-9A-F]{4})\s+((?:[0-9A-F]{2}\s?)+)")
RX_LABEL = re.compile(r"^(\w+):\s*$")
RX_EQU = re.compile(r"^(\w+):\s+equ\s+0x([0-9A-F]{4})", re.I)
GAME = ((0x84D0, 0xB258), (0x3300, 0x3F80))


def in_game(a: int) -> bool:
    return any(lo <= a < hi for lo, hi in GAME)


def load():
    text = ASM.read_text().splitlines()
    equ, insns = {}, {}
    for line in text:
        m = RX_EQU.match(line)
        if m:
            equ[m.group(1)] = int(m.group(2), 16)
            continue
        m = RX_INSN.match(line)
        if m and m.group(1) not in ("db", "dw", "ds"):
            mn, ops, addr = m.group(1).lower(), m.group(2).strip(), int(m.group(3), 16)
            insns[addr] = {"mn": mn, "ops": ops, "n": len(m.group(4).split()), "bytes": m.group(4).strip()}
    return equ, insns


def target(ops: str, equ: dict) -> int | None:
    last = ops.split(",")[-1].strip()
    m = re.fullmatch(r"(?:Z_|D_)([0-9A-F]{4})", last)
    if m:
        return int(m.group(1), 16)
    if last in equ:
        return equ[last]
    m = re.fullmatch(r"0x([0-9A-Fa-f]{1,4})", last)
    if m:
        return int(m.group(1), 16)
    m = re.fullmatch(r"\$([+-]\d+)", last)
    return None if not m else ("rel", int(m.group(1)))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--md", default=str(ROOT / "docs/native/INVENTORY.md"))
    ap.add_argument("--json", default=str(ROOT / "build/native/inventory.json"))
    args = ap.parse_args()
    equ, insns = load()
    labels = json.loads((ROOT / "cfg/labels.json").read_text())["labels"]

    def resolve(a: int, ins: dict):
        t = target(ins["ops"], equ)
        if isinstance(t, tuple):
            return a + t[1]
        return t

    entries = {0x84D0}
    for n, e in labels.items():
        if e["kind"] in ("game_code", "sys_code"):
            entries.add(int(e["addr"], 16))
    calls = defaultdict(set)
    for a, ins in insns.items():
        if ins["mn"] == "call" or (ins["mn"] == "rst"):
            t = resolve(a, ins)
            if isinstance(t, int) and t in insns:
                entries.add(t)
    # jump tables: JP nn runs at the start of the window (84D0.. 84E5) are entries
    for a in range(0x84D0, 0x84E8, 3):
        if a in insns and insns[a]["mn"] == "jp":
            t = resolve(a, insns[a])
            if isinstance(t, int):
                entries.add(t)
    entries = {e for e in entries if e in insns}
    # a trampoline (an entry whose first instruction is an unconditional JP)
    # makes its target an entry too; and so does any target reached from two
    # entries (a shared body): repeat until nothing new appears
    while True:
        new = set()
        for e in entries:
            ins = insns[e]
            if ins["mn"] in ("jp", "jr") and "," not in ins["ops"] and not ins["ops"].startswith("("):
                t = resolve(e, ins)
                if isinstance(t, int) and t in insns and t not in entries:
                    new.add(t)
        if not new:
            break
        entries |= new

    def flow(a):
        ins = insns[a]
        mn, ops = ins["mn"], ins["ops"]
        succ = []
        uncond = mn in ("ret", "reti", "retn") and not ops or (mn == "jp" and ops.startswith("(")) \
            or (mn in ("jp", "jr") and "," not in ops)
        if mn in ("jp", "jr", "djnz"):
            t = resolve(a, ins)
            if isinstance(t, int) and in_game(t):
                succ.append(t)
        if not uncond:
            succ.append(a + ins["n"])
        return succ

    def bodies(entries):
        procs = {}
        for e in sorted(entries):
            body, todo = set(), [e]
            while todo:
                a = todo.pop()
                if a in body or a not in insns or (a != e and a in entries):
                    continue                              # another entry: a tail call
                body.add(a)
                todo += flow(a)
            procs[e] = body
        return procs

    # code no entry reaches (the game ISR 36F3 behind the 4141 vector, the
    # key parse reached through the ISR hook, computed jumps): every start of
    # such a run is an entry
    def reached(entries):
        seen = set()
        for b in bodies(entries).values():
            seen |= b
        return seen
    while True:
        seen = reached(entries)
        orphan = [a for a in sorted(insns) if a not in seen]
        starts = {a for a in orphan
                  if not any(p not in seen and a in flow(p) for p in orphan if p < a and p + insns[p]["n"] >= a - 3)}
        starts -= entries
        if not starts:
            break
        entries |= set(sorted(starts)[:1])                 # one at a time: its body may absorb the rest
    # a body reached from two entries becomes its own procedure: its join
    # points (shared addresses entered from outside the shared set) are entries
    while True:
        procs = bodies(entries)
        seen = defaultdict(set)
        for e, b in procs.items():
            for a in b:
                seen[a].add(e)
        multi = {a for a, s in seen.items() if len(s) > 1}
        joins = {t for a in seen if a not in multi for t in flow(a) if t in multi}
        if not joins:
            break
        entries |= joins
    owner, shared = {}, defaultdict(set)
    for e, body in procs.items():
        for a in body:
            if a in owner:
                shared[a].add(e)
            else:
                owner[a] = e
    out = []
    for e in sorted(procs):
        body = procs[e]
        callees_game, callees_ext, reads, writes, smc = set(), set(), set(), set(), set()
        nbytes = 0
        for a in body:
            ins = insns[a]
            nbytes += ins["n"]
            mn, ops = ins["mn"], ins["ops"]
            if mn in ("call", "rst") or (mn == "jp" and resolve(a, ins) in entries and resolve(a, ins) != e):
                t = resolve(a, ins)
                if isinstance(t, int):
                    (callees_game if in_game(t) else callees_ext).add(t)
            for m in re.finditer(r"\((?:Z_|D_)?([0-9A-F]{4})(?:\+\d+)?\)|\(([A-Z_][A-Z0-9_]*)(?:\+\d+)?\)", ops):
                if m.group(1):
                    addr = int(m.group(1), 16)
                elif m.group(2) in equ:
                    addr = equ[m.group(2)]
                else:
                    continue
                dst = ops.split(",")[0].strip().startswith("(")
                (writes if dst else reads).add(addr)
                if dst and addr in insns or (dst and any(addr - k in insns for k in (1, 2, 3))):
                    smc.add(addr)
        out.append({"entry": e, "insns": len(body), "bytes": nbytes, "body": sorted(a for a in body if owner.get(a) == e),
                    "calls": sorted(callees_game), "ext": sorted(callees_ext),
                    "reads": sorted(reads), "writes": sorted(writes), "smc": sorted(smc)})
    callers = defaultdict(set)
    for p in out:
        for c in p["calls"]:
            callers[c].add(p["entry"])
    for p in out:
        p["callers"] = sorted(callers[p["entry"]])
    covered = set(owner)
    orphans = sorted(a for a in insns if a not in covered)
    Path(args.json).parent.mkdir(parents=True, exist_ok=True)
    Path(args.json).write_text(json.dumps({"procs": out, "orphans": orphans,
                                           "shared": {f"{a:04X}": sorted(s) for a, s in shared.items()}}, indent=1))
    ext_names = {int(e["addr"], 16): n for n, e in labels.items()}
    for n, a in equ.items():
        ext_names.setdefault(a, n)
    lines = ["# Опись логики игры (A0, tools/native/inventory.py)", "",
             f"Команд Z80: {len(insns)}; процедур: {len(out)}; байт кода: "
             f"{sum(p['bytes'] for p in out)}; не отнесены к процедурам: {len(orphans)} команд"
             f"{' (' + ', '.join(f'{a:04X}' for a in orphans[:20]) + (' …' if len(orphans) > 20 else '') + ')' if orphans else ''}; "
             f"общих хвостов: {len(shared)}.", "",
             "| вход | команд | байт | зовут | вызывает (игра) | адаптер/BIOS | SMC |", "|---|---|---|---|---|---|---|"]
    for p in sorted(out, key=lambda p: -p["bytes"]):
        name = ext_names.get(p["entry"], "")
        lines.append(f"| {p['entry']:04X}{' ' + name if name else ''} | {p['insns']} | {p['bytes']} | {len(p['callers'])} | "
                     f"{' '.join(f'{c:04X}' for c in p['calls'][:8])}{' …' if len(p['calls']) > 8 else ''} | "
                     f"{' '.join(ext_names.get(c, f'{c:04X}') for c in p['ext'][:6])}{' …' if len(p['ext']) > 6 else ''} | "
                     f"{' '.join(f'{c:04X}' for c in p['smc'][:4])} |")
    Path(args.md).parent.mkdir(parents=True, exist_ok=True)
    Path(args.md).write_text("\n".join(lines) + "\n")
    print(f"{len(insns)} insns, {len(out)} procs, {len(orphans)} orphans, {len(shared)} shared -> {args.md}")


if __name__ == "__main__":
    main()
