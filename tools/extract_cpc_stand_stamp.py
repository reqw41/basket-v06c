#!/usr/bin/env python3
"""Extract the CPC standing-fans stamp into src/assets.

CPC 2182 (type-4 score, 1175 bit 0 clear) copies 21x32 mode-1 bytes from
264A into the working court background A568 at byte offsets 0Bh and 20h of
each 64-byte row; A568 row 0 is game row 16 = Vector court row 8. Stamp rows
0, 1 and 31 equal the seated court at both offsets, so only rows 2..30
(court rows 10..38) are stored: 29 x 21 = 609 bytes.

Input: a CPC match RAM image (tools/cpc_capture_match.lua), default
build/cpc/basket-match.ram.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC, W, H = 0x264A, 21, 32
FIRST, LAST = 2, 30
OUT = ROOT / "src/assets/cpc_stand_stamp_mode1.bin"


def main() -> None:
    ram = Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / "build/cpc/basket-match.ram").read_bytes()
    if ram[0x2185:0x2190] != bytes.fromhex("e60ffe04c03a7511cb47c0"):
        raise SystemExit("CPC 2185: stamp gate not found, wrong RAM image")
    if ram[0x219D:0x21A0] != bytes([0x11, SRC & 255, SRC >> 8]):
        raise SystemExit("CPC 219D: stamp source is not 264A")
    stamp = ram[SRC:SRC + W * H]
    bank = ram[0x8B68:0xA568]
    for off in (0x0B, 0x20):
        for row in list(range(FIRST)) + list(range(LAST + 1, H)):
            if bank[row * 64 + off:row * 64 + off + W] != stamp[row * W:row * W + W]:
                raise SystemExit(f"stamp row {row} differs from the seated court")
    OUT.write_bytes(stamp[FIRST * W:(LAST + 1) * W])
    print(OUT, len(stamp[FIRST * W:(LAST + 1) * W]))


if __name__ == "__main__":
    main()
