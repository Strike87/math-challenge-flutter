from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import platform
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from statistics import NormalDist

import numpy as np


ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
FROZEN = BASE / "frozen_inputs"
MANIFEST = FROZEN / "gb_measure_01f_exec_manifest_v1_2.json"
REPORT_MD = FROZEN / "gb_measure_01f_input_freeze_recovery_r2.md"
REVIEW_MD = FROZEN / "gb_measure_01f_r2_independent_review_pass.md"
AUTH_MD = FROZEN / "gb_measure_01f_exec_authorization_2026-09-04.md"
EXPECTED_MANIFEST_SHA = "918ba80bccadea4f45807c6c3329c54389a769e1f15c0d39d3e6672a5af5d79e"
EXPECTED_BRANCH = "research/gb-preview-01-full-text-extraction-02"
EXPECTED_HEAD = "62e6dcfbe0d2eab51ec359b036b50bf7dd3d6e66"
PHASE_SCREEN = "screen"
PHASE_CONFIRM = "confirm"
PHASE_ORACLE = "oracle"
PHASE_SENS = "sensitivity_false_negative"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def load_manifest() -> dict:
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def design_id(n1: int, n2: int) -> str:
    return f"GBM01-N1-{n1:03d}-N2-{n2:03d}"


def expand_designs(manifest: dict) -> list[dict]:
    n1s = manifest["calibration_design"]["stage1"]["n_per_form_grid"]
    n2s = manifest["calibration_design"]["stage2"]["n_per_order_grid"]
    rows = []
    for n1 in n1s:
        for n2 in n2s:
            rows.append(
                {
                    "design_id": design_id(n1, n2),
                    "n_stage1_per_form": n1,
                    "n_stage2_per_order": n2,
                    "total_response_burden": 36 * n1 + 72 * n2,
                    "total_participants": 2 * n1 + 2 * n2,
                    "repeated_measurement_participants": 2 * n2,
                }
            )
    return sorted(
        rows,
        key=lambda r: (
            r["total_response_burden"],
            r["total_participants"],
            r["repeated_measurement_participants"],
            r["n_stage1_per_form"],
            r["design_id"],
        ),
    )


def seed(namespace: str, phase: str, did: str, sid: str, shift: str, i: int, component: str) -> int:
    key = f"{namespace}|{phase}|{did}|{sid}|{shift}|{i}|{component}"
    return int.from_bytes(hashlib.sha256(key.encode("utf-8")).digest()[:8], "big") & 0x7FFFFFFFFFFFFFFF


def rng(namespace: str, phase: str, did: str, sid: str, shift: str, i: int, component: str):
    return np.random.Generator(np.random.PCG64DXSM(seed(namespace, phase, did, sid, shift, i, component)))


def logistic(x):
    return 1.0 / (1.0 + np.exp(-x))


@dataclass(frozen=True)
class Scenario:
    id: str
    p_ref: float
    person_sd: float
    person_by_form_sd: float
    person_by_occasion_sd: float
    form_shift_B_minus_A_logit: float
    practice_shift_logit: float
    form_second_interaction_logit: float

    @classmethod
    def from_dict(cls, d: dict) -> "Scenario":
        return cls(
            d["id"],
            d["p_ref"],
            d["person_sd"],
            d["person_by_form_sd"],
            d["person_by_occasion_sd"],
            d["form_shift_B_minus_A_logit"],
            d["practice_shift_logit"],
            d["form_second_interaction_logit"],
        )


def eta(s: Scenario, form: str, occasion: int, theta, u, v, true_change: float = 0.0):
    x = math.log(s.p_ref / (1.0 - s.p_ref)) + theta + u + v
    if form == "B":
        x = x + s.form_shift_B_minus_A_logit
    if occasion == 2:
        x = x + s.practice_shift_logit + true_change
    if form == "B" and occasion == 2:
        x = x + s.form_second_interaction_logit
    return x


def stage1_scores(r, s: Scenario, n: int, form: str) -> np.ndarray:
    theta = r.normal(0, s.person_sd, size=n)
    u = r.normal(0, s.person_by_form_sd, size=n)
    v = r.normal(0, s.person_by_occasion_sd, size=n)
    return r.binomial(18, logistic(eta(s, form, 1, theta, u, v)), size=n) / 18.0


