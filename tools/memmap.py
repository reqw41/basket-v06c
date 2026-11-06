#!/usr/bin/env python3
"""Memory map of the native Z80 image by procedures and resources.

Inputs: build/v06/xref_*.json (smoke_v06js.js --xref), build/v06/basket.rom,
z80dasm listing of the game overlay (CALL targets = procedure entries).
Output: build/v06/memmap.json + a text summary on stdout.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
B = ROOT / "build/v06"
GAME_LO, GAME_HI = 0x84D0, 0xDD18

rom = (B / "basket.rom").read_bytes()
mem = bytearray(0x10000)
mem[0x100:0x100 + len(rom)] = rom

fetch, execd, rd, wr = set(), set(), {}, {}
for f in sorted(B.glob("xref_*.json")):
    x = json.loads(f.read_text())
    fetch |= set(x["fetch"])
    execd |= set(x["exec"])
    for src, dst in ((x["rd"], rd), (x["wr"], wr)):
        for a, pcs in src.items():
            dst.setdefault(int(a), set()).update(pcs)

# ---- procedure entries: executed CALL targets from the static listing
game = bytes(mem[GAME_LO:GAME_HI])
(tmp := Path("/tmp/memmap_game.bin")).write_bytes(game)
lst = subprocess.run(["z80dasm", "-a", "-l", "-g", hex(GAME_LO), str(tmp)],
                     capture_output=True, text=True).stdout
entries = {int(m, 16) for m in re.findall(r"call (?:[a-z]+,)?sub_([0-9a-f]{4})h", lst)}
entries = {e for e in entries if e in execd}
entries |= {GAME_LO, 0x84E8, 0x8508, 0xD48B}
for pc in execd:                                   # runtime-only CALL targets
    if GAME_LO <= pc < GAME_HI and mem[pc] == 0xCD:
        t = mem[pc + 1] | mem[pc + 2] << 8
        if GAME_LO <= t < GAME_HI and t in execd:
            entries.add(t)
entries = sorted(e for e in entries if GAME_LO <= e < GAME_HI)

NAMES = {
    0x84D0: "таблица переходов",
    0x84E8: "пролог (однократно)",
    0x8508: "главный цикл: меню → матч",
    0x88EF: "ИИ второго игрока",
    0xA4A8: "меню capture (RET, плоскость)",
    0xA694: "меню: опрос 1..5",
    0xAC00: "звуковой драйвер (WRTPSG)",
    0xAF05: "опрос управления → AC4D/AC4E",
    0xB1F2: "битмап → VRAM (кадр)",
    0xB1FE: "битмап → VRAM строки 1..14",
    0xCC76: "заставка: мяч крутится",
    0xCF08: "заливка VRAM (загрузчик)",
    0xD358: "инициализация железа",
    0xD48B: "прерывание: клавиатура, 410F/4110",
    0xD5DE: "тест клавиши A=ряд*8+бит",
}


def proc_of(pc):
    if not (GAME_LO <= pc < GAME_HI):
        return None
    lo, hi = 0, len(entries) - 1
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if entries[mid] <= pc:
            lo = mid
        else:
            hi = mid - 1
    return entries[lo] if entries[lo] <= pc else None


def owner(pc):
    if pc < 0x1000:
        return "adapter"
    p = proc_of(pc)
    return f"{p:04X}" if p is not None else f"?{pc:04X}"


# ---- procedures
procs = []
for i, e in enumerate(entries):
    end = entries[i + 1] if i + 1 < len(entries) else GAME_HI
    code = sum(1 for a in range(e, end) if a in fetch)
    last = max((a for a in range(e, end) if a in fetch), default=e)
    tags = set()
    for pc in range(e, end):
        if pc not in execd:
            continue
        op = mem[pc]
        if op in (0xCF, 0xD7, 0xE7, 0xEF):
            tags.add("VDP")
        if op == 0xCD:
            t = mem[pc + 1] | mem[pc + 2] << 8
            if t in (0xD5DE, 0x0141):
                tags.add("ввод")
            if t in (0x0093, 0xAC00):
                tags.add("звук")
            if t in (0x01E0, 0x01E3):
                tags.add("VDP")
        if op in (0xDD, 0xFD):
            tags.add("IX/IY")
    procs.append(dict(addr=e, end=end, code=code, span=last - e + 1,
                      name=NAMES.get(e, ""), tags=sorted(tags)))

# ---- data: every non-fetched byte that was read or written
data = sorted(a for a in set(rd) | set(wr) if a not in fetch and 0x1000 <= a < 0xE000)
regions = []
for a in data:
    who = frozenset(owner(p) for p in rd.get(a, set()) | wr.get(a, set()))
    kind = "rw" if a in wr else "ro"
    if regions and a - regions[-1]["end"] <= 2 and regions[-1]["kind"] == kind \
            and (who & regions[-1]["who"] or a - regions[-1]["end"] == 0):
        r = regions[-1]
        r["end"] = a + 1
        r["who"] |= who
        r["bytes"] += 1
    else:
        regions.append(dict(start=a, end=a + 1, kind=kind, who=set(who), bytes=1))

# merge tiny neighbours with the same owners into blocks for the overview
for r in regions:
    r["who"] = sorted(r["who"])

out = dict(procs=procs, regions=regions,
           fetch_total=len([a for a in fetch if GAME_LO <= a < GAME_HI]),
           game_size=GAME_HI - GAME_LO)
(B / "memmap.json").write_text(json.dumps(out, ensure_ascii=False))

print(f"procedures {len(procs)}  code bytes fetched {out['fetch_total']} / {out['game_size']}")
big = sorted(procs, key=lambda p: -p["code"])[:40]
for p in big:
    print(f"  {p['addr']:04X}-{p['end'] - 1:04X} code {p['code']:5d} {','.join(p['tags']):12s} {p['name']}")
print(f"data regions {len(regions)}")
for r in sorted(regions, key=lambda r: -r["bytes"])[:60]:
    who = " ".join(r["who"][:8]) + (" …" if len(r["who"]) > 8 else "")
    print(f"  {r['start']:04X}-{r['end'] - 1:04X} {r['bytes']:5d} {r['kind']} {who}")
