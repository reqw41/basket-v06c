#!/usr/bin/env python3
"""Stage entity transfers for consolidation (assembler-level).

Each transfer is a named entity with explicit old/new ranges and a checklist.

  dirty_old_to_b258 — restore DIRTY_OLD_COUNT/LIST to permanent B258..B2C4
                      (outside freed 0100..0EFF / D09C..DD17 and outside
                      code window 84D0..B257). Source edit + rebuild.

  replay_to_window  — relocate replay.asm module into a proven-free span
                      inside 84D0..B257 (requires sufficient contiguous free).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
B = ROOT / "build/v06"
SOFT = ROOT / "src/v06/softvdp.asm"
REPLAY = ROOT / "src/v06/replay.asm"
GLUE = ROOT / "src/v06/glue.asm"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rebuild() -> int:
    return subprocess.run(
        [sys.executable, str(ROOT / "tools/build_v06_rom.py")], cwd=ROOT
    ).returncode


def verify_smoke_replay() -> int:
    """Behavioral checks vs control expectations (match path + replay unit)."""
    r1 = subprocess.run(
        ["node", str(ROOT / "tools/smoke_v06js.js"), str(B / "basket.rom"), "400", "--input"],
        cwd=ROOT,
    )
    if r1.returncode != 0:
        return r1.returncode
    r2 = subprocess.run(
        ["node", str(ROOT / "tools/test_replay_zoom.js"), str(B / "basket.rom")],
        cwd=ROOT,
    )
    if r2.returncode != 0:
        return r2.returncode
    r3 = subprocess.run(
        [sys.executable, str(ROOT / "tools/test_b01c_sprite.py")],
        cwd=ROOT,
    )
    return r3.returncode


def entity_dirty_old_to_b258() -> int:
    """Restore DIRTY_OLD to permanent B258 work RAM."""
    text = SOFT.read_text()
    if "DIRTY_OLD_COUNT equ     0xB258" in text:
        print("dirty_old: already at 0xB258")
    elif "DIRTY_OLD_COUNT equ     0x0D00" in text:
        text = text.replace(
            "DIRTY_OLD_COUNT equ     0x0D00",
            "DIRTY_OLD_COUNT equ     0xB258",
        ).replace(
            "DIRTY_OLD_LIST  equ     0x0D01",
            "DIRTY_OLD_LIST  equ     0xB259",
        )
        SOFT.write_text(text)
        print("dirty_old: softvdp.asm equ 0D00 → B258")
    else:
        print("dirty_old: unexpected softvdp.asm equ layout", file=sys.stderr)
        return 1

    rc = rebuild()
    if rc != 0:
        return rc

    src = SOFT.read_text()
    if "0xB258" not in src or "DIRTY_OLD_COUNT" not in src:
        print("verify failed: source", file=sys.stderr)
        return 1

    report = {
        "entity": "dirty_old_to_b258",
        "old": {"DIRTY_OLD_COUNT": 0x0D00, "DIRTY_OLD_LIST": 0x0D01, "span": "0D00..0D6C"},
        "new": {"DIRTY_OLD_COUNT": 0xB258, "DIRTY_OLD_LIST": 0xB259, "span": "B258..B2C4"},
        "size": 1 + 27 * 4,
        "align": 1,
        "address_deps": "none (absolute equ only)",
        "smc": False,
        "reason": (
            "Permanent work-RAM home outside freed 0100..0EFF and D09C..DD17, "
            "and outside code window 84D0..B257. Original MSX B258 pointer table "
            "unused after native patches; runtime DIRTY_OLD only."
        ),
        "rom_sha256": sha256(B / "basket.rom"),
        "entries": ["FRAME_BEGIN", "FRAME_END", "FRAME_RESET", "DIRTY_SAVE_OLD", "REPLAY_DONE"],
        "refs": "all via DIRTY_OLD_* equ in softvdp.asm / replay.asm",
    }
    (B / "xfer_dirty_old.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))

    print("verify: smoke + replay + sprite…")
    rc = verify_smoke_replay()
    report["verify_rc"] = rc
    (B / "xfer_dirty_old.json").write_text(json.dumps(report, indent=2) + "\n")
    return rc


def entity_replay_to_window() -> int:
    """Refuse placement unless a *verified* free entity span exists (not after-JP)."""
    cfg_path = B / "cfg_map.json"
    if not cfg_path.exists():
        print("run cfg_map_v06.py first", file=sys.stderr)
        return 1
    cfg = json.loads(cfg_path.read_text())
    budget = cfg.get("budget", {})
    if budget.get("proven_deletable", 0) != 0 or budget.get("after_jp_heuristic", {}).get("status") == "REVOKED":
        # After-JP revoked: only allow placement into an explicitly verified entity
        # listed in window_entities with disposition reclaim_verified (none yet).
        pass
    if budget.get("proven_deletable", 0) == 0:
        report = {
            "entity": "replay_to_window",
            "status": "blocked",
            "reason": (
                "No proven_deletable bytes. After-JP heuristic REVOKED "
                f"(xref_rd hits were {budget.get('after_jp_heuristic', {}).get('xref_rd_hits')}; "
                "examples include A798 menu text). Do not place code on unsafe candidates."
            ),
            "proven_deletable": 0,
            "available_proven_free": budget.get("available_proven_free", 0),
            "transfer_cost_as_is": budget.get("transfer_cost_as_is"),
        }
        (B / "xfer_replay.json").write_text(json.dumps(report, indent=2) + "\n")
        print(json.dumps(report, indent=2))
        return 2

    print("unexpected proven_deletable > 0 without verified entity path", file=sys.stderr)
    return 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--entity",
        required=True,
        choices=["dirty_old_to_b258", "dirty_old_to_0d00", "replay_to_window"],
    )
    args = ap.parse_args()
    if args.entity == "dirty_old_to_b258":
        return entity_dirty_old_to_b258()
    if args.entity == "dirty_old_to_0d00":
        print("retired: use dirty_old_to_b258 (0D00 was temporary)", file=sys.stderr)
        return 1
    if args.entity == "replay_to_window":
        return entity_replay_to_window()
    return 1


if __name__ == "__main__":
    sys.exit(main())
