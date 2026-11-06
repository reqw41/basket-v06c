#!/usr/bin/env python3
"""Repack Basket Master bitmaps into Vector-06C plane layout.

Vector plane byte (col, y) sits at (E0+col)<<8 | (DF-y). A 32×112 court
column is 112 bytes that LDIR onto E0+col, row 68..D7 (y=119..8).

Court source: 2500, 0xE00 bytes, row-major 32 bytes/row × 112 rows.
Sprites (415A..): word width,height then interleaved mask/bitmap strips
drawn by B01C as 4-byte strips; SPRITE_OR writes them to the plane.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COURT = 0x2500
COURT_W, COURT_H = 32, 112  # bytes × rows (playfield tile rows 1..14)


def pack_court_columns(rom: bytes, court: int = COURT) -> bytes:
    src = rom[court:court + COURT_W * COURT_H]
    out = bytearray(COURT_W * COURT_H)
    for col in range(COURT_W):
        for y in range(COURT_H):
            # store bottom-first so LDIR lands on plane row 0x68 = y=119
            out[col * COURT_H + y] = src[(COURT_H - 1 - y) * COURT_W + col]
    return bytes(out)


def main() -> None:
    rom = bytearray(0x10000)
    img = (ROOT / "build/v06/basket.rom").read_bytes()
    rom[0x100:0x100 + len(img)] = img
    packed = pack_court_columns(rom)
    out = ROOT / "build/v06/court_v06.bin"
    out.write_bytes(packed)
    print(f"{out} {len(packed)} bytes (32 columns × {COURT_H})")


if __name__ == "__main__":
    main()
