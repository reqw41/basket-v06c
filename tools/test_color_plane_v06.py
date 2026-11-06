#!/usr/bin/env python3
"""Prove that C000..DFFF is a data-only high colour video plane."""

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from build_v06_rom import splash_plane_pair

B = ROOT / "build/v06"
ROM = B / "basket.rom"
LO, HI = 0xC000, 0xE000


def main() -> int:
    image = ROM.read_bytes()
    full = bytes(0x100) + image
    _low, expected_high = splash_plane_pair()
    if full[LO:HI] != expected_high:
        print("FAIL: C000..DFFF does not contain the expected initial splash plane")
        return 1

    digest = hashlib.sha256(image).hexdigest()
    seen = set()
    exec_violations = []
    write_scenarios = set()
    for path in sorted(B.glob("xref_match_*.json")):
        if path.name.endswith(".meta.json"):
            continue
        meta_path = path.with_name(path.stem + ".meta.json")
        if not meta_path.exists():
            continue
        meta = json.loads(meta_path.read_text())
        if meta.get("rom_sha256") != digest:
            continue
        scenario = meta.get("scenario", path.stem)
        seen.add(scenario)
        trace = json.loads(path.read_text())
        for kind in ("exec", "rd", "wr"):
            values = trace.get(kind, {})
            addresses = values.keys() if isinstance(values, dict) else values
            hits = sorted(int(a) for a in addresses if LO <= int(a) < HI)
            if kind == "exec" and hits:
                exec_violations.append((scenario, hits[:16]))
            if kind == "wr" and hits:
                write_scenarios.add(scenario)

    required = {"match_1p", "match_2p"}
    missing = required - seen
    if missing:
        print("FAIL: missing matching-ROM scenarios: " + ", ".join(sorted(missing)))
        return 1
    if exec_violations:
        for scenario, hits in exec_violations:
            print(f"FAIL: {scenario} executes high colour plane: " + " ".join(f"{a:04X}" for a in hits))
        return 1
    missing_writes = required - write_scenarios
    if missing_writes:
        print("FAIL: high colour plane was not rendered in: " + ", ".join(sorted(missing_writes)))
        return 1
    print(f"PASS: C000..DFFF contains splash data, is rendered at runtime and never executed across {len(seen)} scenarios")
    return 0


if __name__ == "__main__":
    sys.exit(main())
