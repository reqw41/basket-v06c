#!/usr/bin/env python3
"""Check the assembled CPC-style palette and its plane-bit contract."""

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from build_v06_rom import load_syms  # noqa: E402


class CpcPaletteTests(unittest.TestCase):
    def test_palette_contract_matches_assembled_rom(self):
        cfg = json.loads((ROOT / "cfg/cpc_palette.json").read_text())
        expected = bytes(int(value, 16) for value in cfg["hardware_table"])
        self.assertEqual(expected, bytes([0xC0, 0xFF, 0x00, 0x5F]) * 4)

        rom_file = ROOT / "build/v06/basket.rom"
        lst_file = ROOT / "build/v06/glue.lst"
        self.assertTrue(rom_file.exists(), "run tools/build_v06_rom.py first")
        self.assertTrue(lst_file.exists(), "run tools/build_v06_rom.py first")
        syms = load_syms(lst_file)
        rom = bytes(0x100) + rom_file.read_bytes()
        active = syms["PAL_TAB"]
        self.assertEqual(
            rom[active:active + 16],
            expected,
            "assembled palette must expose the CPC four-pen plane contract",
        )

    def test_head_canvases_align_with_original_msx_masks(self):
        # Independent spatial reference. Matching the renderer's own staged
        # bytes cannot detect a lost crop margin or a detached head.
        mem = bytes(0x100) + (ROOT / "build/v06/basket.rom").read_bytes()
        original = bytearray(0x10000)
        block = (ROOT / "ref/msx/executive/executive.block1.bin").read_bytes()
        original[0x415A:0x415A+len(block)] = block
        # Runtime records are trimmed (canvas h, w, top, keep, kept rows) and
        # mirrored frames are references (tools/pack_sprite_mirrors.py), so
        # their offsets differ from the MSX table; canvases must not.
        sys.path.insert(0, str(ROOT / "tools"))
        from pack_sprite_mirrors import read_row
        for index in (10, 11, 22, 23, 34, 35, 46, 47):
            offset = int.from_bytes(mem[0x7760+index*2:0x7762+index*2], "little")
            address = 0x415A + offset
            height, width = mem[address:address+2]
            self.assertEqual((height, width), (16, 24))
            msx = 0x415A + int.from_bytes(original[0x7760+index*2:0x7762+index*2], "little")
            self.assertEqual(original[msx:msx+2], bytes((16, 6)))
            stride = width//8
            actual, expected = set(), set()
            for y in range(height):
                for x in range(width):
                    bit = 0x80 >> (x & 7)
                    if (read_row(mem, address, y, 0, x//8) | read_row(mem, address, y, 1, x//8)) & bit:
                        actual.add((x, y))
                    mrow = msx+2+y*stride*2
                    if not original[mrow+stride+x//8] & bit:
                        expected.add((x, y))
            with self.subTest(head=index):
                self.assertGreaterEqual(len(actual & expected)/len(actual | expected), .96,
                                        "head origin differs from MSX game coordinates")

    def test_fast_sprite_plane_order_is_recorded(self):
        cfg = json.loads((ROOT / "cfg/cpc_palette.json").read_text())
        pens = {pen["index"]: pen for pen in cfg["pens"]}
        self.assertEqual(pens[0]["role"], "bright_blue")
        self.assertEqual(pens[1]["role"], "white")
        self.assertEqual(pens[2]["role"], "black")
        self.assertEqual(pens[3]["role"], "warm_salmon")

    def test_cpc_source_pen_order_is_recorded(self):
        source = json.loads((ROOT / "cfg/cpc_palette.json").read_text())["cpc_match_source"]
        self.assertEqual(source["code_table"], "73B1")
        self.assertEqual(source["hardware_inks"], ["15", "14", "0B", "07"])
        self.assertEqual(
            source["roles_by_source_pen"],
            ["bright_blue_transparent", "black", "white", "warm_salmon"],
        )
        self.assertEqual(source["vector_role_indices_for_visible_source_pens"], [0, 2, 1, 3])


if __name__ == "__main__":
    unittest.main()
