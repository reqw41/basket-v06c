"""Place extracted CPC colours on the original MSX sprite canvases.

The two ports share body/head animation indices but not their cropped origins.
Preserve every nontransparent pixel and its pen; adapt the resource once at
build time, keeping runtime coordinates and the 415A..77F5 budget unchanged.

CPC Mode-1 pen 0 is the blitter's transparent paper. Some extracted frames
(notably the 8×8 ball) store MSX-transparent corners as opaque black ink.
Independent Executive masks punch those pixels back to pen 0 so both video
planes keep the background, while black ink inside the silhouette stays solid.

Masks are applied only to those small ball sprites. The 20×24 hoop frames are
pre-mirrored in the CPC bank on a tighter canvas than the 24-wide MSX masks;
punching them against Executive opacity strips ink. Right-side frames keep CPC
ink and are recentred onto the original 24px MSX canvas (4px left pad).
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MSX_BLOCK1 = ROOT / "ref/msx/executive/executive.block1.bin"
MSX_BASE = 0x415A
MSX_TABLE = 0x7760
UNTRIMMED = {72, 73}  # HUD_ICON (hud_icon.asm) reads these 8x8 records whole


def load_msx_opaque_masks(count: int) -> list[list[list[bool]]]:
    """Per-sprite [y][x] opacity from the original MSX mask plane.

    Record layout matches Executive / parse_v06_silhouettes: height,
    even stored_width; each row is bitmap[half] then mask[half], where a
    clear mask bit means the pixel is opaque.
    """
    block = MSX_BLOCK1.read_bytes()
    mem = bytearray(0x10000)
    mem[MSX_BASE:MSX_BASE + len(block)] = block
    masks: list[list[list[bool]]] = []
    for index in range(count):
        offset = int.from_bytes(mem[MSX_TABLE + index * 2:MSX_TABLE + index * 2 + 2], "little")
        pos = MSX_BASE + offset
        height, stored_width = mem[pos], mem[pos + 1]
        if not height or not stored_width or stored_width & 1:
            raise ValueError(f"MSX sprite {index}: bad header {stored_width}x{height}")
        half = stored_width // 2
        width_px = half * 8
        opaque = [[False] * width_px for _ in range(height)]
        raw = mem[pos + 2:pos + 2 + height * stored_width]
        for y in range(height):
            mask_bytes = raw[y * stored_width + half:(y + 1) * stored_width]
            for xb, value in enumerate(mask_bytes):
                for bit_index in range(8):
                    if not value & (0x80 >> bit_index):
                        opaque[y][xb * 8 + bit_index] = True
        masks.append(opaque)
    return masks


def prepare_bank(raw: bytes) -> bytes:
    layout = json.loads((ROOT / "cfg/cpc_sprite_layout.json").read_text())
    count = layout["source_records"]
    table = len(raw) - count * 2
    msx_masks = load_msx_opaque_masks(layout["runtime_records"])
    canvas_widths = {int(k): int(v) for k, v in layout.get("canvas_widths", {}).items()}
    records = bytearray()
    offsets = []
    for index in range(layout["runtime_records"]):
        source = int.from_bytes(raw[table + index * 2:table + index * 2 + 2], "little")
        h, w = raw[source:source + 2]
        stride = (w + 7) // 8
        width = layout["head_canvas_width"] if index in layout["head_indices"] else w
        if index in canvas_widths:
            width = canvas_widths[index]
        out_stride = (width + 7) // 8
        dx = layout["x_offsets_pixels"].get(str(index), 0)
        opaque = msx_masks[index]
        if len(opaque) != h:
            raise ValueError(f"sprite {index}: CPC height {h} != MSX height {len(opaque)}")
        # Ball-only: false opaque corners. Hoop/player frames keep CPC ink.
        punch_msx_gap = h <= 8 and w <= 8
        rows = []
        for row in range(h):
            start = source + 2 + row * stride * 2
            planes = [bytearray(out_stride), bytearray(out_stride)]
            for x in range(w):
                bit = 0x80 >> (x & 7)
                pen = (bool(raw[start + x // 8] & bit)
                       + 2 * bool(raw[start + stride + x // 8] & bit))
                if not pen:
                    continue
                target = x + dx
                if not 0 <= target < width:
                    raise ValueError(f"sprite {index}: anchor would crop opaque pixel {x},{row}")
                if punch_msx_gap and (
                    target >= len(opaque[row]) or not opaque[row][target]
                ):
                    # MSX-transparent: drop CPC black ink that should be paper.
                    continue
                for plane in range(2):
                    if pen & (1 << plane):
                        planes[plane][target // 8] |= 0x80 >> (target & 7)
            rows.append(bytes(planes[0]) + bytes(planes[1]))
        # Runtime record: canvas height, width, top, kept rows, then only the
        # rows from the first to the last non-empty one (COLOR_SPRITE feeds
        # a zero row outside them, so rectangles keep the canvas height).
        # The HUD icon sprites stay whole: HUD_ICON copies all 8 rows.
        top, keep = 0, h
        if index not in UNTRIMMED:
            while top < h and not any(rows[top]):
                top += 1
            keep = h - top
            while keep and not any(rows[top + keep - 1]):
                keep -= 1
            if not keep:
                top = 0
        offsets.append(len(records))
        records.extend((h, width, top, keep))
        for row in rows[top:top + keep]:
            records.extend(row)
    for offset in offsets:
        records.extend(offset.to_bytes(2, "little"))
    return bytes(records)
