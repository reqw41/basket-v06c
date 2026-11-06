"""Bake AY tone periods into VI53 divisors.

Music notes are [duration][P_lo][P_hi]. SFX events are 2 bytes
(flags+coarse, fine) and become 3 bytes (flags, D_lo, D_hi) in the
7FBA hole. D = 13P + P/4 + P/8 — same formula as the old IRQ path.
"""
from __future__ import annotations

MUSIC_PTRS = (
    0x7B9D, 0x7BC4, 0x7BEB, 0x7C18, 0x7C24, 0x7C3C, 0x7C54, 0x7C6C,
    0x7C7B, 0x7C93, 0x7CAB, 0x7CB7, 0x7CDE, 0x7D02, 0x7D2F, 0x7D3B,
    0x7D59, 0x7D77, 0x7D86, 0x7DA4, 0x7DC2, 0x7DE9, 0x7E0D, 0x7E3A,
    0x7E46, 0x7E64, 0x7E82,
)
SFX_OLD = (0x7AE8, 0x7B51, 0x7B76, 0x7B94)
SFX_SITES = {
    0x7AE8: (0x8603,),
    0x7B51: (0x8C57, 0x985C),
    0x7B76: (0x8C0D, 0x96B3),
    0x7B94: (0x85F7,),
}
SFX_DEST = 0x7FBA
SFX_DEST_END = 0x84D0


def ay_to_vi53(p: int) -> int:
    if p <= 0:
        return 0
    d = 13 * p + (p >> 2) + (p >> 3)
    return 0 if d < 64 else d


def _put_word(rom: bytearray, addr: int, value: int) -> None:
    rom[addr] = value & 0xFF
    rom[addr + 1] = value >> 8


def convert_music(rom: bytearray) -> int:
    seen: set[int] = set()
    notes = 0
    for start in MUSIC_PTRS:
        p = start
        while p not in seen and p < 0x7F50:
            seen.add(p)
            if rom[p] == 0xFF:
                break
            d = ay_to_vi53(rom[p + 1] | (rom[p + 2] << 8))
            _put_word(rom, p + 1, d)
            notes += 1
            p += 3
            if rom[p] == 0xFF:
                break
    return notes


def convert_sfx(rom: bytearray) -> dict[int, int]:
    dest = SFX_DEST
    remap: dict[int, int] = {}
    for old in SFX_OLD:
        remap[old] = dest
        p = old
        while rom[p] != 0xFF:
            flags = rom[p]
            period = rom[p + 1] | ((flags & 3) << 8)
            d = ay_to_vi53(period)
            rom[dest] = flags & 0xFC
            _put_word(rom, dest + 1, d)
            dest += 3
            p += 2
            if dest + 4 > SFX_DEST_END:
                raise RuntimeError("SFX overflow 7FBA..84CF")
        rom[dest] = 0xFF
        dest += 1
    # Old 2-byte AY streams are unused after the remap.
    rom[SFX_OLD[0]:MUSIC_PTRS[0]] = bytes(MUSIC_PTRS[0] - SFX_OLD[0])
    return remap


def pack_v06_snd(rom: bytearray) -> tuple[int, dict[int, int]]:
    notes = convert_music(rom)
    remap = convert_sfx(rom)
    return notes, remap
