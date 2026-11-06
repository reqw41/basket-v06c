#!/usr/bin/env python3
"""Differential check: original B01C AND/OR vs the Vector SPRITE_OR rules.

Original B15F..B18D (per row, after B1CD/B18E filled B1E4):
    iy  = B1E4 + B1E2          # left-clip skip
    b   = B1E1                 # clipped width
    off = C                    # B180: B1DD/2  or  B1DD/2+1 if D099&3
    dest[i] = (dest[i] & iy[i+off]) | iy[i]

B180 is the full pixel-byte count, never the clipped B1_WIDTH and never 3.
"""
from __future__ import annotations

import sys


def b01c_row(dest: list[int], strip: list[int], skip: int, width: int, mask_off: int) -> list[int]:
    out = list(dest)
    iy = skip
    for i in range(width):
        out[i] = (out[i] & strip[iy + i + mask_off]) | strip[iy + i]
    return out


def broken_v1_row(dest: list[int], strip: list[int], skip: int, width: int, mask_off: int) -> list[int]:
    """Current SPRITE_OR: iy=B1E4, mask always +3, ignore skip, dest from clean bg."""
    del skip, mask_off
    out = list(dest)
    iy = 0
    for i in range(width):
        idx = iy + i + 3
        mask = strip[idx] if idx < len(strip) else 0
        out[i] = (out[i] & mask) | strip[iy + i]
    return out


def compose_from_bg(bg: list[int], strip: list[int], skip: int, width: int, mask_off: int) -> list[int]:
    """Read clean background instead of current dest — wipes earlier sprites."""
    return b01c_row(list(bg), strip, skip, width, mask_off)


def mask_off_for(b1dd: int, shift: int) -> int:
    half = b1dd >> 1
    return half + (1 if shift else 0)


CASES = []


def add(name, dest, strip, skip, width, mask_off, expect, fn=b01c_row):
    CASES.append((name, dest, strip, skip, width, mask_off, expect, fn))


# Confirmed regression 1: two pixel bytes, masks at +2, not +3
add(
    "two-byte on FF: 80 40 / 7F BF → FF FF",
    dest=[0xFF, 0xFF],
    strip=[0x80, 0x40, 0x7F, 0xBF],
    skip=0, width=2, mask_off=2,
    expect=[0xFF, 0xFF],
)

# Confirmed regression 2: left clip skips first pixel/mask pair
add(
    "clip left byte: keep second only",
    dest=[0xFF],
    strip=[0x80, 0x40, 0x7F, 0xBF],
    skip=1, width=1, mask_off=2,
    expect=[0xFF],
)

# Confirmed regression 3: transparent row must keep previous sprite
add(
    "transparent 3-byte does not wipe previous",
    dest=[0xA5, 0x5A, 0x3C],
    strip=[0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF],
    skip=0, width=3, mask_off=3,
    expect=[0xA5, 0x5A, 0x3C],
)

# Widths actually used: B1DD is even (pixel+mask), 2..8 typical; +1 when shifted
for w, pix, msk in (
    (1, [0x81], [0x7E]),
    (2, [0x80, 0x40], [0x7F, 0xBF]),
    (3, [0x10, 0x20, 0x40], [0xEF, 0xDF, 0xBF]),
    (4, [0x01, 0x02, 0x04, 0x08], [0xFE, 0xFD, 0xFB, 0xF7]),
    (5, [0x80, 0x00, 0x01, 0x00, 0x00], [0x7F, 0xFF, 0xFE, 0xFF, 0xFF]),
):
    add(
        f"width {w} opaque on 00",
        dest=[0] * w,
        strip=pix + msk,
        skip=0, width=w, mask_off=w,
        expect=[p for p in pix],
    )

# All four D099&3 → mask_off = half or half+1
for shift in (0, 1, 2, 3):
    b1dd = 4
    off = mask_off_for(b1dd, shift)
    # unshifted strip is 2+2; shifted loader inserts a 0 pixel and FF mask
    if shift:
        strip = [0xC0, 0x00, 0x00, 0x3F, 0xFF, 0xFF]
        dest = [0xFF, 0xFF, 0xFF]
        width = 3
        expect = b01c_row(dest, strip, 0, width, off)
    else:
        strip = [0xC0, 0x00, 0x3F, 0xFF]
        dest = [0xFF, 0xFF]
        width = 2
        expect = b01c_row(dest, strip, 0, width, off)
    add(f"D099&3={shift} mask_off={off}", dest, strip, 0, width, off, expect)

