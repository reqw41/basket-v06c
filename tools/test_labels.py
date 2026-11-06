#!/usr/bin/env python3
"""Gate: src/v06 names game and cross-module addresses, never numbers.

1. src/v06/labels*.inc are generated from cfg/labels.json (tools/gen_labels.py)
   and adapter labels hold their linked addresses (tools/link_labels.py).
2. Every label with a signature still has those bytes in the ROM image, so a
   moved routine fails here instead of being called at its old address
   (adapter-owned signatures are refreshed by each build).
3. No 0xNNNN literal outside labels.inc / ORG lines points into the game
   image (relocated D-block 3300..3F7F, work RAM 4000..4159, game 84D0..B257)
   or at any labelled address. Exceptions are listed in ALLOWED.
"""
import json, re, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
RANGES = ((0x3300, 0x3F80), (0x4000, 0x415A), (0x84D0, 0xB258))
ALLOWED = {
    ("court_tiles.asm", "COURT_TAIL-0x3300"),   # size arithmetic, not an address
    ("glue.asm", "call    0xD8EB"),             # MSX address, relocation manifest rewrites it
}


def main() -> int:
    fails = []
    r = subprocess.run([sys.executable, str(ROOT / "tools/gen_labels.py"), "--check"],
                       capture_output=True, text=True)
    if r.returncode:
        fails.append(r.stdout.strip())
    r = subprocess.run([sys.executable, str(ROOT / "tools/link_labels.py"), "--check"],
                       capture_output=True, text=True)
    if r.returncode:
        fails.append(r.stdout.strip()[-400:])
    labels = json.loads((ROOT / "cfg/labels.json").read_text())["labels"]
    mem = (ROOT / "build/v06/basket.full.bin").read_bytes()
    for name, e in labels.items():
        a = int(e["addr"], 16)
        if "sig" in e and mem[a:a + len(e["sig"]) // 2].hex() != e["sig"]:
            fails.append(f"{name} @{e['addr']}: bytes {mem[a:a + 3].hex()} != sig {e['sig']}")
    labelled = {int(e["addr"], 16) for e in labels.values()}
    for f in sorted((ROOT / "src/v06").glob("*.asm")):
        for n, line in enumerate(f.read_text().splitlines(), 1):
            code = line.split(";")[0]
            if re.match(r"\s*(org\b|#assert\b)", code, re.I) or any(f.name == a and b in code for a, b in ALLOWED):
                continue
            for m in re.finditer(r"0x([0-9A-Fa-f]{4})\b", code):
                v = int(m.group(1), 16)
                if v in labelled or any(lo <= v < hi for lo, hi in RANGES):
                    fails.append(f"{f.name}:{n}: raw address {m.group(0)}: {line.strip()[:70]}")
    for x in fails:
        print("FAIL", x)
    print("LABELS_FAIL" if fails else f"LABELS_PASS ({len(labels)} labels)")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
