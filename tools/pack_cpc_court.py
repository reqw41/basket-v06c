"""Lossless CPC static court tiles and compact menu LZ.

CPC static bank 8B68..A567 maps to game rows 16..119. Keep existing hoop
art for rows 8..15. Tile records interleave Vector low/high bytes per row.

At pack time the three AMSTRAD boards are rewritten as VECTOR from the game
font (blue fill, white outline) and the whole court is re-deduplicated.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

PEN_BLUE = 0
PEN_WHITE = 1
PEN_BLACK = 2
PEN_PINK = 3


def unpack_rle(data):
    out = bytearray(); i = 0
    while i < len(data) and data[i]:
        token = data[i]; i += 1
        if token & 128:
            out.extend([data[i]] * (token & 127)); i += 1
        else:
            out.extend(data[i:i + token]); i += token
    return bytes(out)


def pack_menu(data):
    # Flag bit 1: literal. Bit 0: 12-bit backward distance, length nibble.
    # Length 3..17; nibble F adds one byte for length 18..273.
    out = bytearray(); pos = 0
    while pos < len(data):
        flag = len(out); out.append(0)
        for bit in range(8):
            if pos == len(data):
                break
            best = distance = 0
            for start in range(max(0, pos - 4095), pos):
                if data[start] != data[pos]:
                    continue
                n = 1
                while n < 273 and pos + n < len(data) and data[start + n] == data[pos + n]:
                    n += 1
                if n > best:
                    best, distance = n, pos - start
            if best >= 3:
                out.extend((distance & 255, (distance >> 8) * 16 + min(best - 3, 15)))
                if best >= 18:
                    out.append(best - 18)
                pos += best
            else:
                out[flag] |= 1 << bit
                out.append(data[pos])
                pos += 1
    return bytes(out)


def _font_bytes() -> bytes:
    overlay = (ROOT / "ref/msx/executive/executive.overlay.bin").read_bytes()
    off = 0xD918 - 0x84D0
    return bytes(overlay[off:off + 0x400])


def _glyph_row(font: bytes, ch: int, row: int) -> int:
    return font[ch * 8 + row]


def _court_pens():
    cpc = (ROOT / "src/assets/cpc_court_mode1.bin").read_bytes()
    old = (ROOT / "src/assets/court_bg_v06.bin").read_bytes()
    assert len(cpc) == 104 * 64 and len(old) == 112 * 32
    pens = [[PEN_BLACK] * 256 for _ in range(112)]
    for y in range(112):
        for col in range(32):
            for x in range(8):
                bit = 0x80 >> x
                if y < 8:
                    lo = old[y * 32 + col]
                    hi = lo ^ 255
                    pens[y][col * 8 + x] = ((1 if hi & bit else 0) << 1) | (1 if lo & bit else 0)
                else:
                    px = col * 8 + x
                    value = cpc[(y - 8) * 64 + px // 4]
                    q = px % 4
                    pens[y][col * 8 + x] = [0, 2, 1, 3][
                        ((value >> (7 - q)) & 1) | (((value >> (3 - q)) & 1) << 1)
                    ]
    return pens


def _apply_vector_banners(pens) -> None:
    """Replace the three AMSTRAD boards (tile cols 4..11 / 12..19 / 20..27)."""
    font = _font_bytes()
    word = b"VECTOR"
    scale = 1
    tw = len(word) * 8 * scale
    th = 8 * scale
    for tx0 in (4, 12, 20):
        x_left, x_right = tx0 * 8, (tx0 + 8) * 8
        # Wipe AMSTRAD lettering AND the old checker foot (row 54). Keep the
        # side frame (x_left/x_right-1) and the court-wide white bar at y56.
        for y in range(41, 55):
            for x in range(x_left + 1, x_right - 1):
                pens[y][x] = PEN_BLACK
        x0 = x_left + (64 - tw) // 2
        y0 = 45
        ink = [[0] * tw for _ in range(th)]
        for i, ch in enumerate(word):
            for row in range(8):
                bits = _glyph_row(font, ch, row)
                for bit in range(8):
                    if not (bits & (0x80 >> bit)):
                        continue
                    for dx in range(scale):
                        for dy in range(scale):
                            ink[row * scale + dy][i * 8 * scale + bit * scale + dx] = 1
        lowest = max((y for y in range(th) if any(ink[y])), default=-1)
        # 1px white halo. Below the glyph box (y == lowest+1) only paint cells
        # directly under ink — full bottom outline without inter-letter dashes.
        for y in range(-1, lowest + 2):
            for x in range(-1, tw + 1):
                if 0 <= y < th and 0 <= x < tw and ink[y][x]:
                    continue
                halo = False
                if y == lowest + 1:
                    if 0 <= x < tw and ink[lowest][x]:
                        halo = True
                else:
                    for ny in (y - 1, y, y + 1):
                        for nx in (x - 1, x, x + 1):
                            if 0 <= ny < th and 0 <= nx < tw and ink[ny][nx]:
                                halo = True
                                break
                        if halo:
                            break
                if not halo:
                    continue
                py, px = y0 + y, x0 + x
                if 41 <= py < 55 and x_left < px < x_right - 1:
                    pens[py][px] = PEN_WHITE
        for y in range(th):
            for x in range(tw):
                if ink[y][x]:
                    pens[y0 + y][x0 + x] = PEN_BLUE
        # Guarantee the old AMSTRAD foot stays gone even if halo reached y54.
        for x in range(x_left + 1, x_right - 1):
            pens[54][x] = PEN_BLACK


def _pens_to_pair_rows(pens):
    rows = []
    for y in range(112):
        row = bytearray()
        for col in range(32):
            lo = hi = 0
            for x in range(8):
                pen = pens[y][col * 8 + x]
                if pen & 1:
                    lo |= 128 >> x
                if pen & 2:
                    hi |= 128 >> x
            row.extend((lo, hi))
        rows.append(row)
    return rows


def pack_court():
    pens = _court_pens()
    _apply_vector_banners(pens)
    rows = _pens_to_pair_rows(pens)
    tiles = []
    indices = bytearray()
    for y in range(14):
        for col in range(32):
            tile = bytes(
                v for dy in range(8) for v in rows[y * 8 + dy][col * 2:col * 2 + 2]
            )
            if tile not in tiles:
                tiles.append(tile)
            indices.append(tiles.index(tile))
    assert len(tiles) <= 256
    return bytes(indices) + b"".join(tiles)


def _pairs(pens):
    out = bytearray()
    for y in range(112):
        for col in range(32):
            lo = hi = 0
            for x in range(8):
                pen = pens[y][col * 8 + x]
                if pen & 1:
                    lo |= 128 >> x
                if pen & 2:
                    hi |= 128 >> x
            out.extend((lo, hi))
    return bytes(out)


def expected_court_pairs():
    """112×32 interleaved (low, high) pairs after VECTOR rewrite — test etalon."""
    pens = _court_pens()
    _apply_vector_banners(pens)
    return _pairs(pens)


def expected_stamped_court_pairs():
    """Same with the CPC standing-fans stamp (rows 10..38, bytes 0Bh and 20h)."""
    pens = _court_pens()
    _apply_vector_banners(pens)
    stamp = (ROOT / "src/assets/cpc_stand_stamp_mode1.bin").read_bytes()
    for off in (0x0B, 0x20):
        for r in range(len(stamp) // 21):
            for b in range(21):
                v = stamp[r * 21 + b]
                for q in range(4):
                    pens[r + 10][(off + b) * 4 + q] = [0, 2, 1, 3][
                        ((v >> (7 - q)) & 1) | (((v >> (3 - q)) & 1) << 1)
                    ]
    return _pairs(pens)