def stage2_diffs(r, s: Scenario, n: int, order: str) -> np.ndarray:
    theta = r.normal(0, s.person_sd, size=n)
    u_a = r.normal(0, s.person_by_form_sd, size=n)
    u_b = r.normal(0, s.person_by_form_sd, size=n)
    v1 = r.normal(0, s.person_by_occasion_sd, size=n)
    v2 = r.normal(0, s.person_by_occasion_sd, size=n)
    if order == "AB":
        a1 = r.binomial(18, logistic(eta(s, "A", 1, theta, u_a, v1)), size=n) / 18.0
        b2 = r.binomial(18, logistic(eta(s, "B", 2, theta, u_b, v2)), size=n) / 18.0
        return b2 - a1
    b1 = r.binomial(18, logistic(eta(s, "B", 1, theta, u_b, v1)), size=n) / 18.0
    a2 = r.binomial(18, logistic(eta(s, "A", 2, theta, u_a, v2)), size=n) / 18.0
    return a2 - b1


def decision_diff(r, s: Scenario, order: str, true_change: float) -> float:
    theta = r.normal(0, s.person_sd)
    u_a = r.normal(0, s.person_by_form_sd)
    u_b = r.normal(0, s.person_by_form_sd)
    v1 = r.normal(0, s.person_by_occasion_sd)
    v2 = r.normal(0, s.person_by_occasion_sd)
    if order == "AB":
        a1 = r.binomial(18, logistic(eta(s, "A", 1, theta, u_a, v1))) / 18.0
        b2 = r.binomial(18, logistic(eta(s, "B", 2, theta, u_b, v2, true_change))) / 18.0
        return float(b2 - a1)
    b1 = r.binomial(18, logistic(eta(s, "B", 1, theta, u_b, v1))) / 18.0
    a2 = r.binomial(18, logistic(eta(s, "A", 2, theta, u_a, v2, true_change))) / 18.0
    return float(a2 - b1)


def summarize_oracle(args) -> dict:
    manifest, sid = args
    ns = manifest["simulation_execution"]["seed_namespace"]
    s = Scenario.from_dict(next(x for x in manifest["scenarios"] if x["id"] == sid))
    R = manifest["oracle"]["replications_per_scenario"]
    a = np.empty(R)
    b = np.empty(R)
    dab = np.empty(R)
    dba = np.empty(R)
    for i in range(R):
        a[i] = stage1_scores(rng(ns, PHASE_ORACLE, "ORACLE", sid, "TC_NULL", i, "stage1_A"), s, 1, "A")[0]
        b[i] = stage1_scores(rng(ns, PHASE_ORACLE, "ORACLE", sid, "TC_NULL", i, "stage1_B"), s, 1, "B")[0]
        dab[i] = stage2_diffs(rng(ns, PHASE_ORACLE, "ORACLE", sid, "TC_NULL", i, "stage2_AB"), s, 1, "AB")[0]
        dba[i] = stage2_diffs(rng(ns, PHASE_ORACLE, "ORACLE", sid, "TC_NULL", i, "stage2_BA"), s, 1, "BA")[0]
    return {
        "scenario_id": sid,
        "R": R,
        "stage1_var_A": float(np.var(a, ddof=1)),
        "stage1_var_B": float(np.var(b, ddof=1)),
        "var_d_AB": float(np.var(dab, ddof=1)),
        "var_d_BA": float(np.var(dba, ddof=1)),
        "true_form_correction": float((np.mean(dab) - np.mean(dba)) / 2.0),
        "true_practice_correction": float((np.mean(dab) + np.mean(dba)) / 2.0),
    }


def ref_se(oracle: dict, n1: int, n2: int, order: str) -> float:
    v1 = oracle["stage1_var_A"] / n1 + oracle["stage1_var_B"] / n1
    v2 = 0.25 * (oracle["var_d_AB"] / n2 + oracle["var_d_BA"] / n2)
    w1, w2 = 1.0 / v1, 1.0 / v2
    l1 = w1 / (w1 + w2)
    l2 = w2 / (w1 + w2)
    vf = l1 * l1 * v1 + l2 * l2 * v2
    vp = v2
    cfp = l2 * 0.25 * (oracle["var_d_AB"] / n2 - oracle["var_d_BA"] / n2)
    vd = oracle["var_d_AB"] if order == "AB" else oracle["var_d_BA"]
    sign = 1.0 if order == "AB" else -1.0
    return math.sqrt(vd + vf + vp + 2.0 * sign * cfp)


