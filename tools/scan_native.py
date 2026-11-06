#!/usr/bin/env python3
"""Scan the MSX overlay (native 84D0..DD18) by control flow.

Lists what a no-relocation Vector port must patch:
  - absolute operands in reachable code that point at DD18..FFFF
    (MSX high RAM / system area = Vector visible plane)
  - LD SP instructions
  - IN/OUT instructions (port, address)
"""
from __future__ import annotations

import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from reloc_overlay import find_reachable_code, ORIG_BASE, ORIG_END  # noqa: E402

ov = (ROOT / "ref/msx/executive/executive.overlay.bin").read_bytes()
mem = bytearray(0x10000)
mem[ORIG_BASE:ORIG_BASE + len(ov)] = ov

code = find_reachable_code(mem, ORIG_BASE, ORIG_BASE + len(ov), 0x84D0)


def text(pc, ins):
    return ins.fmt % ((hex(ins.operand),) if "%s" in ins.fmt else ())


high = defaultdict(list)
sp = []
io = []
low = defaultdict(list)
for pc in sorted(code):
    ins = code[pc]
    t = text(pc, ins)
    op = mem[pc]
    if "sp," in t and t.startswith("ld sp"):
        sp.append((pc, t))
    if op in (0xD3, 0xDB) or (op == 0xED and mem[pc + 1] & 0xC6 in (0x40, 0x41)):
        io.append((pc, t))
    v = getattr(ins, "operand", None)
    if v is None or ins.length < 3:
        continue
    if v >= 0xDD18:
        high[v].append((pc, t))
    elif v < 0x4000 and v >= 0x0200:
        low[v].append((pc, t))

print(f"reachable insns: {len(code)}")
print("\n== LD SP ==")
for pc, t in sp:
    print(f"  {pc:04X} {t}")
print("\n== I/O ==")
for pc, t in io:
    print(f"  {pc:04X} {t}")
print("\n== operands >= DD18 ==")
for v in sorted(high):
    sites = high[v]
    print(f"  {v:04X} x{len(sites)}: " + ", ".join(f"{pc:04X} {t}" for pc, t in sites[:4]))
print("\n== operands 0200..3FFF ==")
for v in sorted(low):
    sites = low[v]
    print(f"  {v:04X} x{len(sites)}: " + ", ".join(f"{pc:04X} {t}" for pc, t in sites[:3]))
