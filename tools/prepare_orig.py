#!/usr/bin/env python3
"""Prepare the original MSX payloads the build needs, from the Executive tape.

    python3 tools/prepare_orig.py 'Fernando Martin Basket Master - Executive (1987)(Dinamic Software)(ES)[a][RUN'CAS-'].cas'

Writes ref/msx/executive/: executive.rom (cartridge for openMSX),
executive.block{0,1,2}.bin (the three BLOAD stages) and executive.overlay.bin
(MSX RAM 84D0..DD18 as the build reads it: the stages loaded in tape order
plus the bytes the game initialises at start, cfg/overlay_fixup.json).
Every file is checked against its SHA-256.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from build_exec_rom import build_rom, parse_cas  # noqa: E402

OUT = ROOT / "ref/msx/executive"
SHA = {
    "cas": "0c8577f41c5eb9518d54d29e35a4628b93d38b405b53b207ea527f715beb4f70",
    "executive.rom": "fa119d7d2d9d7017f86bde5e241c7722f9fd2d88f988953bbb477c4f50c2822d",
    "executive.block0.bin": "37d9bf3f5fac06a6e7d1ab7d6aaac31d991ada1e63c62eb2dcc7fbcee094975b",
    "executive.block1.bin": "0c9c3f0fdf0284882fa27d81149fe03fc5f4e1fdad58bf7101319744c6ef2ca6",
    "executive.block2.bin": "96898d004ccdc1a40f0fe6fbce2573f60d41671a13f429ffdb3a989d15dacdfc",
    "executive.overlay.bin": "05e5a738d038203c103942d2a26bb863499d92ab13873356d3b3ef15c2299b6f",
}
OVERLAY_LO, OVERLAY_HI = 0x84D0, 0xDD19


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def put(name: str, data: bytes) -> None:
    if sha(data) != SHA[name]:
        raise SystemExit(f"{name}: SHA-256 {sha(data)} does not match, wrong tape?")
    (OUT / name).write_bytes(data)
    print(f"{name}: {len(data)} bytes OK")


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    cas = Path(sys.argv[1]).read_bytes()
    if sha(cas) != SHA["cas"]:
        print(f"warning: tape SHA-256 {sha(cas)} differs from the reference dump", file=sys.stderr)
    OUT.mkdir(parents=True, exist_ok=True)
    blocks = parse_cas(cas)
    put("executive.rom", build_rom(blocks))
    ram = bytearray(0x10000)
    for i, (load, _end, _entry, raw) in enumerate(blocks):
        put(f"executive.block{i}.bin", raw)
        ram[load:load + len(raw)] = raw
    fixup = json.loads((ROOT / "cfg/overlay_fixup.json").read_text())
    for addr, data in fixup["runs"]:
        at = int(addr, 16)
        ram[at:at + len(data) // 2] = bytes.fromhex(data)
    put("executive.overlay.bin", bytes(ram[OVERLAY_LO:OVERLAY_HI]))


if __name__ == "__main__":
    main()
