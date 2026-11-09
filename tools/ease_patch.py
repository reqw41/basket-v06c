"""Easier steals on the lower levels (trial, 09.11): one patch for MSX and the port.

In defence the computer presses fire the very pass its hand touches the ball
(889F: `bit 6,(ix+1) / ld a,10h / jr nz,88C6`; contact = bit 6 of (ix+1),
the same bit the steal at 8E5A takes). A human has to press fire in that
pass, so the computer steals at once and the player hardly ever (CPC and MSX
alike, 09.11). The patch lets the computer fire on contact only with a
chance that depends on the level (93D2): ROOKIE 1/4, AMATEUR 1/2, NBA always
(the original). When it does not fire it stands still for that pass.

The stub is Z80 game code (on the port the recompiler translates it). It
draws from the game RNG (high 7 bits), so the MSX reference
(build_exec_rom --deterministic) gets the same patch and the lockstep stays
exact.
"""
from __future__ import annotations

SITE = 0x889F
SITE_OLD = bytes.fromhex("ddcb01763e10")    # bit 6,(ix+1) / ld a,10h; 88A5 jr nz,88C6 stays
LEVEL = 0x93D2


def stub(base: int, rng: int) -> bytes:
    """Z: no contact (A = 10h as before). NZ: A = 10h fire, or A = 0 stand."""
    code = bytearray()
    code += bytes.fromhex("ddcb0176")            # bit 6,(ix+1)
    code += bytes.fromhex("3e10")                # ld a,10h
    code += bytes.fromhex("c8")                  # ret z: no contact
    code += bytes((0x3A, LEVEL & 0xFF, LEVEL >> 8))   # ld a,(93D2)
    code += bytes.fromhex("e603fe02")            # and 3 / cp 2
    nba = len(code)
    code += bytes.fromhex("3000")                # jr nc,fire (patched below)
    code += bytes.fromhex("e5d5")                # push hl / push de
    code += bytes.fromhex("3c0f0f0f5f")          # inc a / rrca x3 / ld e,a: 20h ROOKIE, 40h AMATEUR
    code += bytes((0xCD, rng & 0xFF, rng >> 8))  # call RNG: HL = x (H = 0..7Fh)
    code += bytes.fromhex("7cbbd1e1")            # ld a,h / cp e / pop de / pop hl
    chance = len(code)
    code += bytes.fromhex("3800")                # jr c,fire (patched below)
    code += bytes.fromhex("f6013e00c9")          # or 1 / ld a,0 / ret: NZ, stand still
    fire = len(code)
    code += bytes.fromhex("3e10b7c9")            # ld a,10h / or a / ret: NZ, fire
    code[nba + 1] = fire - (nba + 2)
    code[chance + 1] = fire - (chance + 2)
    return bytes(code)


def apply(mem: bytearray, base: int, rng: int, offset: int = 0) -> int:
    """Patch an image in place (offset = image index of address 0); returns the stub size."""
    s = stub(base, rng)
    at = SITE - offset
    if bytes(mem[at:at + len(SITE_OLD)]) != SITE_OLD:
        raise ValueError(f"ease_patch {SITE:04X}: {bytes(mem[at:at + 6]).hex()}, want {SITE_OLD.hex()}")
    if any(mem[base - offset:base - offset + len(s)]):
        raise ValueError(f"ease_patch: {base:04X}..{base + len(s) - 1:04X} is not free")
    mem[base - offset:base - offset + len(s)] = s
    mem[at:at + len(SITE_OLD)] = bytes((0xCD, base & 0xFF, base >> 8, 0, 0, 0))
    return len(s)


def patches(base: int, rng: int) -> list[tuple[int, bytes]]:
    """[(address, new bytes)] for loaders that poke RAM (build_exec_rom)."""
    return [(base, stub(base, rng)), (SITE, bytes((0xCD, base & 0xFF, base >> 8, 0, 0, 0)))]


MSX = dict(base=0x8460, rng=0xD606)
PORT = dict(base=0xA133, rng=0x386E)
