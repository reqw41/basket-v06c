#!/usr/bin/env python3
"""CPC AY sound asset: extract, relocate, VI53 pack."""
from __future__ import annotations

import hashlib
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from extract_cpc_snd import (  # noqa: E402
    DEFAULT_CDT,
    DEFAULT_OUT,
    MUSIC_SIZE,
    MUSIC_SIG,
    SFX_SIZE,
    V06_MUSIC,
    V06_SFX,
    extract,
)
from pack_v06_snd import SFX_OLD, pack_v06_snd  # noqa: E402


class CpcSndTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.asset = DEFAULT_OUT.read_bytes()
        cls.cdt = DEFAULT_CDT if DEFAULT_CDT.is_file() else None

    def test_asset_layout(self):
        self.assertEqual(len(self.asset), SFX_SIZE + MUSIC_SIZE)
        self.assertEqual(self.asset[SFX_SIZE - 1], 0xFF)
        self.assertEqual(self.asset[SFX_SIZE : SFX_SIZE + 12], MUSIC_SIG[:12])
        # First order-table word points at V06 music base.
        off = SFX_SIZE + 0x312
        word = self.asset[off] | self.asset[off + 1] << 8
        self.assertEqual(word, V06_MUSIC)

    def test_matches_cdt_when_present(self):
        if self.cdt is None:
            self.skipTest("CPC CDT not present")
        self.assertEqual(self.asset, extract(self.cdt))

    def test_pack_v06_snd(self):
        rom = bytearray(65536)
        rom[V06_SFX : V06_SFX + len(self.asset)] = self.asset
        notes, remap = pack_v06_snd(rom)
        self.assertEqual(notes, 200)
        self.assertEqual(set(remap), set(SFX_OLD))
        self.assertEqual(rom[0x7FBA], 0xF4)  # first packed SFX flags
        # Old SFX hole cleared for court helpers.
        self.assertEqual(rom[V06_SFX : V06_MUSIC], bytes(SFX_SIZE))

    def test_sha_stable(self):
        want = "15112d772ba6f9947109e75d301d030784765227270b6e356823275c42fa1d5b"
        self.assertEqual(hashlib.sha256(self.asset).hexdigest(), want)


if __name__ == "__main__":
    unittest.main()
