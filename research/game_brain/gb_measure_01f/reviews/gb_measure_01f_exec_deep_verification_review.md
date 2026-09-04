# GB-MEASURE-01F-EXEC — Deep Technical/Scientific Verification Review

**Review role:** second-party deep verification by the assistant that participated in the R1/R2 protocol work.  
**Formal independence claim:** **NO** — this report is intentionally **not** labeled the formal independent post-execution review.  
**Execution package reviewed:** `research.zip`  
**research.zip SHA-256:** `5b0568f988dc74bb2b7726e6132ea28a3f02ef192cf8d592c6ccac298a2e4500`  
**Execution ID:** `20260904T172054Z`  
**Frozen manifest SHA-256:** `918ba80bccadea4f45807c6c3329c54389a769e1f15c0d39d3e6672a5af5d79e`  
**Execution code SHA-256:** `12ae1e5c13f86c584837d16c15f8687617491900d86fba0a995d5aeda5557172`

## Verdict

```text
PASS_FOR_EXTERNAL_INDEPENDENT_CONFIRMATION
```

I found **no blocking defect that overturns the specific execution outcome**:

```text
NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID
```

The zero-survivor result is independently recoverable from the supplied aggregate
screening artifacts and is especially robust because **every one of the 49 designs
hard-fails the frozen S09 calibration-pass sentinel at screening**.

This is not the formal independent close because I participated in building the
governing R1/R2 package.

---

## 1. Package and hash integrity

Verified directly from the supplied ZIP:

```text
Frozen manifest SHA-256
= 918ba80bccadea4f45807c6c3329c54389a769e1f15c0d39d3e6672a5af5d79e

Execution code SHA-256
= 12ae1e5c13f86c584837d16c15f8687617491900d86fba0a995d5aeda5557172
```

The execution code hash matches the execution report/manifest.

Every hash listed in `result_hashes.json` matches the corresponding supplied file,
including:

```text
execution_manifest.json
gb_measure_01f_exec_report.md
design_grid.csv
oracle_by_scenario.csv
screening_metrics.csv
screening_exclusions.csv
design_adjudication.csv
variance_diagnostics.csv
confirmatory_metrics.csv
s09_sentinel.csv
sensitivity_power_fnr.csv
```

The three expected no-survivor outputs are truly zero-byte files and therefore
correctly have the SHA-256 of an empty file.

---

## 2. Runtime / authority verification

The supplied execution manifest records:

```text
branch = research/gb-preview-01-full-text-extraction-02
HEAD   = 62e6dcfbe0d2eab51ec359b036b50bf7dd3d6e66

Python implementation = cpython
Python version        = 3.13.5
NumPy                 = 2.3.5
PRNG                  = PCG64DXSM

seed namespace
= GBM01F_EXEC_V1_20260904

mayAffectGameplay
= false
```

The frozen authorization and independent R2 PASS records are included, and their
hash linkage is consistent.

No production/gameplay authority is introduced by the research code.

---

## 3. Static protocol → code parity

I inspected `gb_measure_01f_exec.py` directly.

Outcome-critical frozen behavior is implemented consistently:

```text
49 frozen designs
frozen minimum-design burden ordering
S01-S09 DGM
Stage-1 A/B independent groups
Stage-2 AB/BA independent order groups
independent target decision pair
even replicate -> AB
odd replicate  -> BA
component-specific SHA-256 seeds
PCG64DXSM Generator
frozen component draw order
complete-data-only / fail-closed replicate handling
form-consistency gate
plug-in F_hat / P_hat variance-covariance algebra
D_adj orientation rule
V_adj = VD + VF + VP + 2*s*CFP
two-sided z decision rule
99% hard-screen rule
95% confirmatory rule
S09 sentinel logic
no confirmatory or sensitivity phase when survivors = 0
```

No use of Python `random`, `default_rng`, global NumPy RNG state, OS entropy, or
wall-clock random seeding was found.

The source does duplicate several frozen constants in code instead of reading all
of them from the manifest. I verified the duplicated values used on the
outcome-critical path match R2. This is a maintainability/drift risk, not an
observed result discrepancy in this run.

---

## 4. Design-grid / screening coverage

Verified:

```text
design rows
= 49

screening rows
= 441
= 49 designs × 9 scenarios

unique design × scenario cells
= 441

R per screening cell
= 3000

AB per screening cell
= 1500

BA per screening cell
= 1500
```

The supplied `design_grid.csv` exactly matches the frozen ordering calculation:

```text
1. response burden
2. total participants
3. repeated participants
4. n1
5. design_id
```

No design/scenario cell is missing or duplicated.

---

## 5. Independent hard-screen recomputation

I independently recomputed the screening exclusion decision from
`screening_metrics.csv` rather than calling the executor's `hard_fail()` function.

Result:

```text
recomputed exclusions
= exact match to screening_exclusions.csv

independent survivors
= 0

design_adjudication rows
= 49

all adjudication states
= SCREEN_EXCLUDED
```

The exact failed-reason strings reproduce for all 49 designs.

---

## 6. Decisive S09 result

This is the most important finding.

Every candidate design contains:

```text
S09:s09_calibration_pass
```

