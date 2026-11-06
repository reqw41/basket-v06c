"""Store mirrored CPC sprite frames as references (runtime sprite bank).

Input: the trimmed bank of prepare_cpc_sprite_bank.prepare_bank (records
`h, width, top, keep, kept rows` then the 2-byte offset table from 415A).
Facing-left player frames 12..23 and the right hoops 67..71 are exact
horizontal mirrors of 0..11 and 62..66: same stride 3, top and kept rows,
every stored row bit-reversed plane by plane. They become 6-byte records

    h, width, top | 0x80, keep, dw rows

where `rows` is the absolute address of the source sprite's stored rows.
COLOR_SPRITE (CS_HEADER, MIR_ROW in src/v06/softvdp.asm) reverses each row
through the 256-byte MIR_REV table. Only stride-3 frames can be references:
MIR_ROW is unrolled for three bytes per plane.
"""
from __future__ import annotations

REV = bytes(int(f"{x:08b}"[::-1], 2) for x in range(256))
BASE = 0x415A
MIRROR_FLAG = 0x80


def split(bank: bytes, count: int):
    table = bank[-2 * count:]
    recs = bank[:-2 * count]
    out = []
    for i in range(count):
        o = int.from_bytes(table[2 * i:2 * i + 2], "little")
        h, w, top, keep = recs[o:o + 4]
        st = (w + 7) // 8
        rows = [recs[o + 4 + k * 2 * st:o + 4 + (k + 1) * 2 * st] for k in range(keep)]
        out.append((h, w, top, keep, st, rows))
    return out


def mirror_row(row: bytes, st: int) -> bytes:
    return (bytes(REV[x] for x in reversed(row[:st]))
            + bytes(REV[x] for x in reversed(row[st:])))


def pack_mirrors(bank: bytes, count: int, keep_whole=frozenset()) -> tuple[bytes, dict[int, int]]:
    """Runtime bank (records + offset table) and {mirror index: source index}."""
    sprites = split(bank, count)
    sources: dict[int, int] = {}
    for c, (h, w, top, keep, st, rows) in enumerate(sprites):
        if st != 3 or not keep or c in keep_whole:
            continue
        mrows = [mirror_row(r, st) for r in rows]
        for a in range(c):
            ha, wa, ta, ka, sa, ra = sprites[a]
            if a not in sources and sa == 3 and ta == top and ka == keep and ra == mrows:
                sources[c] = a
                break
    recs = bytearray()
    offsets = []
    rows_at: dict[int, int] = {}
    for i, (h, w, top, keep, st, rows) in enumerate(sprites):
        offsets.append(len(recs))
        if i in sources:
            recs += bytes((h, w, top | MIRROR_FLAG, keep))
            recs += rows_at[sources[i]].to_bytes(2, "little")
            continue
        recs += bytes((h, w, top, keep))
        rows_at[i] = BASE + len(recs)
        for r in rows:
            recs += r
    for o in offsets:
        recs += o.to_bytes(2, "little")
    return bytes(recs), sources


def read_row(mem, ptr: int, y: int, plane: int, x: int) -> int:
    """Byte x of plane `plane` in canvas row y of the runtime record at ptr."""
    w, top, keep = mem[ptr + 1], mem[ptr + 2], mem[ptr + 3]
    st = (w + 7) // 8
    mirrored = top & MIRROR_FLAG
    top &= 0x7F
    if not top <= y < top + keep:
        return 0
    if mirrored:
        rows = mem[ptr + 4] | mem[ptr + 5] << 8
        return REV[mem[rows + (y - top) * 2 * st + plane * st + st - 1 - x]]
    return mem[ptr + 4 + (y - top) * 2 * st + plane * st + x]
