#!/usr/bin/env python3
"""Move adapter unit boundaries in cfg/current_memory_map.json to the build.

  python3 tools/sync_memory_map.py           # after tools/build_v06_rom.py
  python3 tools/sync_memory_map.py --check   # fail if the map is out of date

A region with "unit": "<stem>" holds src/v06/<stem>.asm assembled at
"unit_org" (default: the region's lo); its end is unit_org + size of
build/v06/<stem>.bin, or the "unit_end" symbol of build/v06/<stem>.lst. A unit that fills its slot has no tail; otherwise the region with "tail_of": "<stem>" is the proven-free
zero tail after it and starts there. Also writes the ROM SHA-256 into the
map and cfg/memory_budget.json. The padding proofs themselves stay with
tools/classify_memory_v06.py.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAP = ROOT / "cfg/current_memory_map.json"
BUDGET = ROOT / "cfg/memory_budget.json"
B = ROOT / "build/v06"


def sync() -> list[str]:
    m = json.loads(MAP.read_text())
    regions = m["regions"]
    changes = []
    for i, r in enumerate(regions):
        unit = r.get("unit")
        if not unit:
            continue
        if "unit_end" in r:          # end symbol, when the .bin holds more
            lst = (B / f"{unit}.lst").read_text(errors="replace")
            end = int(re.search(rf"^{r['unit_end']}\s+= \$([0-9A-F]{{4}})", lst, re.M).group(1), 16)
        else:
            org = int(r.get("unit_org", r["lo"]), 16)
            end = org + (B / f"{unit}.bin").stat().st_size
        tail = next((k for k, t in enumerate(regions) if t.get("tail_of") == unit), None)
        want = f"{end:04X}"
        if tail is None:             # a unit that fills its slot: no free tail
            nxt = regions[i + 1] if i + 1 < len(regions) else None
            if nxt is not None and end > int(nxt["lo"], 16):
                raise SystemExit(f"{unit}: ends at {end:04X}, past {nxt['id']} {nxt['lo']}")
            if r["hi"] != want:
                changes.append(f"{r['id']} {r['lo']}..{r['hi']} -> ..{want}")
                r["hi"] = want
            continue
        if tail != i + 1:
            raise SystemExit(f"{unit}: tail region must follow {r['id']}")
        t = regions[tail]
        if end > int(t["hi"], 16):
            raise SystemExit(f"{unit}: ends at {end:04X}, past its slot {t['hi']}")
        if r["hi"] != want:
            changes.append(f"{r['id']} {r['lo']}..{r['hi']} -> ..{want}")
            r["hi"] = t["lo"] = want
    sha = hashlib.sha256((B / "basket.rom").read_bytes()).hexdigest()
    if m["rom_sha256"] != sha:
        changes.append("rom_sha256")
        m["rom_sha256"] = sha
    budget = json.loads(BUDGET.read_text())
    if budget.get("rom_sha256_baseline") != sha:
        budget["rom_sha256_baseline"] = sha
        if "--check" not in sys.argv:
            BUDGET.write_text(json.dumps(budget, indent=2, ensure_ascii=False) + "\n")
    if changes and "--check" not in sys.argv:
        MAP.write_text(json.dumps(m, indent=2, ensure_ascii=False) + "\n")
    # Proven-free total for tools/test_classify_memory_v06.py.
    import subprocess
    subprocess.run([sys.executable, str(ROOT / "tools/classify_memory_v06.py")],
                   capture_output=True, text=True, check=False)
    rep = json.loads((B / "memory_classification.json").read_text())
    if m.get("reclaimable_bytes") != rep["reclaimable_bytes"]:
        changes.append(f"reclaimable_bytes {m.get('reclaimable_bytes')} -> {rep['reclaimable_bytes']}")
        m["reclaimable_bytes"] = rep["reclaimable_bytes"]
        if "--check" not in sys.argv:
            MAP.write_text(json.dumps(m, indent=2, ensure_ascii=False) + "\n")
    return changes


def main() -> int:
    ch = sync()
    if "--check" in sys.argv:
        print("memory map out of date: " + "; ".join(ch) if ch else "memory map in sync")
        return 1 if ch else 0
    print("\n".join(ch) if ch else "memory map in sync")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
