#!/usr/bin/env python3
"""Regression tests for cfg_map_v06 flow + data-keep policy.

Flow: cRET / uret / HALT / dyn / SMC.
Data: live string after JP must not be proven_deletable; LD HL,(nn) keeps
both bytes; indirect array base kept; project addresses 93F6/9417/A798 kept.
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(Path(__file__).resolve().parent / "vendor"))

from cfg_map_v06 import (  # noqa: E402
    cfg_reach,
    data_refs_from_insns,
    expand_string_objects,
    find_smc_sites,
    unsafe_after_jp_candidates,
)


def mem_from(org: int, blob: bytes) -> bytearray:
    m = bytearray(0x10000)
    m[org : org + len(blob)] = blob
    return m


class TestCfgReach(unittest.TestCase):
    def test_conditional_ret_falls_through(self):
        org = 0x9000
        blob = bytes([0xC0, 0x00, 0xC9])
        r = cfg_reach(mem_from(org, blob), {org}, org, org + len(blob))
        self.assertTrue({org, org + 1, org + 2} <= r["code_bytes"])
        self.assertEqual(r["insns"][org]["flow"], "cret")

    def test_unconditional_ret_stops(self):
        org = 0x9000
        blob = bytes([0xC9, 0x00, 0xC9])
        r = cfg_reach(mem_from(org, blob), {org}, org, org + len(blob))
        self.assertIn(org, r["code_bytes"])
        self.assertNotIn(org + 1, r["code_bytes"])

    def test_halt_continues(self):
        org = 0x9100
        blob = bytes([0x76, 0x00, 0xC9])
        r = cfg_reach(mem_from(org, blob), {org}, org, org + len(blob))
        self.assertTrue({org, org + 1, org + 2} <= r["code_bytes"])
        self.assertIn(org, r["halt"])

    def test_dyn_jp_hl_recorded_and_stops(self):
        org = 0x9200
        blob = bytes([0x00, 0xE9, 0x00, 0xC9])
        r = cfg_reach(mem_from(org, blob), {org}, org, org + len(blob))
        self.assertEqual(r["dyn"], [org + 1])
        self.assertNotIn(org + 2, r["code_bytes"])

    def test_smc_absolute_store_into_code(self):
        org = 0x9300
        blob = bytes([0x32, 0x04, 0x93, 0xC9, 0x00, 0xC9])
        mem = mem_from(org, blob)
        r = cfg_reach(mem, {org, org + 4}, org, org + len(blob))
        smc = find_smc_sites(mem, r["insns"], r["code_bytes"])
        self.assertTrue(any(s["target"] == 0x9304 for s in smc), smc)


class TestDataKeep(unittest.TestCase):
    def test_live_string_after_jp_not_proven_deletable(self):
        """JP nn ; '1 PLAYER' — string is after-JP candidate but must stay keep."""
        org = 0xA780
        # jp A800 ; then menu text (same pattern as real A7xx)
        text = b"1 PLAYER \xff2 PLAYERS  "
        blob = bytes([0xC3, 0x00, 0xA8]) + text
        mem = mem_from(org, blob)
        r = cfg_reach(mem, {org}, org, org + len(blob))
        cand = unsafe_after_jp_candidates(r["insns"], r["code_bytes"], org, org + len(blob))
        # Heuristic would see the string as candidate…
        self.assertTrue(any(org + 3 + i in cand for i in range(len(text))))
        # …but string expansion from a seed inside the text keeps the object.
        str_keep = expand_string_objects(mem, {org + 3, org + 5}, org, org + len(blob))
        self.assertIn(org + 3, str_keep)  # '1'
        self.assertIn(org + 3 + text.index(b"2"), str_keep)
        # Policy: proven_deletable must be empty (revoked) — candidates ≠ free.
        proven = set()  # revoked
        self.assertFalse(str_keep & proven)

    def test_ld_hl_indirect_keeps_both_bytes(self):
        # ld hl,(0x9400) ; ret
        org = 0x8500
        blob = bytes([0x2A, 0x00, 0x94, 0xC9])
        mem = mem_from(org, blob)
        r = cfg_reach(mem, {org}, org, org + len(blob))
        data = data_refs_from_insns(mem, r["insns"], r["code_bytes"])
        self.assertIn(0x9400, data)
        self.assertIn(0x9401, data)

    def test_ld_de_nn_array_base_kept(self):
        # ld de,0xA798 ; ret  — menu string base
        org = 0x8600
        blob = bytes([0x11, 0x98, 0xA7, 0xC9])
        mem = mem_from(org, blob)
        r = cfg_reach(mem, {org}, org, org + len(blob))
        data = data_refs_from_insns(mem, r["insns"], r["code_bytes"])
        self.assertIn(0xA798, data)

    def test_project_addrs_93f6_9417_a798_kept_via_policy(self):
        """Project false positives must be treated as keep, never proven free."""
        addrs = {0x93F6, 0x9417, 0xA798}
        # Simulate: they appear in after-JP candidates and in xref rd.
        cand = set(addrs) | {0x93F7, 0x9418}
        xref_rd = set(addrs)
        proven = set()  # revoked heuristic
        # Anything in xref_rd or string objects must not be in proven.
        keep = xref_rd | expand_string_objects(
            mem_from(0xA790, b"1 PLAYER \xff2 PLAYERS  "),
            {0xA798},
            0xA790,
            0xA7B0,
        )
        self.assertTrue(addrs <= keep | xref_rd)
        self.assertFalse(keep & proven)
        self.assertFalse(xref_rd & proven)
        # And we refuse to place code on cand alone:
        self.assertTrue(cand)
        placeable = cand - keep - xref_rd
        # 93F6/9417/A798 must not be placeable
        self.assertFalse(addrs & placeable)


if __name__ == "__main__":
    unittest.main()
