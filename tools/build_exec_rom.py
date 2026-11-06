#!/usr/bin/env python3
"""Build Executive MSX cartridge ROM that mirrors tape BLOAD+,R.

Tape: three BLOADs with auto-start (CALL CF08, CALL CF08, JP 84D0).
A raw overlay blackscreens — stages 1–2 must run.

Cart conflict: game lives at 84D0..DD18 (under page2). Stub switches
PPI (port A8) so page2/page3 stay RAM while page1 reads ASCII16 banks,
copies/calls stages, then unmaps the cart before JP into the game.
"""

from __future__ import annotations

import argparse
import hashlib
import struct
from pathlib import Path

ROM_SIZE = 0x10000  # 4 × 16 KiB ASCII16 banks
BANK = 0x4000
STUB_RAM = 0xF000
DETERMINISTIC = False


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_cas(data: bytes) -> list[tuple[int, int, int, bytes]]:
    sync = bytes.fromhex("1fa6debacc137d74")
    parts: list[int] = []
    i = 0
    while True:
        j = data.find(sync, i)
        if j < 0:
            break
        parts.append(j)
        i = j + len(sync)
    chunks = [
        data[s + len(sync) : (parts[n + 1] if n + 1 < len(parts) else len(data))]
        for n, s in enumerate(parts)
    ]
    bins: list[tuple[int, int, int, bytes]] = []
    i = 0
    while i < len(chunks):
        hdr = chunks[i]
        if len(hdr) >= 10 and len(set(hdr[:10])) == 1 and hdr[0] == 0xD0:
            body = chunks[i + 1]
            load, end, entry = struct.unpack_from("<HHH", body, 0)
            raw = body[6 : 6 + (end - load + 1)]
            if len(raw) != end - load + 1:
                raise ValueError(f"truncated block after hdr@{i}")
            bins.append((load, end, entry, raw))
            i += 2
        else:
            i += 1
    if len(bins) != 3:
        raise ValueError(f"expected 3 binary blocks, found {len(bins)}")
    return bins


def z80_ld_imm16(op: int, val: int) -> bytes:
    return bytes([op, val & 0xFF, val >> 8])


def pack_blocks(blocks: list[tuple[int, int, int, bytes]]) -> tuple[bytearray, list[dict]]:
    rom = bytearray([0xFF] * ROM_SIZE)
    meta = []
    cursor = BANK  # bank0 = header/stub; payloads from bank1
    for load, end, entry, raw in blocks:
        if cursor + len(raw) > ROM_SIZE:
            raise ValueError("payloads do not fit in 64 KiB ROM")
        rom[cursor : cursor + len(raw)] = raw
        meta.append(
            {
                "load": load,
                "end": end,
                "entry": entry,
                "len": len(raw),
                "bank": cursor // BANK,
                "off": cursor % BANK,
            }
        )
        cursor += len(raw)
    return rom, meta


def split_bank_chunks(bank: int, off: int, dest: int, length: int):
    left = length
    cur_bank, cur_off, cur_dest = bank, off, dest
    while left:
        room = BANK - cur_off
        n = min(left, room)
        yield cur_bank, cur_off, cur_dest, n
        left -= n
        cur_dest += n
        cur_off = 0
        cur_bank += 1


def emit_copy(code: bytearray, bank: int, off: int, dest: int, length: int) -> None:
    # ASCII16: LD (6000),bank  → 4000-7FFF
    code += bytes([0x3E, bank & 0xFF, 0x32, 0x00, 0x60])
    code += z80_ld_imm16(0x21, 0x4000 + off)
    code += z80_ld_imm16(0x11, dest)
    code += z80_ld_imm16(0x01, length)
    code += bytes([0xED, 0xB0])


