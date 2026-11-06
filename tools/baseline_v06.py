#!/usr/bin/env python3
"""Freeze a reproducible baseline for consolidation work.

Rebuilds the ROM (optional), records SHA-256 of ROM/full/glue, glue
symbol snapshot, and refuses to mix analysis with a different image.

Output: build/v06/baseline.json
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


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def load_syms(lst: Path) -> dict[str, int]:
    syms = {}
    for line in lst.read_text(errors="replace").splitlines():
        m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s+=\s+\$([0-9A-Fa-f]+)", line)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    return syms


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rebuild", action="store_true", help="run build_v06_rom.py first")
    args = ap.parse_args()

    if args.rebuild:
        r = subprocess.run([sys.executable, str(ROOT / "tools/build_v06_rom.py")], cwd=ROOT)
        if r.returncode != 0:
            return r.returncode

    rom = B / "basket.rom"
    full = B / "basket.full.bin"
    glue = B / "glue.bin"
    lst = B / "glue.lst"
    for p in (rom, full, glue, lst):
        if not p.exists():
            print(f"missing {p}", file=sys.stderr)
            return 1

    syms = load_syms(lst)
    body_end = syms.get("REPLAY_X2", 0) + 16
    if "REPLAY_X2" not in syms:
        print("REPLAY_X2 missing from glue.lst", file=sys.stderr)
        return 1
    if syms["REPLAY_X2"] & 0x0F:
        print(f"REPLAY_X2 not 16-aligned: {syms['REPLAY_X2']:04X}", file=sys.stderr)
        return 1

    # Work RAM: DIRTY_OLD permanent at B258..B2C4 (outside freed 0100..0EFF /
    # D09C..DD17 and outside code window 84D0..B257).
    dirty_max = 27
    dirty_old = {
        "DIRTY_OLD_COUNT": 0xB258,
        "DIRTY_OLD_LIST": 0xB259,
        "bytes": 1 + dirty_max * 4,
        "end_inclusive": 0xB258 + 1 + dirty_max * 4 - 1,  # B2C4
        "temporary_was": "0D00..0D6C",
    }

    out = {
        "rom": str(rom),
        "rom_sha256": sha256(rom),
        "full_sha256": sha256(full),
        "glue_sha256": sha256(glue),
        "glue_lst_sha256": sha256(lst),
        "adapter_body": {"lo": 0x0200, "hi": body_end, "size": body_end - 0x0200},
        "symbols_key": {
            k: syms[k]
            for k in (
                "ADAPTER_INIT", "IRQ_HANDLER", "FRAME_BEGIN", "FRAME_END",
                "SPRITE_ROWS", "REPLAY_ZOOM", "REPLAY_X2", "REPLAY_GLYPH",
                "NATIVE_FRAME", "NATIVE_DIRTY", "PAGE0_BLOB",
            )
            if k in syms
        },
        "work_ram_not_free": {
            "DIRTY_OLD": dirty_old,
            "note": (
                "DIRTY_OLD is permanent work RAM at B258..B2C4. B2C5..B330 "
                "stores previous-frame sprite metadata; only B331..B337 is free."
            ),
        },
        "target_code_window": {"lo": 0x84D0, "hi": 0xB258, "size": 0xB258 - 0x84D0},
    }
    B.mkdir(parents=True, exist_ok=True)
    (B / "baseline.json").write_text(json.dumps(out, indent=2) + "\n")
    print(f"baseline rom={out['rom_sha256'][:16]}… adapter={out['adapter_body']['size']}B")
    print(f"DIRTY_OLD occupies {dirty_old['DIRTY_OLD_COUNT']:04X}..{dirty_old['end_inclusive']:04X} "
          f"({dirty_old['bytes']}B); temporary was {dirty_old['temporary_was']}")
    print(f"wrote {B / 'baseline.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