def wilson(k: int, n: int, level: float) -> tuple[float, float]:
    z = NormalDist().inv_cdf(0.5 + level / 2.0)
    if n == 0:
        return (math.nan, math.nan)
    p = k / n
    d = 1.0 + z * z / n
    c = (p + z * z / (2.0 * n)) / d
    h = z * math.sqrt((p * (1.0 - p) + z * z / (4.0 * n)) / n) / d
    return c - h, c + h


def finite_positive(*xs: float) -> bool:
    return all(math.isfinite(x) and x > 0 for x in xs)


def one_rep(manifest: dict, phase: str, row: dict, sid: str, i: int, oracle: dict, true_change: float = 0.0) -> dict:
    ns = manifest["simulation_execution"]["seed_namespace"]
    s = Scenario.from_dict(next(x for x in manifest["scenarios"] if x["id"] == sid))
    did = row["design_id"]
    shift = "TC_NULL" if true_change == 0.0 and phase != PHASE_SENS else f"TC_{true_change:+0.6f}"
    n1, n2 = row["n_stage1_per_form"], row["n_stage2_per_order"]
    order = "AB" if i % 2 == 0 else "BA"
    try:
        a = stage1_scores(rng(ns, phase, did, sid, shift, i, "stage1_A"), s, n1, "A")
        b = stage1_scores(rng(ns, phase, did, sid, shift, i, "stage1_B"), s, n1, "B")
        dab = stage2_diffs(rng(ns, phase, did, sid, shift, i, "stage2_AB"), s, n2, "AB")
        dba = stage2_diffs(rng(ns, phase, did, sid, shift, i, "stage2_BA"), s, n2, "BA")
        d = decision_diff(rng(ns, phase, did, sid, shift, i, f"decision_{order}"), s, order, true_change)
        va = float(np.var(a, ddof=1))
        vb = float(np.var(b, ddof=1))
        vab = float(np.var(dab, ddof=1))
        vba = float(np.var(dba, ddof=1))
        v1 = va / n1 + vb / n1
        v2 = 0.25 * (vab / n2 + vba / n2)
        if not finite_positive(v1, v2):
            raise ArithmeticError("invalid calibration variance")
        f1 = float(np.mean(b) - np.mean(a))
        f2 = float((np.mean(dab) - np.mean(dba)) / 2.0)
        p_hat = float((np.mean(dab) + np.mean(dba)) / 2.0)
        z_form = (f1 - f2) / math.sqrt(v1 + v2)
        if not math.isfinite(z_form) or abs(z_form) > 2.5758293035489004:
            return {"valid": False, "order": order, "reliable": 0, "inc": 0, "dec": 0}
        w1, w2 = 1.0 / v1, 1.0 / v2
        l1, l2 = w1 / (w1 + w2), w2 / (w1 + w2)
        f_hat = l1 * f1 + l2 * f2
        vf = l1 * l1 * v1 + l2 * l2 * v2
        vp = v2
        cfp = l2 * 0.25 * (vab / n2 - vba / n2)
        vd = vab if order == "AB" else vba
        sign = 1.0 if order == "AB" else -1.0
        v_adj = vd + vf + vp + 2.0 * sign * cfp
        if not finite_positive(v_adj):
            raise ArithmeticError("invalid adjusted variance")
        se = math.sqrt(v_adj)
        d_adj = d - sign * f_hat - p_hat
        z = d_adj / se
        reliable = int(abs(z) >= 1.959963984540054)
        direction = 1 if z >= 1.959963984540054 else (-1 if z <= -1.959963984540054 else 0)
        ref = ref_se(oracle, n1, n2, order)
        return {
            "valid": True,
            "order": order,
            "reliable": reliable,
            "inc": int(direction == 1),
            "dec": int(direction == -1),
            "direction": direction,
            "se_rel": (se - ref) / ref,
            "se_abs_rel": abs(se - ref) / ref,
            "f_bias": (f_hat - oracle["true_form_correction"]) / ref,
            "p_bias": (p_hat - oracle["true_practice_correction"]) / ref,
            "VD_hat": vd,
            "VF_hat": vf,
            "VP_hat": vp,
            "CFP_hat": cfp,
            "V_adj_hat": v_adj,
            "SE_adj_hat": se,
        }
    except Exception:
        return {"valid": False, "order": order, "reliable": 0, "inc": 0, "dec": 0}


