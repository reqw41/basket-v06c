#!/usr/bin/env python3
"""Regression tests for false-green prevention in the verification runner."""
import sys
import tempfile
import unittest
from pathlib import Path

from verify_refactor import execute, validate_match


class VerificationTests(unittest.TestCase):
    def good(self):
        return {"rom_sha256": "abc", "mode": "2p", "missing_required": [],
                "phase": "ready", "playersMode": 2}

    def test_stale_rom_rejected(self):
        self.assertTrue(validate_match(self.good(), "2p", "different"))

    def test_ready_required(self):
        m = self.good()
        m["phase"] = "menu"
        self.assertTrue(validate_match(m, "2p", "abc"))

    def test_wrong_mode_rejected(self):
        self.assertTrue(validate_match(self.good(), "1p", "abc"))

    def test_missing_outcome_metadata_rejected(self):
        m = self.good()
        del m["missing_required"]
        self.assertTrue(validate_match(m, "2p", "abc"))

    def test_forced_entry_rejected(self):
        m = self.good()
        m["procedure_check"] = {"returned": True}
        self.assertTrue(validate_match(m, "2p", "abc"))

    def test_matching_success_accepted(self):
        self.assertEqual(validate_match(self.good(), "2p", "abc"), [])

    def test_timeout_and_nonzero_are_not_pass(self):
        with tempfile.TemporaryDirectory() as d:
            log = Path(d) / "test.log"
            r = execute([sys.executable, "-c", "raise SystemExit(1)"], d, log, 2)
            self.assertEqual(r["status"], "FAIL")
            r = execute([sys.executable, "-c", "import time; time.sleep(3)"], d, log, .05)
            self.assertEqual(r["status"], "ERROR")


if __name__ == "__main__":
    unittest.main()
