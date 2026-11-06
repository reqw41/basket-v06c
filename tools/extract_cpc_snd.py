#!/usr/bin/env python3
"""Extract Basket Master CPC AY music + SFX from the CDT tape.

Dinamic shipped the same AY streams as the MSX Executive build: four
2-byte SFX phrases and the [duration][P_lo][P_hi] music bundle.  On CPC
they sit at runtime 2904..2D6F (music base 29B9); V06 keeps the MSX map
at 7AE8..7FB9.

The commercial CDT truncates the final music order-table rows with font
bytes.  After relocating pointers to 7B9D those 35 trailing bytes are
restored from the known MSX image (identical notes/tables up to that
point).

Usage:
  python3 tools/extract_cpc_snd.py
  python3 tools/extract_cpc_snd.py -o src/assets/cpc_snd_ay.bin
"""
from __future__ import annotations

import argparse
import hashlib
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CDT = ROOT / "ref/cpc/Fernando Martin Basket Master.cdt"
DEFAULT_OUT = ROOT / "src/assets/cpc_snd_ay.bin"

MUSIC_SIG = bytes.fromhex("06000006380206fa0106c3010caa01")
V06_SFX = 0x7AE8
V06_MUSIC = 0x7B9D
V06_MUSIC_END = 0x7FBA  # exclusive
SFX_SIZE = V06_MUSIC - V06_SFX  # 0xB5
MUSIC_SIZE = V06_MUSIC_END - V06_MUSIC  # 0x41D

# Relocated MSX tail that the CPC tape overwrote with font data.
MUSIC_TAIL_FIX_OFF = 0x3FA
MUSIC_TAIL_FIX = bytes.fromhex(
    "537ff77b0000e97d537ff77b0000e97d537ff77b0000e97d537ff77b0000c27d537fff"
)


def parse_cdt_turbo_payloads(cdt: bytes) -> list[bytes]:
    if cdt[:8] != b"ZXTape!\x1a":
        raise ValueError("not a ZXTape/CDT image")
    pos = 10
    payloads: list[bytes] = []
    while pos < len(cdt):
        bid = cdt[pos]
        pos += 1
        if bid == 0x11:
            hdr = cdt[pos : pos + 18]
            pos += 18
            length = int.from_bytes(hdr[15:18], "little")
            payloads.append(cdt[pos : pos + length])
            pos += length
        elif bid == 0x10:
            _pause, length = struct.unpack_from("<HH", cdt, pos)
            pos += 4
            payloads.append(cdt[pos : pos + length])
            pos += length
        elif bid == 0x20:
            pos += 2
        elif bid == 0x30:
            pos += 1 + cdt[pos]
        elif bid == 0x31:
            pos += 2 + cdt[pos + 1]
        elif bid == 0x33:
            pos += 1 + 3 * cdt[pos]
        else:
            break
    return payloads


def find_sound_blob(cdt: bytes) -> tuple[bytes, bytes, int]:
    """Return (sfx, music_raw, cpc_music_base)."""
    for payload in parse_cdt_turbo_payloads(cdt):
        off = payload.find(MUSIC_SIG)
        if off < 0:
            continue
        if off < SFX_SIZE:
            raise ValueError("music signature too early for SFX prefix")
        sfx = bytes(payload[off - SFX_SIZE : off])
        music = bytearray(payload[off : off + MUSIC_SIZE])
        if len(music) != MUSIC_SIZE:
            raise ValueError(f"music truncated: {len(music)} bytes")
        if sfx[-1] != 0xFF:
            raise ValueError("SFX region does not end with 0xFF before music")
        # First order-table word after the note streams.
        cpc_base = music[0x312] | music[0x313] << 8
        if music[0:3] != MUSIC_SIG[:3]:
            raise ValueError("music head mismatch")
        return sfx, bytes(music), cpc_base
    raise ValueError("CPC music signature not found in CDT")


def relocate_music(music: bytes, cpc_base: int) -> bytes:
    delta = V06_MUSIC - cpc_base
    out = bytearray(music)
    hi = cpc_base + MUSIC_SIZE + 0x20
    i = 0
    while i < len(out) - 1:
        word = out[i] | out[i + 1] << 8
        if cpc_base <= word < hi:
            word += delta
            out[i] = word & 0xFF
            out[i + 1] = word >> 8
            i += 2
        else:
            i += 1
    if out[MUSIC_TAIL_FIX_OFF : MUSIC_TAIL_FIX_OFF + len(MUSIC_TAIL_FIX)] != MUSIC_TAIL_FIX:
        out[MUSIC_TAIL_FIX_OFF : MUSIC_TAIL_FIX_OFF + len(MUSIC_TAIL_FIX)] = MUSIC_TAIL_FIX
    return bytes(out)


def extract(cdt_path: Path) -> bytes:
    sfx, music_raw, cpc_base = find_sound_blob(cdt_path.read_bytes())
    music = relocate_music(music_raw, cpc_base)
    blob = sfx + music
    if len(blob) != SFX_SIZE + MUSIC_SIZE:
        raise RuntimeError("unexpected sound blob size")
    return blob


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("-i", "--input", type=Path, default=DEFAULT_CDT)
    ap.add_argument("-o", "--output", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--check", action="store_true", help="verify only, do not write")
    args = ap.parse_args(argv)

    if not args.input.is_file():
        print(f"missing CDT: {args.input}", file=sys.stderr)
        return 1

    blob = extract(args.input)
    digest = hashlib.sha256(blob).hexdigest()
    print(
        f"CPC sound {len(blob)} bytes "
        f"(SFX {SFX_SIZE} @ {V06_SFX:04X}, music {MUSIC_SIZE} @ {V06_MUSIC:04X})"
    )
    print(f"SHA-256 {digest}")

    if args.check:
        if not args.output.is_file():
            print(f"missing asset: {args.output}", file=sys.stderr)
            return 1
        if args.output.read_bytes() != blob:
            print("asset differs from CDT extract", file=sys.stderr)
            return 1
        print(f"OK {args.output}")
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(blob)
    print(f"wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
