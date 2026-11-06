"""Deterministic randomness for Basket Master: one patch for MSX and the port.

The original mixes three sources: the game RNG (MSX D606, port 386E:
x = x * 105 in 4114), which the frame interrupt also bumps (MSX D4BC, port
3724: inc 4114 every IRQ), and five `ld a,r` reads. Interrupt counts and R
depend on CPU speed, so the MSX, the Z80 port and the i8080 port could not
play the same match. After this patch:

  * `ld a,r` sites call stubs that take the high byte of the next game RNG
    value (7 bits, like R): `push hl / call RNG / ld a,h / pop hl / <op>`;
  * the interrupt bumps 4114 only outside a match (menu, demo), so the seed
    still varies with how long the player stays in the menu, and inside a
    match every random number follows from the seed and the inputs.

Stubs are plain Z80 game code: on the port they live in the game window
(A160.., freed by the native wipe) and the recompiler translates them with
the game (A510 sets IX).
"""
from __future__ import annotations

# (Z80 address = MSX address, original bytes, stub kind). The bytes after
# ED 5F are the instruction that consumed A; the stub performs it.
SITES = (
    (0x86D0, "ed5ffe64", "cp64"),
    (0x876D, "ed5fe610", "and10"),
    (0x8797, "ed5fe60f", "and0f"),
    (0x8B84, "ed5fe60f", "and0f"),
    (0xA510, "ed5fdd210300", "ix3"),
)
ISR_BUMP = "2a144123221441"          # ld hl,(4114) / inc hl / ld (4114),hl
TAILS = {"cp64": "fe64", "and10": "e610", "and0f": "e60f", "ix3": "dd210300"}


def stubs(base: int, rng: int, match_flag: int) -> tuple[bytes, dict[str, int]]:
    out = bytearray()
    addr = {}
    for kind in ("cp64", "and10", "and0f", "ix3"):
        addr[kind] = base + len(out)
        out += bytes((0xE5, 0xCD, rng & 0xFF, rng >> 8, 0x7C, 0xE1))  # push hl/call/ld a,h/pop hl
        out += bytes.fromhex(TAILS[kind]) + b"\xC9"
    addr["seed"] = base + len(out)
    out += bytes((0x3A, match_flag & 0xFF, match_flag >> 8, 0x3D, 0xC8))  # ld a,(flag)/dec a/ret z
    out += bytes.fromhex(ISR_BUMP) + b"\xC9"
    return bytes(out), addr


def patches(base: int, rng: int, match_flag: int, isr: int) -> list[tuple[int, bytes, bytes]]:
    """[(address, original bytes, new bytes)]; the stub block is first."""
    code, addr = stubs(base, rng, match_flag)
    out = [(base, None, code)]
    for site, orig, kind in SITES:
        old = bytes.fromhex(orig)
        new = bytes((0xCD, addr[kind] & 0xFF, addr[kind] >> 8))
        out.append((site, old, new + bytes(len(old) - 3)))
    old = bytes.fromhex(ISR_BUMP)
    new = bytes((0xC3, addr["seed"] & 0xFF, addr["seed"] >> 8))
    out.append((isr, old, new + bytes(len(old) - 3)))
    return out


def apply(mem: bytearray, base: int, rng: int, match_flag: int, isr: int) -> int:
    """Patch a 64 KiB image in place; returns the stub block size."""
    for at, old, new in patches(base, rng, match_flag, isr):
        if old is not None and bytes(mem[at:at + len(old)]) != old:
            raise ValueError(f"rng_patch {at:04X}: {bytes(mem[at:at + len(old)]).hex()}, want {old.hex()}")
        mem[at:at + len(new)] = new
    return len(stubs(base, rng, match_flag)[0])


MSX = dict(base=0x8400, rng=0xD606, match_flag=0xB206, isr=0xD4BC)
PORT = dict(base=0xA160, rng=0x386E, match_flag=0x0FED, isr=0x3724)
