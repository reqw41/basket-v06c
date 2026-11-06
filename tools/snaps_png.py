#!/usr/bin/env python3
"""Convert build/v06/snap_*.bin plane dumps into one contact sheet PNG."""
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build/v06"


def plane_image(data: bytes) -> Image.Image:
    img = Image.new("1", (256, 192), 0)
    px = img.load()
    for col in range(32):
        for y in range(192):
            v = data[col * 256 + (0xDF - y)]
            for bit in range(8):
                if v & (0x80 >> bit):
                    px[col * 8 + bit, y] = 1
    return img


def main() -> None:
    snaps = sorted(OUT.glob("snap_*.bin"), key=lambda p: int(re.findall(r"\d+", p.name)[0]))
    if not snaps:
        sys.exit("no snaps")
    cols = min(3, len(snaps))
    rows = (len(snaps) + cols - 1) // cols
    sheet = Image.new("L", (cols * 264, rows * 212), 128)
    draw = ImageDraw.Draw(sheet)
    for i, p in enumerate(snaps):
        x, y = (i % cols) * 264 + 4, (i // cols) * 212 + 16
        sheet.paste(plane_image(p.read_bytes()).convert("L"), (x, y))
        draw.text((x, y - 13), p.stem, fill=255)
    out = OUT / "snaps.png"
    sheet.save(out)
    print(out)


if __name__ == "__main__":
    main()
