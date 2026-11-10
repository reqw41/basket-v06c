#!/usr/bin/env python3
"""Print procedures of the inventory as Z80 listings: show.py 386E [9919 ...]"""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
inv = {p['entry']: p for p in json.loads((ROOT / 'build/native/inventory.json').read_text())['procs']}
lines = {}
for l in (ROOT / 'disasm/v06/game.asm').read_text().splitlines():
    m = re.match(r'^\t(\w+)\s*([^;]*?)\s*;\s*([0-9A-F]{4})\s', l)
    if m and m.group(1) not in ('db', 'dw', 'ds'):
        lines[int(m.group(3), 16)] = f'{m.group(1)} {m.group(2)}'.strip()
for arg in sys.argv[1:]:
    e = int(arg, 16); p = inv[e]
    print(f'; ---- {e:04X}: {p["bytes"]} bytes, callers {" ".join("%04X" % c for c in p["callers"])}')
    prev = None
    for a in p['body']:
        if prev is not None and a != prev:
            print('      ...')
        print(f'{a:04X}  {lines[a]}')
        n = len(re.findall(r'[0-9A-F]{2}', ''))  # unused
        prev = None
        nxt = [b for b in p['body'] if b > a]
        prev = nxt[0] if nxt else None
        # contiguity check by next instruction address
        prev = None
