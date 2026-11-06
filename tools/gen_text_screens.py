"""Build CPC-style text menu chrome from the game font.

Plane layout matches Vector hardware: byte at (col, y) lives at
  addr = ((0xE0 + col) << 8) | (0xDF - y)
Colour pens: 0 blue, 1 white, 2 black, 3 pink (low bit / high bit).

Splash art is the CPC loading bitmap (`splash_planes_v06.z`), not text.
Menu chrome matches the CPC sample: filled blue bar, black label well,
title above, copyright below; players stand in the blue side strips.
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

PEN_BLUE = (0, 0)
PEN_WHITE = (1, 0)
PEN_BLACK = (0, 1)
PEN_PINK = (1, 1)

# CPC 256×192 reference (content-scaled): blue y46..146, well y56..136,
# players ≈ y80..108 centered in the bar; copyright y184..190.
PANEL = (8, 46, 247, 146)
WELL = (56, 56, 207, 136)


def plane_offset(col: int, y: int) -> int:
    return (col << 8) | ((0xDF - y) & 0xFF)


def make_planes(fill=PEN_BLACK):
    lo = bytearray(8192)
    hi = bytearray(8192)
    bit_lo, bit_hi = fill
    if bit_lo:
        lo[:] = b"\xff" * 8192
    if bit_hi:
        hi[:] = b"\xff" * 8192
    return lo, hi


def set_pen(lo: bytearray, hi: bytearray, col: int, y: int, mask: int, pen):
    if not mask or y < 0 or y > 255 or col < 0 or col > 31:
        return
    off = plane_offset(col, y)
    bit_lo, bit_hi = pen
    if bit_lo:
        lo[off] |= mask
    else:
        lo[off] &= ~mask & 0xFF
    if bit_hi:
        hi[off] |= mask
    else:
        hi[off] &= ~mask & 0xFF


def hline(lo, hi, y, x0, x1, pen):
    for x in range(x0, x1 + 1):
        set_pen(lo, hi, x >> 3, y, 0x80 >> (x & 7), pen)


def vline(lo, hi, x, y0, y1, pen):
    mask = 0x80 >> (x & 7)
    col = x >> 3
    for y in range(y0, y1 + 1):
        set_pen(lo, hi, col, y, mask, pen)


def rect_frame(lo, hi, x0, y0, x1, y1, pen):
    hline(lo, hi, y0, x0, x1, pen)
    hline(lo, hi, y1, x0, x1, pen)
    vline(lo, hi, x0, y0, y1, pen)
    vline(lo, hi, x1, y0, y1, pen)


def fill_rect(lo, hi, x0, y0, x1, y1, pen):
    for y in range(y0, y1 + 1):
        hline(lo, hi, y, x0, x1, pen)


def glyph_row(font: bytes, ch: int, row: int) -> int:
    return font[ch * 8 + row]


def draw_text(lo, hi, font, text: bytes, x: int, y: int, pen=PEN_WHITE, scale=1):
    for index, ch in enumerate(text):
        base_x = x + index * 8 * scale
        for row in range(8):
            bits = glyph_row(font, ch, row)
            for bit in range(8):
                if not (bits & (0x80 >> bit)):
                    continue
                for dx in range(scale):
                    for dy in range(scale):
                        px = base_x + bit * scale + dx
                        py = y + row * scale + dy
                        set_pen(lo, hi, px >> 3, py, 0x80 >> (px & 7), pen)


def draw_chrome(lo, hi, font, *, splash: bool = False):
    """CPC menu: title, filled blue bar, black well, copyright."""
    del splash
    title = b"FERNANDO MARTIN BASKET MASTER"
    draw_text(lo, hi, font, title, (256 - len(title) * 8) // 2, 8, PEN_WHITE, scale=1)

    px0, py0, px1, py1 = PANEL
    fill_rect(lo, hi, px0, py0, px1, py1, PEN_BLUE)
    wx0, wy0, wx1, wy1 = WELL
    fill_rect(lo, hi, wx0, wy0, wx1, wy1, PEN_BLACK)
    # Copyright and the controls under the panel are drawn at runtime
    # (MENU_DRAW_COPYRIGHT): they overflow the dual-LZ menu slot.


def render_screen(font: bytes, *, splash: bool = False) -> tuple[bytes, bytes]:
    if len(font) < 0x80 * 8:
        raise ValueError("font too short")
    lo, hi = make_planes(PEN_BLACK)
    draw_chrome(lo, hi, font, splash=splash)
    return bytes(lo), bytes(hi)


def font_from_rom(rom: bytes) -> bytes:
    return bytes(rom[0x3B80:0x3B80 + 0x400])


def font_from_overlay() -> bytes:
    overlay = (ROOT / "ref/msx/executive/executive.overlay.bin").read_bytes()
    off = 0xD918 - 0x84D0
    return bytes(overlay[off:off + 0x400])


def pack_menu_planes(font: bytes | None = None) -> tuple[bytes, bytes]:
    """Return LZ-packed menu_lo/hi."""
    from pack_cpc_court import pack_menu

    if font is None:
        font = font_from_overlay()
    menu_lo, menu_hi = render_screen(font, splash=False)
    return pack_menu(menu_lo), pack_menu(menu_hi)