def mean_ci(values: list[float], level: float) -> tuple[float, float, float, int]:
    n = len(values)
    if n == 0:
        return math.nan, math.nan, math.nan, 0
    arr = np.asarray(values, dtype=float)
    mean = float(np.mean(arr))
    mcse = float(np.std(arr, ddof=1) / math.sqrt(n)) if n > 1 else 0.0
    z = NormalDist().inv_cdf(0.5 + level / 2.0)
    return mean, mean - z * mcse, mean + z * mcse, n


def run_cell(args) -> tuple[dict, dict | None]:
    manifest, phase, row, sid, R, oracle, level, true_change = args
    reps = [one_rep(manifest, phase, row, sid, i, oracle, true_change) for i in range(R)]
    valid = [r for r in reps if r["valid"]]
    reliable = sum(r["reliable"] for r in reps)
    inc = sum(r["inc"] for r in reps)
    dec = sum(r["dec"] for r in reps)
    invalid = R - len(valid)
    lo_fp, hi_fp = wilson(reliable, R, level)
    lo_bad, hi_bad = wilson(invalid, R, level)
    m_se, l_se, h_se, n_valid = mean_ci([r["se_rel"] for r in valid], level)
    m_abs, l_abs, h_abs, _ = mean_ci([r["se_abs_rel"] for r in valid], level)
    m_f, l_f, h_f, _ = mean_ci([r["f_bias"] for r in valid], level)
    m_p, l_p, h_p, _ = mean_ci([r["p_bias"] for r in valid], level)
    out = {
        **row,
        "scenario_id": sid,
        "phase": phase,
        "true_change_logit": true_change,
        "R": R,
        "valid_n": n_valid,
        "ab_count": sum(r["order"] == "AB" for r in reps),
        "ba_count": sum(r["order"] == "BA" for r in reps),
        "false_reliable_change_rate": reliable / R,
        "false_reliable_change_ci_low": lo_fp,
        "false_reliable_change_ci_high": hi_fp,
        "false_increase_rate": inc / R,
        "false_decrease_rate": dec / R,
        "indeterminate_rate": invalid / R,
        "indeterminate_ci_low": lo_bad,
        "indeterminate_ci_high": hi_bad,
        "se_signed_rel_bias": m_se,
        "se_signed_rel_bias_ci_low": l_se,
        "se_signed_rel_bias_ci_high": h_se,
        "se_abs_rel_error": m_abs,
        "se_abs_rel_error_ci_low": l_abs,
        "se_abs_rel_error_ci_high": h_abs,
        "form_bias_norm": m_f,
        "form_bias_norm_ci_low": l_f,
        "form_bias_norm_ci_high": h_f,
        "practice_bias_norm": m_p,
        "practice_bias_norm_ci_low": l_p,
        "practice_bias_norm_ci_high": h_p,
    }
    diag = None
    if valid:
        diag = {k: float(np.mean([r[k] for r in valid])) for k in ["VD_hat", "VF_hat", "VP_hat", "CFP_hat", "V_adj_hat", "SE_adj_hat"]}
        diag.update({**row, "scenario_id": sid, "phase": phase, "true_change_logit": true_change, "R": R, "valid_n": n_valid})
    if phase == PHASE_SENS:
        wanted = 1 if true_change > 0 else -1
        directional = sum(r.get("direction") == wanted for r in reps) / R
        wrong = sum(r.get("direction") == -wanted for r in reps) / R
        out.update({"directional_power": directional, "wrong_direction_rate": wrong, "false_negative_rate": 1.0 - directional - out["indeterminate_rate"]})
    return out, diag


def write_csv(path: Path, rows: list[dict]) -> None:
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    keys = list(dict.fromkeys(k for r in rows for k in r))
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=keys)
        w.writeheader()
        w.writerows(rows)


