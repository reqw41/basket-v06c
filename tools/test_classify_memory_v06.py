#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

import classify_memory_v06 as cm

ROOT = Path(__file__).resolve().parents[1]


class CompleteMemoryMapTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((ROOT / "cfg/current_memory_map.json").read_text())
        cls.mem = cm.load_mem()
        cls.sha = cm.sha256(ROOT / "build/v06/basket.rom")
        cls.evidence = cm.build_evidence(cls.mem, cls.sha)
        cls.report = cm.classify(cls.config, cls.mem, cls.evidence)

    def test_exact_64k_coverage_without_unknown_class(self):
        self.assertEqual(self.report["coverage"], {
            "classified_bytes": 65536, "unclassified_bytes": 0, "overlap_bytes": 0,
        })
        self.assertNotIn("unknown", self.report["class_counts"])
        self.assertEqual(sum(self.report["class_counts"].values()), 65536)

    def test_regions_are_contiguous(self):
        regions = cm.validate_regions(self.config)
        self.assertEqual(regions[0]["lo"], 0)
        self.assertEqual(regions[-1]["hi"], 0x10000)
        for left, right in zip(regions, regions[1:]):
            self.assertEqual(left["hi"], right["lo"])

    def test_all_declared_padding_is_proven(self):
        self.assertTrue(self.report["padding_proofs"])
        claimed = [p for p in self.report["padding_proofs"] if p["reclaimable_claim"]]
        self.assertTrue(all(p["status"] == "PASS" for p in claimed), self.report["padding_proofs"])
        # The total moves with every adapter change (tools/sync_memory_map.py
        # records it); each claimed byte is proven above.
        self.assertEqual(self.report["reclaimable_bytes"], self.config["reclaimable_bytes"])
        self.assertFalse(any(p["region"] == "adapter_padding" for p in self.report["padding_proofs"]))
        # The adapter body is split only around proven dead zones (05.11).
        pieces = [r for r in self.config["regions"]
                  if r["id"] == "adapter" or r["id"].startswith("adapter_")]
        self.assertEqual(pieces[0]["lo"], "0200")
        self.assertEqual(pieces[-1]["hi"], "0E00")

    def test_padding_proof_rejects_a_trace_reference(self):
        evidence = {k: (set(v) if isinstance(v, set) else v) for k, v in self.evidence.items()}
        evidence["xref_rd"].add(0xB331)
        report = cm.classify(self.config, self.mem, evidence)
        proof = next(p for p in report["padding_proofs"] if p["region"] == "mid_padding_tail")
        self.assertEqual(proof["status"], "FAIL")

    def test_replay_tail_is_live_state(self):
        run = next(r for r in self.report["classification_runs"] if r["lo"] <= 0x1FE1 < r["hi"])
        self.assertEqual(run["class"], "mutable_state")
        self.assertEqual(run["region"], "replay_ring")

    def test_mixed_counts_cover_regions(self):
        for item in self.report["mixed_regions"].values():
            self.assertEqual(sum(item["counts"].values()), item["size"])
            self.assertNotIn("reclaimable_padding", item["counts"])

    def test_high_colour_plane_is_data_only(self):
        sys.path.insert(0, str(ROOT / "tools"))
        from build_v06_rom import splash_plane_pair
        _low, expected_high = splash_plane_pair()
        self.assertEqual(self.mem[0xC000:0xE000], expected_high)
        plane = set(range(0xC000, 0xE000))
        self.assertEqual(self.evidence["xref_exec"] & plane, set())


if __name__ == "__main__":
    unittest.main()
