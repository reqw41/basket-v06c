#!/usr/bin/env python3
"""Release images in rom/ from the built ones, English and Russian.

  python3 tools/make_roms.py     # after the build (README: build_v06_rom, i8080, build_v06_rom)

  rom/basket.c00, basket-0100.rom          i8080 (plain Vector)       English
  rom/basket-z80.c00, basket-z80-0100.rom  Z80 processor board        English
  rom/basket-ru.c00, basket-ru-0100.rom, rom/basket-z80-ru.*          the same in Russian
.rom loads at 0100; .c00 is the 64 KB memory from 0000 (JP 0100 in front),
for the MiSTer core and emulators (.r0m).
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "rom"
BUILT = {"basket": ROOT / "build/i8080/basket-i8080.rom", "basket-z80": ROOT / "build/v06/basket.rom"}


def c00(rom: bytes) -> bytes:
    img = bytearray(0x10000)
    img[0:3] = b"\xc3\x00\x01"
    img[0x100:0x100 + len(rom)] = rom
    return bytes(img)


def main() -> None:
    for name, src in BUILT.items():
        en = OUT / f"{name}-0100.rom"
        en.write_bytes(src.read_bytes())
        ru = OUT / f"{name}-ru-0100.rom"
        subprocess.run([sys.executable, str(ROOT / "tools/make_ru.py"), str(en), str(ru)], check=True)
        for rom in (en, ru):
            (OUT / rom.name.replace("-0100.rom", ".c00")).write_bytes(c00(rom.read_bytes()))
    for f in sorted(OUT.iterdir()):
        print(f"{f.relative_to(ROOT)} {f.stat().st_size}")


if __name__ == "__main__":
    main()
