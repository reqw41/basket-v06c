#!/usr/bin/env python3
"""Gate: no game path may reach the retired MSX VDP port emulation.

Scans the relocated system block and the game image for the patched port
opcodes (RST 08/10/20/28 followed by NOP). A site is "observed" when a
matching-SHA xref scenario executed it. Exit 1 if any site is observed, or
if a byte pair is not one of the known data false positives (3418: operand
of JP D77E; 3488: table byte).
"""
from __future__ import annotations
import hashlib, json
from collections import Counter
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
B=ROOT/'build/v06'; ROM=B/'basket.rom'; FULL=B/'basket.full.bin'
OPS={0xCF:'OUT98',0xD7:'OUT99',0xE7:'IN99',0xEF:'IN98'}

def main()->int:
    sha=hashlib.sha256(ROM.read_bytes()).hexdigest()
    mem=FULL.read_bytes()
    scenarios={}
    for meta in sorted(B.glob('xref_*.meta.json')):
        m=json.loads(meta.read_text())
        if m.get('rom_sha256')!=sha: continue
        data=meta.with_name(meta.name.replace('.meta.json','.json'))
        if data.exists(): scenarios[meta.stem.removesuffix('.meta')]=set(json.loads(data.read_text()).get('exec',[]))
    sites=[]
    for a in list(range(0x3304, 0x3F80)) + list(range(0x84D0, 0xB258)):
        kind=OPS.get(mem[a])
        if kind and mem[a+1]==0:
            hits=[n for n,ex in scenarios.items() if a in ex]
            sites.append({'addr':f'{a:04X}','kind':kind,'observed':bool(hits),'scenarios':hits})
    counts=Counter((x['kind'],x['observed']) for x in sites)
    report={'rom_sha256':sha,'scenario_count':len(scenarios),'sites':sites,
            'summary':{k:{'total':sum(1 for x in sites if x['kind']==k),
                          'observed':counts[(k,True)],'unobserved':counts[(k,False)]} for k in OPS.values()}}
    out=B/'softvdp_inventory.json'; out.write_text(json.dumps(report,indent=2)+'\n')
    print(f"ROM {sha}")
    for k,row in report['summary'].items(): print(f"{k:5} total={row['total']:2} observed={row['observed']:2} unobserved={row['unobserved']:2}")
    print('observed sites:', ' '.join(x['addr'] for x in sites if x['observed']))
    print(out)
    known_data = {"3418", "3488"}
    bad = [x["addr"] for x in sites if x["observed"] or x["addr"] not in known_data]
    if not scenarios:
        print("SOFTVDP_GATE_FAIL: no matching-SHA scenario traces"); return 1
    if bad:
        print("SOFTVDP_GATE_FAIL:", " ".join(bad)); return 1
    print(f"SOFTVDP_GATE_PASS ({len(scenarios)} scenarios)")
    return 0
if __name__=='__main__': raise SystemExit(main())
