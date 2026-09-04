# CODEX EXECUTION PROMPT — GB-MEASURE-01F-EXEC

Repository:
`Strike87/math-challenge-flutter`

Required repository baseline:

```text
branch = research/gb-preview-01-full-text-extraction-02
HEAD   = 62e6dcfbe0d2eab51ec359b036b50bf7dd3d6e66
```

Supplied governing artifacts:

```text
gb_measure_01f_input_freeze_recovery_r2.md
gb_measure_01f_exec_manifest_v1_2.json
gb_measure_01f_r2_independent_review_pass.md
gb_measure_01f_exec_authorization_2026-09-04.md
```

Frozen manifest SHA-256:

```text
918ba80bccadea4f45807c6c3329c54389a769e1f15c0d39d3e6672a5af5d79e
```

Independent review:

```text
PASS / APPROVED_FOR_01F_EXEC
```

Protocol-owner authorization:

```text
APPROVED TO START GB-MEASURE-01F-EXEC
```

## Mission

Execute:

```text
GB-MEASURE-01F-EXEC
Monte Carlo Execution & Minimum Design Adjudication
```

strictly from the frozen R2/v1.2 package.

This is the first governed simulation execution. Do not alter the frozen scientific
design to make execution easier, faster, or more likely to pass.

---

# 0. NON-NEGOTIABLE AUTHORITY BOUNDARY

```text
mayAffectGameplay = false
```

Do NOT modify gameplay or production behavior.

Do NOT add or change capture, persistence, telemetry, GameBrain interpretation
authority, policy authority, or canonical gameplay authority.

Do NOT commit, push, stage, merge, or open a PR.

You MAY create:
- an isolated execution environment;
- research-only execution code;
- research-only tests;
- checkpoints;
- result tables/files;
- execution logs;
- hashes;
inside the working tree or a clearly isolated research-output directory.

Do NOT edit either frozen R2 governing artifact.

---

# 1. PRE-EXECUTION BASELINE AND INPUT FREEZE CHECK

Before generating any governed Monte Carlo output:

1. Verify branch exactly:
   `research/gb-preview-01-full-text-extraction-02`

2. Verify HEAD exactly:
   `62e6dcfbe0d2eab51ec359b036b50bf7dd3d6e66`

3. Report `git status --short`.

4. Treat pre-existing untracked governance inputs separately from production
   modifications. Do not delete or overwrite them.

5. Parse `gb_measure_01f_exec_manifest_v1_2.json`.

6. Compute its SHA-256 and require exact equality to:

```text
918ba80bccadea4f45807c6c3329c54389a769e1f15c0d39d3e6672a5af5d79e
```

7. Verify the Markdown declares the same manifest hash.

8. Verify the independent-review record says:
   `PASS / APPROVED_FOR_01F_EXEC`.

9. Verify the authorization record refers to the same manifest hash.

Any failure:

```text
GB_MEASURE_01F_EXEC_BLOCKED_PREFLIGHT
```

STOP. Do not simulate.

---

# 2. EXACT RUNTIME PREFLIGHT

The frozen governed runtime is:

```text
CPython = 3.13.5
NumPy   = 2.3.5
PRNG    = numpy.random.PCG64DXSM
```

Do NOT run governed simulation under Python 3.14.0 or any other version.

First enumerate available Python installations on the host (for Windows, include
`py -0p` if available).

Preferred execution setup:

```text
isolated venv
created from exact CPython 3.13.5
NumPy exactly 2.3.5
```

Do not silently install a different Python/NumPy and do not reinterpret the freeze.

If exact CPython 3.13.5 is not available:

```text
GB_MEASURE_01F_EXEC_BLOCKED_RUNTIME_UNAVAILABLE
```

Report the available runtimes and STOP before simulation.

If Python 3.13.5 exists but NumPy 2.3.5 is absent, it is acceptable to install
**exactly NumPy 2.3.5 into the isolated venv**, provided package installation
succeeds without changing the frozen protocol or project dependencies.

Before simulation, print and record:

```text
sys.implementation.name
platform.python_version()
numpy.__version__
numpy.random.PCG64DXSM
manifest SHA-256
seed namespace
```

Any mismatch must fail closed.

---

# 3. IMPLEMENTATION LOCATION AND ISOLATION

Use a research-only implementation. Prefer a bounded structure such as:

```text
research/game_brain/gb_measure_01f/
    gb_measure_01f_exec.py
    gb_measure_01f_model.py
    gb_measure_01f_metrics.py
    gb_measure_01f_io.py
    tests/
```

