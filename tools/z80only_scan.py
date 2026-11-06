#!/usr/bin/env python3
"""List Z80-only instructions in adapter sources (i8080 conversion aid).

  python3 tools/z80only_scan.py [files...]     # default src/v06/*.asm
Prints per-file counts by class and, with -v, every site.
"""
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
R16 = r"(bc|de|hl|sp|ix|iy)"
RULES = [
    ("jr", r"^jr\b"), ("djnz", r"^djnz\b"),
    ("ix/iy", r"\b(ix|iy|ixh|ixl|iyh|iyl)\b"),
    ("cb-bit", r"^(bit|set|res)\b"), ("cb-shift", r"^(rl|rr|rlc|rrc|sla|sra|srl|sll)\b"),
    ("ld rr,(nn)", r"^ld\s+(bc|de|sp)\s*,\s*\("), ("ld (nn),rr", r"^ld\s+\([^)]*\)\s*,\s*(bc|de|sp)\b"),
    ("ld sp,hl", r"^ld\s+sp\s*,\s*hl"),
    ("adc/sbc hl", r"^(adc|sbc)\s+hl"), ("neg", r"^neg\b"),
    ("block", r"^(ldir|lddr|ldi|ldd|cpir|cpdr|cpi|cpd|inir|otir|outi|ini)\b"),
    ("exx/ex af", r"^(exx|ex\s+af)"), ("im/i/r", r"^(im|reti|retn|rld|rrd)\b|^ld\s+(a\s*,\s*[ir]\b|[ir]\s*,)"),
    ("in/out (c)", r"^(in|out)\b.*\(c\)"),
]
LEGAL_SP = re.compile(r"^ld\s+sp\s*,\s*hl")


def scan(path: Path):
    hits = []
    for n, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
        code = line.split(";", 1)[0].strip()
        if not code or code.endswith(":") and " " not in code:
            continue
        code = re.sub(r"^[\w.$]+:\s*", "", code).lower()
        for cls, rx in RULES:
            if cls == "ld sp,hl":
                continue
            if re.search(rx, code):
                hits.append((cls, n, code))
                break
    return hits


def main():
    verbose = "-v" in sys.argv
    files = [Path(a) for a in sys.argv[1:] if a != "-v"] or sorted((ROOT / "src/v06").glob("*.asm"))
    total = Counter()
    for f in files:
        h = scan(f)
        c = Counter(x[0] for x in h)
        total += c
        if h:
            print(f"{f.name:28s} {len(h):4d}  " + ", ".join(f"{k} {v}" for k, v in c.most_common()))
        if verbose:
            for cls, n, code in h:
                print(f"    {n:5d} {cls:12s} {code}")
    print(f"{'TOTAL':28s} {sum(total.values()):4d}  " + ", ".join(f"{k} {v}" for k, v in total.most_common()))


if __name__ == "__main__":
    main()
