#!/usr/bin/env python3
"""Unit tests of port/h100/machine.py on the recorded samples (S0-00.1, S0-00.2).

  python3 port/machines/test_machine.py
"""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "h100"))
import machine  # noqa: E402

S = os.path.join(HERE, "samples")


class Profiles(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.r = {d: machine.detect(os.path.join(S, d)) for d in os.listdir(S)}

    def test_names(self):
        self.assertEqual(self.r["a100-40x2"]["profile"], "a100-40x2")
        self.assertEqual(self.r["a100-80x1"]["adr006_profile"], "a100-80x1")
        self.assertEqual(self.r["h100-80x2"]["adr006_profile"], "h100-80xN")
        self.assertIsNone(self.r["v100-16x1"]["adr006_profile"])

    def test_adr006_table(self):
        c40, c80, ch = (self.r[k]["capabilities"] for k in ("a100-40x2", "a100-80x1", "h100-80x2"))
        self.assertEqual((c40["gmem_limit_gb"], c80["gmem_limit_gb"], ch["gmem_limit_gb"]), (34, 68, 68))
        for c in (c40, c80, ch):
            self.assertIn("eaton_small", c["cases_on_one_gpu"])
            self.assertIn("eaton_mid", c["cases_on_one_gpu"])
        self.assertNotIn("eaton_full", c40["cases_on_one_gpu"])
        self.assertIn("eaton_full", c80["cases_on_one_gpu"])
        self.assertEqual(c40["acceptance_g5"], ["eaton_mid"])
        self.assertEqual(c80["acceptance_g5"], ["eaton_mid", "eaton_full"])
        self.assertEqual((c40["parallel_gpu_runs"], c80["parallel_gpu_runs"]), (2, 1))
        self.assertEqual((c40["gpu_pair_check"], c80["gpu_pair_check"]), ("two GPUs", "same GPU twice"))
        self.assertEqual((c40["multi_gpu"], c80["multi_gpu"], ch["multi_gpu"]), (True, False, True))
        self.assertEqual((c40["h100_only"], c80["h100_only"], ch["h100_only"]), (False, False, True))
        self.assertTrue(c40["full_case"].startswith("multi-GPU"))
        self.assertEqual(c40["cpu_ranks"], [1, 14, 28, 56])
        self.assertEqual(c40["eaton_mid_d02"], c80["eaton_mid_d02"])   # the same acceptance case everywhere

    def test_cc_below_80_stops(self):
        c = self.r["v100-16x1"]["capabilities"]
        self.assertFalse(c["ok"])
        self.assertIn("8.0", c["stop"])

    def test_links_and_cuda(self):
        self.assertEqual(self.r["a100-40x2"]["gpu_links"], {"0-1": "SYS"})
        self.assertEqual(self.r["h100-80x2"]["gpu_links"], {"0-1": "NV18"})
        self.assertEqual(self.r["a100-40x2"]["cuda"], "13.2")

    def test_diff(self):
        a, b = self.r["a100-40x2"], self.r["a100-80x1"]
        self.assertEqual(machine.diff(a, a), "same")
        self.assertEqual(machine.diff(a, b), "gpu+host")

    def test_no_gpu(self):
        self.assertEqual(machine.parse_gpus(""), [])
        self.assertFalse(machine.capabilities([], machine.parse_lscpu(""))["ok"])

    def test_capabilities_md_current(self):
        md = open(os.path.join(HERE, "capabilities.md")).read()
        self.assertEqual(md, machine.capabilities_md(S), "regenerate: python3 port/h100/machine.py capabilities "
                                                        "--out port/machines/capabilities.md")


if __name__ == "__main__":
    unittest.main(verbosity=1)