def preflight() -> dict:
    runtimes = {}
    for cmd in (["py", "-0p"], [sys.executable, "--version"]):
        try:
            runtimes[" ".join(cmd)] = subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True, check=False).stdout.strip() or subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True, check=False).stderr.strip()
        except FileNotFoundError:
            runtimes[" ".join(cmd)] = "UNAVAILABLE"
    branch = subprocess.run(["git", "branch", "--show-current"], cwd=ROOT, text=True, capture_output=True, check=False).stdout.strip()
    head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True, capture_output=True, check=False).stdout.strip()
    status = subprocess.run(["git", "status", "--short"], cwd=ROOT, text=True, capture_output=True, check=False).stdout
    manifest_sha = sha256_file(MANIFEST)
    md = REPORT_MD.read_text(encoding="utf-8")
    review = REVIEW_MD.read_text(encoding="utf-8")
    auth = AUTH_MD.read_text(encoding="utf-8")
    failures = []
    if branch != EXPECTED_BRANCH:
        failures.append(f"branch {branch!r} != {EXPECTED_BRANCH!r}")
    if head != EXPECTED_HEAD:
        failures.append(f"HEAD {head!r} != {EXPECTED_HEAD!r}")
    if manifest_sha != EXPECTED_MANIFEST_SHA:
        failures.append("manifest sha mismatch")
    if EXPECTED_MANIFEST_SHA not in md or EXPECTED_MANIFEST_SHA not in auth:
        failures.append("markdown/authorization manifest hash mismatch")
    if "PASS / APPROVED_FOR_01F_EXEC" not in review:
        failures.append("independent review verdict missing")
    if sys.implementation.name != "cpython" or platform.python_version() != "3.13.5" or np.__version__ != "2.3.5" or np.random.PCG64DXSM.__name__ != "PCG64DXSM":
        failures.append("runtime mismatch")
    return {
        "branch": branch,
        "head": head,
        "git_status_short": status,
        "available_runtimes": runtimes,
        "manifest_sha256": manifest_sha,
        "python_implementation": sys.implementation.name,
        "python_version": platform.python_version(),
        "numpy_version": np.__version__,
        "prng": str(np.random.PCG64DXSM),
        "failures": failures,
    }


def hard_fail(row: dict, level_key: str = "ci_low") -> list[str]:
    reasons = []
    if row["scenario_id"] != "S09":
        if row["false_reliable_change_ci_low"] > 0.06:
            reasons.append("false_reliable_change")
        if row["indeterminate_ci_low"] > 0.05:
            reasons.append("indeterminate")
        if row["se_signed_rel_bias_ci_low"] > 0.05 or row["se_signed_rel_bias_ci_high"] < -0.05:
            reasons.append("se_signed_rel_bias")
        if row["se_abs_rel_error_ci_low"] > 0.1:
            reasons.append("se_abs_rel_error")
        if min(abs(row["form_bias_norm_ci_low"]), abs(row["form_bias_norm_ci_high"])) > 0.1 and (row["form_bias_norm_ci_low"] > 0.1 or row["form_bias_norm_ci_high"] < -0.1):
            reasons.append("form_bias_norm")
        if min(abs(row["practice_bias_norm_ci_low"]), abs(row["practice_bias_norm_ci_high"])) > 0.1 and (row["practice_bias_norm_ci_low"] > 0.1 or row["practice_bias_norm_ci_high"] < -0.1):
            reasons.append("practice_bias_norm")
    else:
        pass_rate = 1.0 - row["indeterminate_rate"]
        lo, _ = wilson(round(pass_rate * row["R"]), row["R"], 0.99)
        if lo > 0.2:
            reasons.append("s09_calibration_pass")
        if row["false_reliable_change_ci_low"] > 0.06:
            reasons.append("s09_false_reliable_change")
    return reasons