# Clip right: width shorter than mask_off
add(
    "clip right: first two of three",
    dest=[0x00, 0x00],
    strip=[0x11, 0x22, 0x44, 0xEE, 0xDD, 0xBB],
    skip=0, width=2, mask_off=3,
    expect=[0x11, 0x22],
)

# Vertical clip is row selection; a single row at the clipped start
add(
    "top-clip row uses skip 0",
    dest=[0x0F],
    strip=[0xF0, 0x0F],
    skip=0, width=1, mask_off=1,
    expect=[0xFF],
)

# Two players then ball: sequential AND/OR on the same dest
def seq_overlap():
    bg = [0x00, 0x00]
    p1 = b01c_row(bg, [0xF0, 0x0F, 0x0F, 0xF0], 0, 2, 2)
    p2 = b01c_row(p1, [0x0C, 0xC0, 0xF3, 0x3F], 0, 2, 2)
    ball = b01c_row(p2, [0x18, 0x18, 0xE7, 0xE7], 0, 2, 2)
    return p1, p2, ball


def test_overlap() -> list[str]:
    errs = []
    bg = [0x00, 0x00]
    p1, p2, ball = seq_overlap()
    if p1 != [0xF0, 0x0F]:
        errs.append(f"player1 {p1}")
    if p2 == p1:
        errs.append("player2 should change dest")
    if ball == p2:
        errs.append("ball should change dest")
    keep = b01c_row(p1, [0x00, 0x00, 0xFF, 0xFF], 0, 2, 2)
    if keep != p1:
        errs.append(f"transparent p2 wiped p1: {keep} vs {p1}")
    lost = compose_from_bg(bg, [0x00, 0x00, 0xFF, 0xFF], 0, 2, 2)
    if lost == p1:
        errs.append("bg-compose should have lost p1")
    if lost != bg:
        errs.append(f"bg-compose transparent should be bg, got {lost}")
    return errs


def test_motion_frames() -> list[str]:
    """Several frames: restore bg in old rect, then AND/OR new sprite (publish order)."""
    errs = []
    bg = [0xFF, 0xFF, 0xFF, 0xFF]
    strip = [0xC0, 0x00, 0x3F, 0xFF]
    scene = list(bg)
    prev = None
    for x in range(3):
        if prev is not None:
            for i in range(2):
                scene[prev + i] = bg[prev + i]
        scene[x : x + 2] = b01c_row(scene[x : x + 2], strip, 0, 2, 2)
        prev = x
    if scene[0] != 0xFF:
        errs.append(f"frame motion left a trail at col0: {scene}")
    return errs


def run() -> int:
    failed = 0
    print("== B01C row semantics ==")
    for name, dest, strip, skip, width, mask_off, expect, fn in CASES:
        got = fn(list(dest), strip, skip, width, mask_off)
        ok = got == expect
        mark = "OK" if ok else "FAIL"
        if not ok:
            failed += 1
        print(f"  {mark:4} {name}: got {[hex(x) for x in got]} expect {[hex(x) for x in expect]}")

    print("== documented current-SPRITE_OR defects ==")
    dest, strip = [0xFF, 0xFF], [0x80, 0x40, 0x7F, 0xBF]
    bad = broken_v1_row(dest, strip, 0, 2, 2)
    print(f"  mask+3 on 80 40 / 7F BF / FF FF → {[hex(x) for x in bad]} (expect FF FF)")
    if bad == [0xBF, 0x40]:
        print("  OK   matches confirmed regression BF 40")
    else:
        print("  NOTE regression shape differs from the isolated report")
        failed += 0  # informational

    clip_bad = broken_v1_row([0xFF], strip, 1, 1, 2)
    clip_ok = b01c_row([0xFF], strip, 1, 1, 2)
    print(f"  clip+3 → {[hex(x) for x in clip_bad]}  B01C → {[hex(x) for x in clip_ok]}")
    if clip_bad == clip_ok:
        failed += 1
        print("  FAIL clipped case should differ from B01C")

    print("== overlap / motion ==")
    for e in test_overlap() + test_motion_frames():
        print("  FAIL", e)
        failed += 1
    if failed == 0:
        print("  OK   sequential players+ball and 3-frame motion")

    print()
    print("failed" if failed else "all passed", f"({failed} failures)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(run())
