#!/usr/bin/env python3
"""Render Vector column-major E000/C000 dumps as the CPC four-pen image."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build/v06"
PALETTE = ((0, 0, 0), (255, 255, 255), (0, 0, 255), (255, 128, 95))


def render(low: bytes, high: bytes) -> Image.Image:
    if len(low) != 0x2000 or len(high) != 0x2000:
        raise ValueError("both plane dumps must be exactly 8192 bytes")
    image = Image.new("RGB", (256, 192))
    out = image.load()
    for y in range(192):
        offset = 0xDF - y
        for byte_col in range(32):
            lo = low[byte_col * 256 + offset]
            hi = high[byte_col * 256 + offset]
            for bit in range(8):
                pen = ((lo >> (7 - bit)) & 1) | (((hi >> (7 - bit)) & 1) << 1)
                out[byte_col * 8 + bit, y] = PALETTE[pen]
    return image


def main() -> None:
    low = BUILD / "plane.bin"
    high = BUILD / "plane-hi.bin"
    output = BUILD / "plane-color.png"
    render(low.read_bytes(), high.read_bytes()).resize(
        (768, 576), Image.Resampling.NEAREST
    ).save(output)
    print(output)


if __name__ == "__main__":
    main()