def passes(row: dict) -> tuple[bool, list[str]]:
    reasons = []
    if row["scenario_id"] != "S09":
        checks = [
            (row["false_reliable_change_ci_high"] <= 0.06, "false_reliable_change"),
            (row["indeterminate_ci_high"] <= 0.05, "indeterminate"),
            (row["se_signed_rel_bias_ci_low"] >= -0.05 and row["se_signed_rel_bias_ci_high"] <= 0.05, "se_signed_rel_bias"),
            (row["se_abs_rel_error_ci_high"] <= 0.1, "se_abs_rel_error"),
            (max(abs(row["form_bias_norm_ci_low"]), abs(row["form_bias_norm_ci_high"])) <= 0.1, "form_bias_norm"),
            (max(abs(row["practice_bias_norm_ci_low"]), abs(row["practice_bias_norm_ci_high"])) <= 0.1, "practice_bias_norm"),
        ]
    else:
        pass_rate = 1.0 - row["indeterminate_rate"]
        _, pass_hi = wilson(round(pass_rate * row["R"]), row["R"], 0.95)
        checks = [(pass_hi <= 0.2, "s09_calibration_pass"), (row["false_reliable_change_ci_high"] <= 0.06, "s09_false_reliable_change")]
        row["calibration_pass_rate"] = pass_rate
        row["calibration_pass_rate_ci_high"] = pass_hi
    for ok, reason in checks:
        if not ok:
            reasons.append(reason)
    return not reasons, reasons