def build_stub(meta: list[dict]) -> bytes:
    code = bytearray()
    code += bytes([0xF3])
    code += z80_ld_imm16(0x31, 0xF380)

    # PPI A8: page0=slot0 (BIOS), page1=slot1 (cart), page2=slot3 (RAM),
    # page3=slot3 (RAM).  bits = 11 11 01 00 = F4h
    # Without this, ASCII16 maps ROM into 8000-BFFF and LDIR into the game
    # image hits ROM (black screen).
    code += bytes([0x3E, 0xF4, 0xD3, 0xA8])

    # HIMEM = 84D0
    code += z80_ld_imm16(0x21, 0x84D0)
    code += bytes([0x22, 0x49, 0xF3])

    # SCREEN 2
    code += bytes([0x3E, 0x02, 0xCD, 0x5F, 0x00])
    # COLOR 1,1,1
    code += bytes(
        [
            0x3E, 0x01,
            0x32, 0xE9, 0xF3,
            0x32, 0xEA, 0xF3,
            0x32, 0xEB, 0xF3,
            0xCD, 0x62, 0x00,
        ]
    )

    for stage in (0, 1):
        m = meta[stage]
        for bank, off, dest, n in split_bank_chunks(
            m["bank"], m["off"], m["load"], m["len"]
        ):
            emit_copy(code, bank, off, dest, n)
        code += bytes([0xCD, m["entry"] & 0xFF, m["entry"] >> 8])

    m = meta[2]
    for bank, off, dest, n in split_bank_chunks(
        m["bank"], m["off"], m["load"], m["len"]
    ):
        emit_copy(code, bank, off, dest, n)

    # Deterministic RNG (tools/rng_patch.py): stubs at 8400 + call sites,
    # written into RAM after the last stage.
    if DETERMINISTIC:
        import sys as _sys
        _sys.path.insert(0, str(Path(__file__).resolve().parent))
        import rng_patch
        for at, _old, new in rng_patch.patches(**rng_patch.MSX):
            code += z80_ld_imm16(0x21, at)
            for b in new:
                code += bytes([0x36, b, 0x23])          # ld (hl),n / inc hl
    # Unmap cart: all pages RAM in slot3 except BIOS page0 slot0 → FCh
    code += bytes([0x3E, 0xFC, 0xD3, 0xA8])
    code += bytes([0xC3, m["entry"] & 0xFF, m["entry"] >> 8])
    return bytes(code)


def build_rom(blocks: list[tuple[int, int, int, bytes]]) -> bytes:
    rom, meta = pack_blocks(blocks)
    stub = build_stub(meta)
    if len(stub) > 0x280:
        raise ValueError(f"stub too large: {len(stub)}")

    stub_off = 0x40
    init_off = 0x10

    init = bytearray()
    init += bytes([0xF3])
    # Ensure page1=cart while copying stub (boot already so); page2/3 RAM
    init += bytes([0x3E, 0xF4, 0xD3, 0xA8])
    init += z80_ld_imm16(0x21, 0x4000 + stub_off)
    init += z80_ld_imm16(0x11, STUB_RAM)
    init += z80_ld_imm16(0x01, len(stub))
    init += bytes([0xED, 0xB0])
    init += bytes([0xC3, STUB_RAM & 0xFF, STUB_RAM >> 8])

    rom[0:2] = b"AB"
    struct.pack_into("<H", rom, 2, 0x4000 + init_off)
    rom[init_off : init_off + len(init)] = init
    rom[stub_off : stub_off + len(stub)] = stub
    return bytes(rom)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "cas",
        type=Path,
        nargs="?",
        default=Path(
            "ref/msx/executive/Fernando Martin Basket Master - "
            "Executive (1987)(Dinamic Software)(ES)[a][RUN'CAS-'].cas"
        ),
    )
    ap.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("ref/msx/executive/executive.rom"),
    )
    ap.add_argument("--deterministic", action="store_true",
                    help="apply tools/rng_patch.py (default output executive-det.rom)")
    args = ap.parse_args()
    global DETERMINISTIC
    DETERMINISTIC = args.deterministic
    if DETERMINISTIC and args.output == Path("ref/msx/executive/executive.rom"):
        args.output = Path("ref/msx/executive/executive-det.rom")

    blocks = parse_cas(args.cas.read_bytes())
    rom = build_rom(blocks)
    out = args.output
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(rom)
    for i, (load, end, entry, raw) in enumerate(blocks):
        (out.parent / f"executive.block{i}.bin").write_bytes(raw)

    print(f"ROM: {out} ({len(rom)} bytes) sha256 {sha256(rom)}")
    for i, (load, end, entry, raw) in enumerate(blocks):
        print(f"  stage {i}: {load:04X}..{end:04X} entry {entry:04X} {len(raw)} b")
    print("  boot: A8=F4 → SCREEN2 → CALL/CALL/unmap → JP 84D0")


if __name__ == "__main__":
    main()
