import importlib.util
import math
from pathlib import Path
import sys
import unittest


MOD = Path(__file__).resolve().parents[1] / "gb_measure_01f_exec.py"
spec = importlib.util.spec_from_file_location("gb_measure_01f_exec", MOD)
m = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = m
spec.loader.exec_module(m)


class GBMeasure01FTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = m.load_manifest()

    def test_manifest_hash_and_design_order(self):
        self.assertEqual(m.sha256_file(m.MANIFEST), m.EXPECTED_MANIFEST_SHA)
        designs = m.expand_designs(self.manifest)
        self.assertEqual(len(designs), 49)
        self.assertEqual(designs[0]["design_id"], "GBM01-N1-050-N2-025")
        self.assertLessEqual(
            designs[0]["total_response_burden"],
            designs[-1]["total_response_burden"],
        )

    def test_seed_golden_and_component_split(self):
        ns = self.manifest["simulation_execution"]["seed_namespace"]
        a = m.seed(ns, "screen", "GBM01-N1-050-N2-025", "S01", "TC_NULL", 0, "stage1_A")
        b = m.seed(ns, "screen", "GBM01-N1-050-N2-025", "S01", "TC_NULL", 0, "stage1_B")
        self.assertEqual(a, 6561262688953575749)
        self.assertNotEqual(a, b)

    def test_wilson_interval_contains_observed_rate(self):
        lo, hi = m.wilson(5, 100, 0.95)
        self.assertLess(lo, 0.05)
        self.assertGreater(hi, 0.05)

    def test_reference_variance_positive(self):
        o = {
            "stage1_var_A": 0.04,
            "stage1_var_B": 0.05,
            "var_d_AB": 0.07,
            "var_d_BA": 0.08,
        }
        self.assertTrue(math.isfinite(m.ref_se(o, 50, 25, "AB")))
        self.assertGreater(m.ref_se(o, 50, 25, "BA"), 0)


if __name__ == "__main__":
    unittest.main()