def run(args) -> int:
    manifest = load_manifest()
    pf = preflight()
    execution_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out = BASE / "results" / execution_id
    out.mkdir(parents=True, exist_ok=False)
    if pf["failures"]:
        (out / "execution_manifest.json").write_text(json.dumps({"status": "GB_MEASURE_01F_EXEC_BLOCKED_PREFLIGHT", "preflight": pf}, indent=2), encoding="utf-8")
        print("GB_MEASURE_01F_EXEC_BLOCKED_PREFLIGHT")
        print(out)
        return 2
    designs = expand_designs(manifest)
    scenarios = [s["id"] for s in manifest["scenarios"]]
    write_csv(out / "design_grid.csv", designs)
    print("runtime", sys.implementation.name, platform.python_version(), np.__version__, np.random.PCG64DXSM, flush=True)
    print("manifest", pf["manifest_sha256"], flush=True)
    with ProcessPoolExecutor(max_workers=args.workers) as ex:
        oracle_rows = [f.result() for f in as_completed(ex.submit(summarize_oracle, (manifest, sid)) for sid in scenarios)]
    oracle_rows.sort(key=lambda r: r["scenario_id"])
    oracle_by_sid = {r["scenario_id"]: r for r in oracle_rows}
    write_csv(out / "oracle_by_scenario.csv", oracle_rows)
    screen_args = [(manifest, PHASE_SCREEN, d, sid, manifest["simulation_execution"]["screen_replications_per_design_scenario"], oracle_by_sid[sid], 0.99, 0.0) for d in designs for sid in scenarios]
    screen, diag = [], []
    with ProcessPoolExecutor(max_workers=args.workers) as ex:
        for fut in as_completed(ex.submit(run_cell, a) for a in screen_args):
            r, dd = fut.result()
            screen.append(r)
            if dd:
                diag.append(dd)
    screen.sort(key=lambda r: (r["design_id"], r["scenario_id"]))
    write_csv(out / "screening_metrics.csv", screen)
    exclusions = []
    survivors = []
    for d in designs:
        reasons = []
        for r in [x for x in screen if x["design_id"] == d["design_id"]]:
            reasons += [f"{r['scenario_id']}:{x}" for x in hard_fail(r)]
        if reasons:
            exclusions.append({**d, "hard_screen_fail_reasons": ";".join(reasons)})
        else:
            survivors.append(d)
    write_csv(out / "screening_exclusions.csv", exclusions)
    confirm, sensitivity = [], []
    if survivors:
        cargs = [(manifest, PHASE_CONFIRM, d, sid, manifest["simulation_execution"]["confirm_replications_per_design_scenario"], oracle_by_sid[sid], 0.95, 0.0) for d in survivors for sid in scenarios]
        with ProcessPoolExecutor(max_workers=args.workers) as ex:
            for fut in as_completed(ex.submit(run_cell, a) for a in cargs):
                r, dd = fut.result()
                confirm.append(r)
                if dd:
                    diag.append(dd)
        sids = [s for s in scenarios if s != "S09"]
        shifts = manifest["acceptance_thresholds"]["non_gating_false_negative_reporting"]["true_change_logit_shifts"]
        sargs = [(manifest, PHASE_SENS, d, sid, manifest["simulation_execution"]["confirm_replications_per_design_scenario"], oracle_by_sid[sid], 0.95, sh) for d in survivors for sid in sids for sh in shifts]
        with ProcessPoolExecutor(max_workers=args.workers) as ex:
            for fut in as_completed(ex.submit(run_cell, a) for a in sargs):
                r, dd = fut.result()
                sensitivity.append(r)
                if dd:
                    diag.append(dd)
    confirm.sort(key=lambda r: (r["design_id"], r["scenario_id"]))
    sensitivity.sort(key=lambda r: (r["design_id"], r["scenario_id"], r["true_change_logit"]))
    write_csv(out / "confirmatory_metrics.csv", confirm)
    write_csv(out / "sensitivity_power_fnr.csv", sensitivity)
    write_csv(out / "variance_diagnostics.csv", diag)
    adjudication = []
    selected = None
    for d in designs:
        if d not in survivors:
            row = next(x for x in exclusions if x["design_id"] == d["design_id"])
            adjudication.append({**d, "status": "SCREEN_EXCLUDED", "failed_reasons": row["hard_screen_fail_reasons"]})
            continue
        reasons = []
        for r in [x for x in confirm if x["design_id"] == d["design_id"]]:
            ok, rs = passes(r)
            reasons += [f"{r['scenario_id']}:{x}" for x in rs]
        status = "PASS" if not reasons else "FAIL"
        adjudication.append({**d, "status": status, "failed_reasons": ";".join(reasons)})
        if selected is None and status == "PASS":
            selected = d
    write_csv(out / "design_adjudication.csv", adjudication)
    write_csv(out / "s09_sentinel.csv", [r for r in confirm if r["scenario_id"] == "S09"])
    code_hash = sha256_file(Path(__file__))
    files = {}
    for p in sorted(out.glob("*")):
        if p.is_file() and p.name != "result_hashes.json":
            files[p.name] = sha256_file(p)
    summary = {
        "status": "GB_MEASURE_01F_EXEC_COMPLETE",
        "execution_id": execution_id,
        "preflight": pf,
        "seed_namespace": manifest["simulation_execution"]["seed_namespace"],
        "code_hash": code_hash,
        "screen_survivor_count": len(survivors),
        "selected_minimum_design": selected or "NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID",
        "result_file_hashes": files,
        "completed_at_utc": datetime.now(timezone.utc).isoformat(),
        "mayAffectGameplay": False,
    }
    (out / "execution_manifest.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    files["execution_manifest.json"] = sha256_file(out / "execution_manifest.json")
    (out / "result_hashes.json").write_text(json.dumps(files, indent=2, sort_keys=True), encoding="utf-8")
    report = [
        "# GB-MEASURE-01F-EXEC Report",
        "",
        "GB_MEASURE_01F_EXEC_COMPLETE",
        "",
        f"- Manifest SHA-256: `{pf['manifest_sha256']}`",
        f"- Code SHA-256: `{code_hash}`",
        f"- Oracle scenarios: `{len(oracle_rows)}`",
        f"- Screening survivors: `{len(survivors)}`",
        f"- Minimum design: `{selected['design_id'] if selected else 'NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID'}`",
        f"- mayAffectGameplay: `false`",
        f"- Independent post-execution outcome review still required.",
    ]
    (out / "gb_measure_01f_exec_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")
    files["gb_measure_01f_exec_report.md"] = sha256_file(out / "gb_measure_01f_exec_report.md")
    (out / "result_hashes.json").write_text(json.dumps(files, indent=2, sort_keys=True), encoding="utf-8")
    print("GB_MEASURE_01F_EXEC_COMPLETE")
    print(out)
    print(json.dumps({"selected": summary["selected_minimum_design"], "screen_survivor_count": len(survivors)}, indent=2))
    return 0


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("command", choices=["run", "preflight", "design-grid"])
    p.add_argument("--workers", type=int, default=1)
    args = p.parse_args()
    if args.command == "preflight":
        print(json.dumps(preflight(), indent=2))
        return 0
    if args.command == "design-grid":
        write_csv(BASE / "design_grid_preview.csv", expand_designs(load_manifest()))
        return 0
    return run(args)


if __name__ == "__main__":
    raise SystemExit(main())