and results under:

```text
research/game_brain/gb_measure_01f/results/<execution_id>/
```

If the repository has a stronger existing research-layout convention, follow it,
but do not touch gameplay/production code.

All implementation must consume the frozen manifest as input rather than
duplicating scientific constants across source files where avoidable.

---

# 4. IMPLEMENTATION VALIDATION BEFORE GOVERNED OUTPUT

Before the real Monte Carlo run, test implementation mechanics without inspecting
reduced-R results from the frozen S01-S09 design grid.

Allowed pre-execution checks include:

- JSON/schema parsing;
- exact 49-design expansion and frozen ordering;
- canonical design IDs;
- seed-key golden tests;
- component-substream independence tests;
- AB/BA parity tests;
- hand-calculated estimator tests;
- hand-calculated variance/covariance sign tests;
- Wilson interval implementation tests;
- continuous MC-CI formula tests;
- deterministic replay of fixed RNG draws;
- complete-data fail-closed tests;
- malformed/non-finite replicate classification tests.

Do NOT run a “small pilot” such as R=10/100/1000 on the governed S01-S09 grid and
inspect operating-characteristic results before the frozen execution.

Do NOT tune code/thresholds based on preliminary scientific results.

---

# 5. EXECUTE THE FROZEN DGM EXACTLY

Implement the binary DGM, scenarios S01-S09, estimators, decision cohort,
complete-data-only rule, variance/covariance model, and invalid-replication
handling exactly as frozen in R2.

Critical regression points:

```text
one independent decision pair per replicate
decision pair excluded from calibration estimation

even replicate_index -> AB
odd  replicate_index -> BA

D_observed_AB = B_occ2 - A_occ1
D_observed_BA = A_occ2 - B_occ1

D_adj = D_observed - orientation_sign*F_hat - P_hat

V_adj_hat
= VD_hat + VF_hat + VP_hat
  + 2*orientation_sign*CFP_hat

SE_adj_hat = sqrt(V_adj_hat)

Z_change = D_adj / SE_adj_hat
```

The target decision pair must remain independent of Stage 1 and Stage 2
calibration participants.

Sensitivity `true_change_logit` applies only to target occasion 2, exactly as
frozen.

No missingness/censoring process is allowed.

---

# 6. RNG / STREAM CONTRACT

Use only the frozen contract:

```text
numpy.random.Generator(numpy.random.PCG64DXSM(component_seed))
```

with:

```text
SHA-256
namespace = GBM01F_EXEC_V1_20260904
0-based replicate_index
frozen design_id
frozen shift_token
frozen component labels
```

Respect the exact component draw order in R2.

No:
- global RNG;
- OS entropy;
- wall-clock seed;
- Python `random`;
- implicit `default_rng`;
- executor-selected substreams.

Parallel execution is allowed because streams are component/replicate keyed, but
aggregation/output ordering must be deterministic and sorted by the frozen
design/scenario/replicate identities.

Worker count is an engineering/runtime parameter only; it must not enter the RNG
or scientific results.

---

# 7. ORACLE PHASE

Run exactly:

```text
R_oracle = 1,000,000
```

for every frozen scenario.

Produce the required oracle population moments:

```text
Stage-1 score variance Form A
Stage-1 score variance Form B
Var(d_AB)
Var(d_BA)
true form correction
true practice correction
```

Then construct `SE_adj_reference` for every candidate design and target
orientation using the frozen R1/R2 variance functional.

Oracle streams must be independent from screen/confirm streams.

Do not change `R_oracle`.

---

# 8. SCREENING PHASE

Run exactly:

```text
R_screen = 3,000
```

for every:

```text
49 candidate designs × S01-S09
```

Screening can NEVER pass a design.

A design can be excluded before confirmatory execution only if the frozen
**99% Monte Carlo interval** for at least one gating metric lies wholly on the
failing side of its frozen threshold.

Record every hard-screen-fail metric/reason.

If a design does not meet that strict hard-fail condition, it survives to
confirmatory execution.

No informal “obviously bad” exclusion.

---

# 9. CONFIRMATORY PHASE

For every screening survivor, run exactly:

```text
R_confirm = 20,000
```

for every required scenario.

No early PASS.

Apply all S01-S08 gates and S09 sentinel gates exactly as frozen.

Invalid/numerical-failure replications:
- remain in the all-attempted denominator;
- count toward the frozen indeterminate/numerical-failure rate;
- are never silently dropped, repaired, or rerun with another seed.

