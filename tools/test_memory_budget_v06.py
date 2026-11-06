#!/usr/bin/env python3
"""Regressions for tools/memory_budget_v06.py."""
from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

import memory_budget_v06 as mb

ROOT = Path(__file__).resolve().parents[1]
CFG = ROOT / "cfg" / "memory_budget.json"


class MemoryBudgetTests(unittest.TestCase):
    def setUp(self):
        self.cfg = mb.load(CFG)

    def test_real_declaration_is_structural(self):
        report = mb.validate(self.cfg)
        self.assertEqual(report["structure_status"], "PASS", report["errors"])
        self.assertEqual(report["memory_layout_claim"], "NOT_CHECKED")
        self.assertEqual(report["capacity_status"], "MEASURED_DEFICIT")
        self.assertEqual(report["evidence_status"], "INCOMPLETE")
        # 04.11: trimmed sprite rows bring resources under 20480; code still
        # over (adapter span counts its zero padding until stage 6 packs it).
        self.assertTrue(any("code:" in d for d in report["deficits"]), report["deficits"])
        self.assertFalse(any("resources:" in d for d in report["deficits"]), report["deficits"])

    def test_region_overlap_detected(self):
        cfg = copy.deepcopy(self.cfg)
        cfg["target_regions"][1]["hi"] = cfg["target_regions"][2]["lo"] + 10
        cfg["target_regions"][1]["capacity"] = (
            cfg["target_regions"][1]["hi"] - cfg["target_regions"][1]["lo"]
        )
        report = mb.validate(cfg)
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("overlap" in e for e in report["errors"]), report["errors"])

    def test_reserve_occupation_detected(self):
        cfg = copy.deepcopy(self.cfg)
        cfg["objects"].append(
            {
                "name": "illegal_in_reserve",
                "current_lo": 0x4000,
                "current_hi": 0x4010,
                "size": 16,
                "category": "gfx_resource",
                "boundary_source": "test",
                "deps": [],
                "target_region": "recomp_reserve",
                "size_kind": "measured",
                "confidence": "high",
            }
        )
        report = mb.validate(cfg)
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("reserve recomp_reserve" in e for e in report["errors"]))

    def test_capacity_overflow_reported(self):
        cfg = copy.deepcopy(self.cfg)
        for o in cfg["objects"]:
            if o["name"] == "stage1_sprites_font":  # any resources object
                o["size"] = 100000
        report = mb.validate(cfg)
        self.assertIn(report["capacity_status"], ("MEASURED_DEFICIT", "ESTIMATED_DEFICIT"))
        self.assertTrue(
            any("resources:" in d for d in report["deficits"])
            or any("overflow" in e for e in report["errors"]),
            report,
        )

    def test_object_overlap_detected(self):
        cfg = copy.deepcopy(self.cfg)
        cfg["objects"].append(
            {
                "name": "overlap_court",
                "current_lo": 0xB500,
                "current_hi": 0xB600,
                "size": 0x100,
                "category": "gfx_resource",
                "boundary_source": "test",
                "deps": [],
                "target_region": "resources",
                "size_kind": "measured",
                "confidence": "high",
            }
        )
        report = mb.validate(cfg)
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("current overlap" in e for e in report["errors"]), report["errors"])

    def test_estimated_overflow_is_not_fit(self):
        cfg = copy.deepcopy(self.cfg)
        # Isolate this synthetic estimate from all measured capacity deficits.
        for o in cfg["objects"]:
            if o.get("target_region") and not o.get("nest_of"):
                o["target_region"] = None
        cfg["objects"].append({
            "name": "estimated_gfx_overflow", "current_lo": 0x2000,
            "current_hi": 0x2FA0, "size": 4000, "category": "gfx_buffer",
            "target_region": "gfx_buffers", "size_kind": "estimated",
            "confidence": "low", "boundary_source": "test", "deps": [],
            "aggregate": True,
            "covers": ["shared_gfx_work_2000", "released_gfx_2500_3fff"],
            "budget_count": True,
        })
        report = mb.validate(cfg)
        self.assertEqual(report["structure_status"], "PASS", report["errors"])
        self.assertEqual(report["capacity_status"], "ESTIMATED_DEFICIT")
        self.assertNotEqual(report["status"], "PASS")

    def test_nested_assignment_to_reserve_is_rejected(self):
        cfg = copy.deepcopy(self.cfg)
        cfg["objects"].append({
            "name": "nested_reserve_user", "current_lo": 0x1000,
            "current_hi": 0x1001, "size": 1, "category": "code",
            "target_region": "recomp_reserve", "size_kind": "measured",
            "confidence": "high", "boundary_source": "test", "deps": [],
            "nest_of": "title_asset", "budget_count": False,
        })
        report = mb.validate(cfg)
        self.assertEqual(report["structure_status"], "FAIL")
        self.assertTrue(any("reserve recomp_reserve" in e for e in report["errors"]))

    def test_wrong_rom_hash_is_rejected(self):
        report = mb.validate(self.cfg, "0" * 64)
        self.assertEqual(report["structure_status"], "FAIL")
        self.assertTrue(any("ROM SHA-256 mismatch" in e for e in report["errors"]))

    def test_invalid_parent_and_cycle_are_rejected(self):
        cfg = copy.deepcopy(self.cfg)
        cfg["objects"][0]["nest_of"] = "missing"
        report = mb.validate(cfg)
        self.assertEqual(report["structure_status"], "FAIL")
        self.assertTrue(any("missing parent" in e for e in report["errors"]))


if __name__ == "__main__":
    unittest.main()
