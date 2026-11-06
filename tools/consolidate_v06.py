#!/usr/bin/env python3
"""Consolidation driver — entity-level only.

The previous byte-compaction algorithm (mark_live / compact / fix_relative_jumps
scanning every byte as JR) is retired. This tool refuses to run it.

Use:
  tools/baseline_v06.py --rebuild
  tools/cfg_map_v06.py --require-baseline
  tools/xfer_entity_v06.py …   (staged entity moves)

See docs/consolidate-report.md.
"""
from __future__ import annotations

import sys


def main() -> int:
    print(
        "tools/consolidate_v06.py: byte-compaction path DISABLED.\n"
        "Reasons (fixed in methodology):\n"
        "  - mark_live marked only insn starts; operands could be dropped\n"
        "  - fix_relative_jumps scanned every byte as JR/DJNZ\n"
        "  - abs_op_sites linear decode ≠ proven insn starts\n"
        "  - B258..B2C4 is DIRTY_OLD work RAM, not free code space\n"
        "Use tools/baseline_v06.py, tools/cfg_map_v06.py, tools/xfer_entity_v06.py.\n"
        "Do not treat build/v06/basket-consolidated.rom as a working base.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
