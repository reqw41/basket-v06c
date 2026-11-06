#!/usr/bin/env python3
"""Mechanical Z80 -> i8080-subset rewrite of adapter sources (in place).

  python3 tools/z80to8080_mech.py src/v06/foo.asm [...]

jr cc,L / jr L  -> jp cc,L / jp L        (same flags, +1 byte)
djnz L          -> dec b / jp nz,L       (dec b sets Z/S/P: the line after
                                          each loop is printed for review)
Mnemonics stay Z80 syntax: sjasm --8080 accepts them for i8080 opcodes.
"""
import re
import sys
from pathlib import Path

RX = re.compile(r"^(?P<lab>(?:[\w.$]+:)?)(?P<ws>\s+)(?P<mn>jr|djnz)(?P<ws2>\s+)(?P<ops>[^;]*?)(?P<tail>\s*(?:;.*)?)$", re.I)


def convert(path: Path):
    lines = path.read_text().split("\n")
    out, review = [], []
    for i, line in enumerate(lines):
        m = RX.match(line)
        if not m:
            out.append(line)
            continue
        mn = m["mn"].lower()
        if mn == "jr":
            out.append(f"{m['lab']}{m['ws']}jp{m['ws2']}{m['ops']}{m['tail']}")
        else:
            out.append(f"{m['lab']}{m['ws']}dec{m['ws2']}b{m['tail']}")
            out.append(f"{m['ws']}jp{m['ws2']}nz,{m['ops'].strip()}")
            nxt = next((l.split(';')[0].strip() for l in lines[i + 1:]
                        if l.split(';')[0].strip()), "")
            review.append(f"{path.name}:{i + 1} djnz {m['ops'].strip()} -> next: {nxt}")
    path.write_text("\n".join(out))
    return review


if __name__ == "__main__":
    for a in sys.argv[1:]:
        for r in convert(Path(a)):
            print(r)
