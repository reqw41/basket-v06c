#!/usr/bin/env python3
"""Extract Basket Master CPC Mode 1 sprites from a live 64K RAM dump.

The match overlay keeps a contiguous sprite bank at 32C8..66F3 and a
relative-offset table at 66F4.  Each record is:

    db height, width_in_cpc_bytes
    db height * width_in_cpc_bytes Mode-1 bytes

A CPC Mode-1 byte holds four 2-bit pixels.  Pen zero is transparent in the
game's blitter.  The optional Vector output stores two pre-split 1-bit planes
and derives the transparency mask at draw time as ~(plane0 | plane1).
"""
from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


CPC_BASE = 0x32C8
CPC_TABLE = 0x66F4
CPC_BANK_SIZE = CPC_TABLE - CPC_BASE
PALETTE = (
    # Live match table at 73B1: border=14, inks=15,14,0B,07.
    # Ink 0 is the transparent bright-blue paper used by the sprite blitter.
    (0x00, 0x00, 0xFF, 0x00),
    (0x00, 0x00, 0x00, 0xFF),
    (0xFF, 0xFF, 0xFF, 0xFF),
    (0xFF, 0x60, 0x60, 0xFF),
)

V06_BASE = 0x415A
V06_TABLE = 0x7760


@dataclass(frozen=True)
class Sprite:
    index: int
    offset: int
    height: int
    width_bytes: int
    payload: bytes

    @property
    def width(self) -> int:
        return self.width_bytes * 4


def u16(data: bytes, pos: int) -> int:
    return data[pos] | data[pos + 1] << 8


def decode_byte(value: int) -> tuple[int, int, int, int]:
    return tuple(
        ((value >> (7 - pixel)) & 1) | (((value >> (3 - pixel)) & 1) << 1)
        for pixel in range(4)
    )


def parse_cpc(ram: bytes) -> list[Sprite]:
    if len(ram) != 0x10000:
        raise ValueError(f"RAM dump must be exactly 65536 bytes, got {len(ram)}")
    sprites: list[Sprite] = []
    expected = 0
    while expected < CPC_BANK_SIZE:
        index = len(sprites)
        table_pos = CPC_TABLE + index * 2
        offset = u16(ram, table_pos)
        if offset != expected:
            raise ValueError(
                f"sprite {index}: pointer {offset:04X}, expected contiguous {expected:04X}"
            )
        pos = CPC_BASE + offset
        height, width_bytes = ram[pos], ram[pos + 1]
        if not height or not width_bytes:
            raise ValueError(f"sprite {index}: invalid {width_bytes * 4}x{height}")
        size = height * width_bytes
        end = offset + 2 + size
        if end > CPC_BANK_SIZE:
            raise ValueError(f"sprite {index}: record crosses pointer table")
        sprites.append(Sprite(index, offset, height, width_bytes, ram[pos + 2:pos + 2 + size]))
        expected = end
    if expected != CPC_BANK_SIZE:
        raise ValueError(f"sprite records end at {expected:04X}, expected {CPC_BANK_SIZE:04X}")
    return sprites


def pixels(sprite: Sprite) -> list[list[int]]:
    rows: list[list[int]] = []
    for y in range(sprite.height):
        row: list[int] = []
        start = y * sprite.width_bytes
        for value in sprite.payload[start:start + sprite.width_bytes]:
            row.extend(decode_byte(value))
        rows.append(row)
    return rows


def render(sprite: Sprite) -> Image.Image:
    image = Image.new("RGBA", (sprite.width, sprite.height), (0, 0, 0, 0))
    out = image.load()
    for y, row in enumerate(pixels(sprite)):
        for x, pen in enumerate(row):
            out[x, y] = PALETTE[pen]
    return image


def split_planes(sprite: Sprite) -> bytes:
    """Return height,width_px then row-interleaved plane0 and plane1 bytes."""
    stride = (sprite.width + 7) // 8
    out = bytearray((sprite.height, sprite.width))
    for row in pixels(sprite):
        p0 = bytearray(stride)
        p1 = bytearray(stride)
        for x, pen in enumerate(row):
            bit = 0x80 >> (x & 7)
            if pen & 1:
                p0[x >> 3] |= bit
            if pen & 2:
                p1[x >> 3] |= bit
        out.extend(p0)
        out.extend(p1)
    return bytes(out)


def validate_split(sprite: Sprite, record: bytes) -> None:
    height, width = record[0], record[1]
    if (height, width) != (sprite.height, sprite.width):
        raise ValueError(f"sprite {sprite.index}: split header mismatch")
    stride = (width + 7) // 8
    source = pixels(sprite)
    pos = 2
    for y in range(height):
        p0 = record[pos:pos + stride]
        p1 = record[pos + stride:pos + stride * 2]
        pos += stride * 2
        restored = []
        for x in range(width):
            bit = 0x80 >> (x & 7)
            restored.append(
                (1 if p0[x >> 3] & bit else 0)
                | (2 if p1[x >> 3] & bit else 0)
            )
        if restored != source[y]:
            raise ValueError(f"sprite {sprite.index}: plane round-trip failed on row {y}")
    if pos != len(record):
        raise ValueError(f"sprite {sprite.index}: trailing split-plane data")