as a hard-screen exclusion reason.

The frozen sentinel requires:

```text
upper 95% Wilson bound of CALIBRATION_PASS
<= 0.200
```

For hard screening, exclusion is allowed when the **99% interval lies wholly on
the failing side**. The observed S09 calibration-pass behavior is nowhere close
to the threshold.

Across all 49 designs:

```text
observed S09 calibration-pass rate:
0.900667 to 0.984333

independently recomputed lower 99% Wilson bound:
0.885704 to 0.977334

frozen failing boundary:
> 0.200
```

Even the design with the **lowest** S09 calibration-pass rate was:

```text
GBM01-N1-400-N2-200

valid / calibration-pass
= 2702 / 3000
= 0.900667

lower 99% Wilson bound
= 0.885704
```

That lower bound is still more than four times the allowed `.200` threshold.

Therefore:

```text
all 49 designs
→ legitimate hard-screen exclusion from S09 alone
```

This conclusion does **not** depend on borderline rounding, a close Monte Carlo
interval, or the core continuous-metric gates.

---

## 7. Why confirmatory and sensitivity outputs are empty

Because survivors = 0, the frozen execution plan does not enter:

```text
confirmatory
S09 confirmatory sentinel table
sensitivity / FNR
```

Therefore the supplied zero-byte files:

```text
confirmatory_metrics.csv
s09_sentinel.csv
sensitivity_power_fnr.csv
```

are protocol-consistent and are not missing execution work.

---

## 8. Scientific interpretation of the result

The result does **not** establish that reliable-change measurement is impossible.

It establishes only:

> Under the frozen R2 DGM, scenarios, sentinel, thresholds, candidate grid, and
> execution rules, none of the 49 candidate calibration designs is admissible.

More specifically, the decisive failure is that the intended S09 model-
misspecification sentinel does **not** fail closed often enough. The calibration
continues to pass in roughly 90–98% of S09 screening replications, while the
frozen gate requires the upper 95% calibration-pass bound to be <=20%.

So the key empirical signal from 01F is not merely “sample size too small.” It is:

```text
the frozen calibration-consistency mechanism
does not detect the frozen S09 misspecification strongly enough
within the entire candidate grid
```

No post-result threshold relaxation, scenario deletion, seed change, or N
extension is authorized inside 01F.

---

## 9. Non-blocking audit findings

### NB-01 — MCSE columns are not explicitly emitted

R2 states that continuous metrics should report:

```text
estimate
R
MCSE where applicable
confidence interval
```

`screening_metrics.csv` contains estimates and confidence bounds but no explicit
MCSE columns.

The MCSE is recoverable from the symmetric CI, and this omission does not affect
the zero-survivor outcome because every design independently hard-fails S09 using
a Wilson rate gate.

Recommendation: treat this as a reporting-completeness correction in the
post-execution record; do not rerun or alter scientific results merely to add the
column.

### NB-02 — Scientific constants are partially duplicated in source

Several thresholds and z cutoffs are hard-coded in the executor instead of being
read from the manifest. They match R2 in this execution, so no result discrepancy
was found.

Recommendation: future execution tooling should bind all scientific constants to
the manifest and keep only implementation mechanics in code.

### NB-03 — No replicate-level audit ledger supplied

The package contains aggregate results and deterministic source/seeding, but no
per-replicate output ledger. Therefore this review verifies code, hashes,
coverage, aggregate interval arithmetic, and exclusion reconstruction; it does
not independently replay all governed random draws.

A fresh external reviewer can either inspect the same deterministic contract or
perform an exact-runtime parity rerun if governance requires bit-level outcome
reproduction.

### NB-04 — `F_true` / `P_true` oracle construction is implicit rather than named as an explicit formula in R2

The executor defines the oracle true form/practice corrections from the Stage-2
population contrasts. That is a natural mirror of the frozen Stage-2 estimators,
but R2 names the oracle quantities without spelling out their exact population
formula.

This can affect the core bias diagnostics, but it does **not** affect the current
zero-survivor conclusion because all 49 designs are independently eliminated by
the S09 calibration-pass gate.

Recommendation: record this semantic clarification before any future protocol
that reuses these oracle bias metrics; do not retroactively change 01F.

---

## 10. Final second-party verdict

```text
GB-MEASURE-01F-EXEC
SECOND-PARTY DEEP VERIFICATION

EXECUTION INTEGRITY
= PASS

HASH / ARTIFACT INTEGRITY
= PASS

49 × 9 SCREENING COVERAGE
= PASS

HARD-SCREEN RECOMPUTATION
= PASS

ZERO-SURVIVOR CONCLUSION
= VERIFIED FROM SUPPLIED AGGREGATES

NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID
= SUPPORTED

FORMAL INDEPENDENT OUTCOME CLOSE
= STILL REQUIRED

mayAffectGameplay
= false
```

Recommended next gate:

```text
Fresh external/new-agent post-execution review
```

If that reviewer also passes the outcome, close `GB-MEASURE-01F-EXEC` with:

```text
NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID
```

Then any attempt to expand N, change S09, alter the consistency gate, or change
acceptance thresholds must be a **new prospective protocol/amendment**, with the
01F results treated as seen evidence.
