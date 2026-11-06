#!/usr/bin/env python3
"""Regression checks for ball transparency, stand colours, and dunk frames.

Independent etalons (not produced by the code under test):
  • Executive MSX sprite masks in ref/msx/executive/executive.block1.bin
  • Raw CPC sprites src/assets/cpc_sprites_v06_2plane.bin
  • CPC court bank src/assets/cpc_court_mode1.bin
Live dunk / restore paths are exercised by tools/test_dunk_anim.js.
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from prepare_cpc_sprite_bank import load_msx_opaque_masks  # mask loader only

ROM = ROOT / "build/v06/basket.rom"
PREPARED = ROOT / "build/v06/cpc_sprites_msx_layout.bin"
CPC_SPRITES = ROOT / "src/assets/cpc_sprites_v06_2plane.bin"
CPC_COURT = ROOT / "src/assets/cpc_court_mode1.bin"
COURT_SHA = "5c5f0a541dfd9a07b5f57323a4fab739bd96b78f9a53c1477dda2d43396e35d8"
LAYOUT = json.loads((ROOT / "cfg/cpc_sprite_layout.json").read_text())
BALL_INDEX = 72


def fail(msg: str) -> int:
    print(f"FAIL: {msg}")
    return 1


def cpc_pen_at(raw: bytes, source: int, w: int, x: int, y: int) -> int:
    stride = (w + 7) // 8
    start = source + 2 + y * stride * 2
    bit = 0x80 >> (x & 7)
    return bool(raw[start + x // 8] & bit) + 2 * bool(raw[start + stride + x // 8] & bit)


def prepared_record(index: int) -> tuple[int, int, bytes]:
    prepared = PREPARED.read_bytes()
    count = LAYOUT["runtime_records"]
    table = len(prepared) - count * 2
    offset = int.from_bytes(prepared[table + index * 2 : table + index * 2 + 2], "little")
    h, width, top, keep = prepared[offset : offset + 4]
    stride = (width + 7) // 8
    rows = bytes(top * stride * 2) + prepared[offset + 4 : offset + 4 + keep * stride * 2]
    return h, width, rows + bytes((h - top - keep) * stride * 2)


def prepared_pen(payload: bytes, width: int, x: int, y: int) -> int:
    stride = (width + 7) // 8
    start = y * stride * 2
    bit = 0x80 >> (x & 7)
    return bool(payload[start + x // 8] & bit) + 2 * bool(payload[start + stride + x // 8] & bit)


def test_ball_pens() -> int:
    if not PREPARED.exists():
        return fail(f"missing {PREPARED}; build the ROM first")
    raw = CPC_SPRITES.read_bytes()
    count = LAYOUT["source_records"]
    table = len(raw) - count * 2
    source = int.from_bytes(raw[table + BALL_INDEX * 2 : table + BALL_INDEX * 2 + 2], "little")
    h, w = raw[source], raw[source + 1]
    if (h, w) != (8, 8):
        return fail(f"ball index {BALL_INDEX} is {w}x{h}, want 8x8")
    opaque = load_msx_opaque_masks(LAYOUT["runtime_records"])[BALL_INDEX]
    _, width, payload = prepared_record(BALL_INDEX)
    punched = kept_black = 0
    for y in range(h):
        for x in range(w):
            cpc = cpc_pen_at(raw, source, w, x, y)
            out = prepared_pen(payload, width, x, y)
            if not opaque[y][x]:
                if out != 0:
                    return fail(f"ball {x},{y}: MSX-transparent but prepared pen {out}")
                if cpc != 0:
                    punched += 1
            else:
                if cpc != 0 and out == 0:
                    return fail(f"ball {x},{y}: opaque CPC pen {cpc} lost")
                if cpc == 1 and out == 1:
                    kept_black += 1
    if punched < 4:
        return fail(f"need MSX mask to punch CPC corner ink; punched={punched}")
    if kept_black < 8:
        return fail(f"need solid black ink inside the ball; kept_black={kept_black}")
    # ROM must contain the prepared ball record.
    rom = ROM.read_bytes()
    if prepared_record(BALL_INDEX)[2] not in rom:
        return fail("prepared ball payload missing from ROM image")
    print(f"PASS ball pens: punched {punched} transparent CPC inks; kept {kept_black} opaque black pixels")
    return 0


def cpc_mode1_pen(bank: bytes, game_y: int, x: int) -> int:
    """CPC Mode1 pen at game row y>=8, pixel x — same bit layout as the CPC bank."""
    value = bank[(game_y - 8) * 64 + x // 4]
    q = x % 4
    return ((value >> (7 - q)) & 1) | (((value >> (3 - q)) & 1) << 1)


def test_stands_cpc_bank() -> int:
    bank = CPC_COURT.read_bytes()
    if hashlib.sha256(bank).hexdigest() != COURT_SHA:
        return fail("cpc_court_mode1.bin sha mismatch")
    # Spectators: game rows 16..39 (CPC rows 8..31). Require all four pens present
    # and pink (CPC pen 3 → Vector 3) somewhere in the crowd band.
    pens_seen = {0, 1, 2, 3}
    found = set()
    pink = 0
    for y in range(16, 40):
        for x in range(32, 224):
            cpc = cpc_mode1_pen(bank, y, x)
            found.add(cpc)
            if cpc == 3:
                pink += 1
    if found != pens_seen:
        return fail(f"CPC stands miss pens {sorted(pens_seen - found)}; got {sorted(found)}")
    if pink < 200:
        return fail(f"CPC stands lack pink crowd pixels; pink={pink}")
    # Packed tile pairs outside VECTOR rows must match this independent decode.
    # Prefer live ROM fetcher check in JS; here compare packer output rows 8..40
    # only after rebuilding pairs from Mode1 without importing pack_court helpers
    # that also apply VECTOR (rows 41+).
    remap = [0, 2, 1, 3]
    expected = ROOT / "build/v06/expected_court_pairs.bin"
    if not expected.exists():
        return fail("missing expected_court_pairs.bin")
    pairs = expected.read_bytes()
    bad = 0
    checked = 0
    for y in range(8, 41):
        for col in range(32):
            lo = hi = 0
            for x in range(8):
                pen = remap[cpc_mode1_pen(bank, y, col * 8 + x)]
                bit = 0x80 >> x
                if pen & 1:
                    lo |= bit
                if pen & 2:
                    hi |= bit
            i = (y * 32 + col) * 2
            if (pairs[i], pairs[i + 1]) != (lo, hi):
                bad += 1
            checked += 1
    if bad:
        return fail(f"packed stand rows 8..40 disagree with CPC Mode1 in {bad}/{checked} cells")
    print(f"PASS stands pack: rows 8..40 ({checked} cells) match CPC Mode1; pink pixels={pink}")
    return 0


def test_hoop_pens() -> int:
    """Right-side hoops keep CPC ink and sit on the 24px MSX canvas (+4 pad)."""
    if not PREPARED.exists():
        return fail(f"missing {PREPARED}; build the ROM first")
    raw = CPC_SPRITES.read_bytes()
    count = LAYOUT["source_records"]
    table = len(raw) - count * 2
    offsets = {int(k): int(v) for k, v in LAYOUT.get("x_offsets_pixels", {}).items()}
    canvases = {int(k): int(v) for k, v in LAYOUT.get("canvas_widths", {}).items()}
    # 62 = left rest (20px), 67 = right rest (24px canvas, dx=4).
    for index in (62, 67):
        source = int.from_bytes(raw[table + index * 2 : table + index * 2 + 2], "little")
        h, w = raw[source], raw[source + 1]
        if (h, w) != (24, 20):
            return fail(f"hoop index {index} source is {w}x{h}, want 20x24")
        _, width, payload = prepared_record(index)
        dx = offsets.get(index, 0)
        want_w = canvases.get(index, w)
        if width != want_w:
            return fail(f"hoop {index}: prepared width {width}, want {want_w}")
        lost = 0
        for y in range(h):
            for x in range(w):
                cpc = cpc_pen_at(raw, source, w, x, y)
                out = prepared_pen(payload, width, x + dx, y)
                if cpc and out != cpc:
                    lost += 1
        if lost:
            return fail(f"hoop {index}: prepared lost/changed {lost} CPC opaque pens")
        if index == 67 and dx != 4:
            return fail(f"hoop 67: expected dx=4 for MSX sideline align, got {dx}")
    print("PASS hoop pens: left/right rest frames keep CPC ink; right on 24px canvas")
    return 0


def test_dunk_js() -> int:
    script = ROOT / "tools/test_dunk_anim.js"
    r = subprocess.run(["node", str(script), str(ROM)], cwd=ROOT, capture_output=True, text=True)
    sys.stdout.write(r.stdout)
    sys.stderr.write(r.stderr)
    return r.returncode


def main() -> int:
    if not ROM.exists():
        return fail(f"missing {ROM}")
    for step in (test_ball_pens, test_hoop_pens, test_stands_cpc_bank, test_dunk_js):
        rc = step()
        if rc:
            return rc
    print("PASS visual regressions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
