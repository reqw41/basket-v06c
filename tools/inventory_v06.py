#!/usr/bin/env python3
"""DEPRECATED occupancy sketch — use tools/cfg_map_v06.py + baseline_v06.py.

This script mixed stale xref without ROM SHA binding and must not be used for
consolidation budget. Kept only as a pointer.
"""
from __future__ import annotations

import sys


def main() -> int:
    print(
        "tools/inventory_v06.py is retired for budgeting.\n"
        "Use:\n"
        "  python3 tools/baseline_v06.py\n"
        "  python3 tools/cfg_map_v06.py --require-baseline\n"
        "  python3 tools/run_xref_scenarios.py\n"
        "See docs/consolidate-report.md",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