def parse_v06_silhouettes(image: bytes) -> list[tuple[int, int, set[tuple[int, int]]]]:
    memory = bytes(0x100) + image
    result = []
    expected = 0
    while V06_BASE + expected < V06_TABLE:
        index = len(result)
        if V06_TABLE + index * 2 + 1 >= len(memory):
            break
        offset = u16(memory, V06_TABLE + index * 2)
        if offset != expected:
            break
        pos = V06_BASE + offset
        height, stored_width = memory[pos], memory[pos + 1]
        if not height or not stored_width or stored_width & 1:
            break
        half = stored_width // 2
        raw = memory[pos + 2:pos + 2 + height * stored_width]
        occupied: set[tuple[int, int]] = set()
        for y in range(height):
            masks = raw[y * stored_width + half:(y + 1) * stored_width]
            for xb, value in enumerate(masks):
                for bit_index in range(8):
                    if not value & (0x80 >> bit_index):
                        occupied.add((xb * 8 + bit_index, y))
        result.append((half * 8, height, occupied))
        expected += 2 + height * stored_width
    return result


def make_sheet(images: list[Image.Image], path: Path) -> None:
    columns, cell_width, cell_height, scale = 8, 120, 100, 2
    rows = (len(images) + columns - 1) // columns
    sheet = Image.new("RGBA", (columns * cell_width, rows * cell_height), (32, 32, 32, 255))
    draw = ImageDraw.Draw(sheet)
    for index, sprite in enumerate(images):
        left = index % columns * cell_width
        top = index // columns * cell_height
        draw.text((left + 3, top + 3), f"{index:02} {sprite.width}x{sprite.height}", fill="white")
        enlarged = sprite.resize((sprite.width * scale, sprite.height * scale), Image.Resampling.NEAREST)
        sheet.alpha_composite(
            enlarged,
            (left + (cell_width - enlarged.width) // 2, top + 20),
        )
    sheet.save(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("ram", type=Path, help="64K CPC RAM dump captured during a match")
    parser.add_argument("--out", type=Path, default=Path("build/cpc/sprites"))
    parser.add_argument("--v06-rom", type=Path, help="optional current basket.rom for geometry comparison")
    args = parser.parse_args()

    ram = args.ram.read_bytes()
    sprites = parse_cpc(ram)
    args.out.mkdir(parents=True, exist_ok=True)

    rendered = []
    vector_records = bytearray()
    vector_offsets = []
    manifest_sprites = []
    v06 = parse_v06_silhouettes(args.v06_rom.read_bytes()) if args.v06_rom else []

    for sprite in sprites:
        image = render(sprite)
        rendered.append(image)
        image.save(args.out / f"sprite_{sprite.index:02d}_{sprite.width}x{sprite.height}.png")
        vector_offsets.append(len(vector_records))
        vector_record = split_planes(sprite)
        validate_split(sprite, vector_record)
        vector_records.extend(vector_record)

        item = {
            "index": sprite.index,
            "cpc_offset": sprite.offset,
            "width": sprite.width,
            "height": sprite.height,
            "mode1_bytes": len(sprite.payload),
            "vector_stride": (sprite.width + 7) // 8,
        }
        if sprite.index < len(v06):
            old_width, old_height, old_shape = v06[sprite.index]
            new_shape = {
                (x, y)
                for y, row in enumerate(pixels(sprite))
                for x, pen in enumerate(row)
                if pen
            }
            union = new_shape | old_shape
            item.update({
                "v06_width": old_width,
                "v06_height": old_height,
                "same_geometry": (sprite.width, sprite.height) == (old_width, old_height),
                "silhouette_iou": round(len(new_shape & old_shape) / len(union), 4) if union else 1.0,
            })
        manifest_sprites.append(item)

    pointer_table = b"".join(offset.to_bytes(2, "little") for offset in vector_offsets)
    vector_blob = bytes(vector_records) + pointer_table
    source_blob = ram[CPC_BASE:CPC_TABLE + len(sprites) * 2]
    (args.out / "cpc_sprites_mode1.bin").write_bytes(source_blob)
    (args.out / "cpc_sprites_v06_2plane.bin").write_bytes(vector_blob)
    make_sheet(rendered, args.out / "sprites-sheet.png")

    report = {
        "ram_sha256": hashlib.sha256(ram).hexdigest(),
        "source": {
            "base": CPC_BASE,
            "pointer_table": CPC_TABLE,
            "count": len(sprites),
            "records_bytes": CPC_BANK_SIZE,
            "pointer_bytes": len(sprites) * 2,
            "total_bytes": len(source_blob),
            "sha256": hashlib.sha256(source_blob).hexdigest(),
        },
        "vector_2plane": {
            "layout": "height,width_px; for each row: plane0[stride], plane1[stride]; relative pointer table at end",
            "mask": "derive as ~(plane0 | plane1)",
            "records_bytes": len(vector_records),
            "pointer_bytes": len(pointer_table),
            "total_bytes": len(vector_blob),
            "sha256": hashlib.sha256(vector_blob).hexdigest(),
        },
        "sprites": manifest_sprites,
    }
    (args.out / "manifest.json").write_text(json.dumps(report, indent=2) + "\n")
    print(f"sprites={len(sprites)} CPC={len(source_blob)} bytes Vector2={len(vector_blob)} bytes")
    print(args.out / "sprites-sheet.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