Do not replace a failed replicate with a new replicate.

---

# 10. NON-GATING SENSITIVITY / FNR PHASE

For confirmatorily evaluated designs, S01-S08 only, execute each frozen target
change:

```text
-0.50
-0.25
+0.25
+0.50
```

using:

```text
R = R_confirm
```

per:

```text
design × core scenario × true-change shift
```

Report:

```text
directional power
false-negative rate
wrong-direction rate
indeterminate rate
```

These metrics are descriptive only.

They MUST NOT:
- select N;
- rescue a failing design;
- remove a passing design;
- change the minimum-design ordering.

---

# 11. WORST-CASE ADJUDICATION

A design passes only if:

```text
all gates pass in every S01-S08
AND
S09 safety gates pass
```

No averaging across scenarios.

Then sort passing designs using the exact frozen ordering:

```text
1. total_response_burden = 36*n1 + 72*n2
2. total_participants    = 2*n1 + 2*n2
3. repeated participants = 2*n2
4. n1
5. lexicographic design_id
```

Select the first passing design.

If none passes, output exactly:

```text
NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID
```

Do NOT:
- add a larger N;
- interpolate;
- extrapolate;
- loosen a threshold;
- drop a scenario;
- rerun under a new seed namespace.

---

# 12. REQUIRED EXECUTION OUTPUTS

Emit at minimum all outputs required by R2:

```text
expanded 49-design table in frozen order
oracle table by scenario
screening metrics + MC uncertainty
hard-screen-fail reasons
confirmatory metrics + MC uncertainty
minimum passing design OR NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID
selected Stage-1 n per form
selected Stage-2 n per order and total
total participants
total item-response burden
all failed-design reasons
S09 sentinel result
non-gating FNR/power table
decision-pair AB/BA counts
VD_hat
VF_hat
VP_hat
CFP_hat
V_adj_hat
SE_adj_hat
software/runtime versions
manifest SHA-256
seed namespace/derivation
execution timestamps
code hash
result-file hashes
```

Recommended machine-readable outputs:

```text
execution_manifest.json
design_grid.csv
oracle_by_scenario.csv
screening_metrics.csv
screening_exclusions.csv
confirmatory_metrics.csv
design_adjudication.csv
s09_sentinel.csv
sensitivity_power_fnr.csv
variance_diagnostics.csv
result_hashes.json
```

Recommended human report:

```text
gb_measure_01f_exec_report.md
```

These filenames are organizational only; do not alter the scientific contents.

---

# 13. EXECUTION INTEGRITY / CHECKPOINTS

Because this may be long-running, checkpointing/resume is permitted only if:

- every result row is keyed by frozen phase/design/scenario/shift/replicate;
- checkpoint metadata includes manifest hash, code hash, runtime versions and seed namespace;
- resume refuses any metadata mismatch;
- already completed frozen replicate identities are not redefined or replaced;
- outcome-dependent stopping is impossible except the frozen screening hard-fail rule;
- final aggregation is deterministic.

Do not use checkpointing to alter R.

---

# 14. FINAL SELF-CHECK

After execution, perform a non-independent executor self-check:

- all required phases completed or explicitly hard-screen-excluded;
- all expected candidate/scenario cells accounted for;
- AB/BA parity counts correct;
- no duplicate replicate identities;
- no missing attempted-replicate denominator rows;
- all hashes generated;
- manifest unchanged;
- production/gameplay untouched;
- `mayAffectGameplay=false`.

Run `git diff --check` and `git status --short`.

Do not call your own execution review “independent”.

---

# 15. FINAL RESPONSE FORMAT

Start with one of:

```text
GB_MEASURE_01F_EXEC_COMPLETE
GB_MEASURE_01F_EXEC_BLOCKED_PREFLIGHT
GB_MEASURE_01F_EXEC_BLOCKED_RUNTIME_UNAVAILABLE
GB_MEASURE_01F_EXEC_FAILED
```

If complete, report:

1. baseline and exact runtime;
2. frozen manifest hash;
3. code hash;
4. oracle completion;
5. screening completion and survivor count;
6. confirmatory completion;
7. selected minimum design OR `NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID`;
8. exact selected N/burden if one passes;
9. S09 result;
10. sensitivity table location;
11. every output file + SHA-256;
12. final git status;
13. explicit statement:
   `no gameplay/production authority changed; mayAffectGameplay=false`;
14. explicit statement:
   `independent post-execution outcome review still required`.

Do not commit or push.

STOP after reporting execution and artifacts.
