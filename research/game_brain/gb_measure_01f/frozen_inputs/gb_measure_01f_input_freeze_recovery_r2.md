# GB-MEASURE-01F-INPUT-FREEZE-RECOVERY

**Protocol ID:** `GB-MEASURE-01F-INPUT-FREEZE-RECOVERY`  
**Version:** `1.2`  
**Target execution:** `GB-MEASURE-01F-EXEC — Monte Carlo Execution & Minimum Design Adjudication`  
**Status:** `FROZEN_BY_PROTOCOL_OWNER / PENDING FRESH R2 INDEPENDENT APPROVAL`  
**Machine manifest:** `gb_measure_01f_exec_manifest_v1_2.json`  
**Manifest SHA-256:** `918ba80bccadea4f45807c6c3329c54389a769e1f15c0d39d3e6672a5af5d79e`

---

## 1. Recovery purpose

The attempted `01F-EXEC` correctly stopped because the repository had no governing
`GB-MEASURE-01`, `01A–01F`, or `01D-ACCEPT` artifacts and therefore no frozen
simulation inputs.

This package prospectively freezes those missing inputs **before any simulation
result is seen**. It does not claim that the exact numeric values below were
previously present in the repository. Where a value was missing, it is explicitly
a new project-local preregistered simulation choice.

No production behavior, gameplay authority, capture, telemetry, or persistence is
authorized.

```text
mayAffectGameplay = false
```


### 1.1 Prospective R1 correction record

A fresh independent pre-execution review returned `REQUIRED_CHANGES` for exactly
two blocking defects. R1 is a prospective correction because no `01F-EXEC` output
has been generated or inspected.

```text
RC-1  Define D_observed and the decision population explicitly.
RC-2  Include calibration-estimation uncertainty and Cov(F_hat, P_hat)
      in the variance used to standardize D_adj.
```

R1 does **not** change:

```text
K
Stage-1 or Stage-2 candidate N grids
R_oracle / R_screen / R_confirm
seed namespace
S01-S09 numeric scenario values
alpha reference cutoff
acceptance thresholds
minimum-design ordering
worst-case rule
mayAffectGameplay
```

---


### 1.2 Prospective R2 correction record

A fresh independent R1 review verified that RC-1 and RC-2 were resolved, but
returned `REQUIRED_CHANGES` for exactly two remaining execution-input gaps:

```text
RC-3  Freeze missingness/censoring scope.
RC-4  Freeze the executable RNG implementation and independent random-stream
      partitioning.
```

R2 is prospective because no `01F-EXEC` simulation has been run and no simulation
output has been generated or inspected.

R2 freezes:

```text
simulation data completeness = COMPLETE_DATA_ONLY
missingness/censoring model  = OUT_OF_SCOPE_FOR_01F_V1_2
CPython                      = 3.13.5
NumPy                        = 2.3.5
PRNG                         = PCG64DXSM
normal draws                 = numpy.random.Generator.normal
binomial draws               = numpy.random.Generator.binomial
component-specific streams   = REQUIRED
```

R2 does **not** change:

```text
K
Stage-1 or Stage-2 candidate N grids
R_oracle / R_screen / R_confirm
seed namespace
S01-S09 numeric scenario values
alpha reference cutoff
acceptance thresholds
minimum-design ordering
worst-case rule
mayAffectGameplay
```

The seed namespace is unchanged. The seed derivation is prospectively extended
only to freeze the previously unspecified component substreams and sensitivity
shift token.

## 2. Scientific claim boundary

Target claim:

> **Reliable improvement in bounded measured performance under one frozen
> MeasurementSpec.**

Not authorized:

```text
durable learning
mastery
mathematical ability
motivation
cognitive load
productive struggle
diagnosis
gameplay recommendation
```

The evidence basis requires repeated comparable measurement plus a reliability /
measurement-error model; raw `recent > earlier` is insufficient, and practice /
retest effects may matter.

---

## 3. Measurement cell

```text
GBM01-CELL-01

Operation             = Multiplication
NumberType            = Natural
ExecutedDifficulty    = Medium
DifficultyProvenance  = playerConfigured
Mode                   = Standard / 1P
Timing                 = Per Question
AnswerStyle            = Choice4
Assistance             = None
ExposureOrigin         = Natural
Adaptive               = OFF
Targeted Repetition    = EXCLUDED
Replay-derived         = EXCLUDED
```

A different context requires a different MeasurementSpec/version.

---

## 4. Candidate alternate measurement forms

```text
GBM01-FORM-A-v1
GBM01-FORM-B-v1
```

Each form has exactly **18** eligible items:

```text
6 direct
6 missing-left
6 missing-right
```

Exact canonical item identity overlap between A and B:

```text
0
```

Terminology is deliberately:

```text
CANDIDATE ALTERNATE MEASUREMENT FORMS
```

not validated “parallel forms”.

`18` is a bounded project-local structural/burden choice, not a universal
psychometric minimum.

---

## 5. Calibration design grid

### Stage 1 — randomized form-equivalence calibration

Independent participants receive one form.

```text
A : B = 1 : 1
```

Frozen `n per form` grid:

```text
50
75
100
150
200
300
400
```

### Stage 2 — counterbalanced alternate-form retest

Independent from Stage 1.

```text
AB : BA = 1 : 1
```

Frozen `n per order` grid:

```text
25
40
50
75
100
150
200
```

Stage-2 total participants are therefore:

```text
50
80
100
150
200
300
400
```

Total candidate designs:

```text
7 × 7 = 49
```

No N is preselected as the winner.

---

## 6. Binary-score generating model

For participant `p`, form `f`, occasion `o`:

```text
score_pfo ~ Binomial(K = 18, p_pfo) / 18
```

with:

```text
logit(p_pfo)
=
logit(p_ref)
+ theta_p
+ u_pf
+ v_po
+ form_shift_f
+ practice_shift * I(occasion = 2)
+ form_second_interaction * I(form = B and occasion = 2)
```

Random effects:

```text
theta_p ~ Normal(0, person_sd²)

u_pf ~ Normal(0, person_by_form_sd²)

v_po ~ Normal(0, person_by_occasion_sd²)
```

This is a **simulation sensitivity model**, not an empirical claim that real Math
Challenge item responses are iid Bernoulli trials.

---


## 6.1 Complete-data-only simulation scope

For `GB-MEASURE-01F-EXEC` v1.2:

```text
SIMULATION DATA SCOPE
= COMPLETE_DATA_ONLY

missingness model
= OUT OF SCOPE

censoring model
= OUT OF SCOPE
```

Every generated Monte Carlo replicate must contain:

```text
complete finite Stage-1 scores for every assigned participant
complete finite two-score Stage-2 pairs for every AB/BA participant
one complete finite two-score independent target decision pair
```

The executor must **not** introduce:

```text
dropout
item nonresponse
administrative censoring
timeout censoring
truncation
partial repeated-measure pairs
imputation
pairwise deletion
complete-case subsampling
```

No incomplete pair enters calibration or decision estimation because incomplete
pairs are not part of the frozen v1.2 DGM.

If any required score cannot be generated as a finite bounded score from the frozen
DGM, the entire Monte Carlo replicate is:

```text
INDETERMINATE / NUMERICAL FAILURE
```

It remains in every applicable all-attempted-replications denominator and is never
silently repaired, imputed, or dropped.

A future missingness/censoring sensitivity analysis requires a **new prospective
protocol version** that freezes the missingness/censoring mechanism, rates,
dependence structure, handling, and acceptance/reporting rules before outputs are
seen.

## 7. Frozen scenarios

The numeric values are **project-local stress-test inputs**, not claimed real-player
population parameters.

| ID | Class | p_ref | person SD | p×form SD | p×occasion SD | B−A shift (logit) | practice (logit) | B-second interaction |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| S01 | core valid | .70 | .75 | .10 | .10 | .00 | .00 | .00 |
| S02 | core valid | .70 | .75 | .10 | .10 | .00 | .15 | .00 |
| S03 | core valid | .50 | .75 | .10 | .10 | .00 | .15 | .00 |
| S04 | core valid | .85 | .75 | .10 | .10 | .00 | .15 | .00 |
| S05 | core valid | .70 | .75 | .10 | .10 | .20 | .15 | .00 |
| S06 | core valid | .70 | .75 | .30 | .10 | .20 | .15 | .00 |
| S07 | core valid | .70 | .75 | .10 | .30 | .20 | .15 | .00 |
| S08 | core valid | .70 | .75 | .30 | .30 | .20 | .20 | .00 |
| S09 | misspecification sentinel | .70 | .75 | .20 | .20 | .20 | .15 | .25 |

S09 is intentionally outside the valid calibration model. It tests whether an
unmodeled form×second-occasion interaction fails closed instead of being silently
converted into “reliable change”.

---

## 8. Frozen calibration estimators

### Stage-1 form effect

```text
F1_hat = mean(B_stage1) - mean(A_stage1)

SE(F1_hat)
=
sqrt( var(A)/n1 + var(B)/n1 )
```

### Stage-2 contrasts

```text
d_AB = B_occ2 - A_occ1
d_BA = A_occ2 - B_occ1
```

Then:

```text
F2_hat
=
[ mean(d_AB) - mean(d_BA) ] / 2

P_hat
=
[ mean(d_AB) + mean(d_BA) ] / 2
```

`P_hat` is the bounded average second-occasion practice/retest correction.

### Form-consistency gate

```text
Z_form
=
(F1_hat - F2_hat)
/
sqrt( SE(F1_hat)^2 + SE(F2_hat)^2 )
```

Freeze:

```text
|Z_form| <= 2.5758293035489004
```

Failure:

```text
CALIBRATION = INDETERMINATE
```

not coercion into a valid receipt.

### Stage-2 estimator variance/covariance

Let:

```text
s_AB^2 = sample variance of d_AB
s_BA^2 = sample variance of d_BA

V1_hat
= var(score_A_stage1)/n1 + var(score_B_stage1)/n1

V2_hat
= .25 * (s_AB^2/n2 + s_BA^2/n2)

VP_hat
= Var_hat(P_hat)
= V2_hat

C2P_hat
= Cov_hat(F2_hat, P_hat)
= .25 * (s_AB^2/n2 - s_BA^2/n2)
```

Stage 1 and Stage 2 use independent participants.

### Combined form correction

Only after consistency passes:

```text
w1 = 1 / V1_hat
w2 = 1 / V2_hat

lambda1 = w1 / (w1 + w2)
lambda2 = w2 / (w1 + w2)

F_hat
= lambda1 * F1_hat
+ lambda2 * F2_hat
```

Frozen plug-in uncertainty:

```text
VF_hat
= Var_hat(F_hat)
= lambda1^2 * V1_hat
+ lambda2^2 * V2_hat

CFP_hat
= Cov_hat(F_hat, P_hat)
= lambda2 * C2P_hat
```

The covariance is not assumed zero merely because Stage 1 is independent: `F_hat`
contains `F2_hat`, and `F2_hat` and `P_hat` are constructed from the same Stage-2
order-group means.

### Independent target decision-pair variance

For a target decision pair with frozen order:

```text
VD_hat(AB) = s_AB^2
VD_hat(BA) = s_BA^2
```

This estimates the variance of one independent repeated-measure decision pair under
the corresponding order. The former pooled `SE_change_hat` is **not** the final
standard error for `D_adj`, because `D_adj` also subtracts estimated calibration
corrections.

---

## 9. Independent decision population and reliable-change criterion

### 9.1 One independent decision pair per Monte Carlo replicate

Each Monte Carlo replicate contains exactly **one target decision participant** in
addition to the Stage-1 and Stage-2 calibration participants.

The target participant is:

```text
independent of every calibration participant
EXCLUDED from F1_hat, F2_hat, P_hat, all calibration variances, and consistency gates
used only to produce the one D_observed adjudicated in that replicate

The target scores are generated from the same frozen scenario DGM with fresh target-participant random effects and binomial draws independent of all calibration draws.

The F_hat, P_hat, and variance/covariance estimates applied to that target are the estimates from the same Monte Carlo replicate calibration sample.

The target pair is an operating-characteristic probe only: it is not added to candidate calibration participant counts or minimum-design response burden.
```

Order allocation is exactly balanced within every frozen even-sized phase:

```text
replicate_index is 0-based within phase

even replicate_index -> AB
odd  replicate_index -> BA
```

Therefore:

```text
D_observed(AB) = score_B_occ2 - score_A_occ1
D_observed(BA) = score_A_occ2 - score_B_occ1
```

For null false-positive execution:

```text
true_change_logit = 0
```

For non-gating sensitivity execution, the listed latent true-change shift is added
only to the target participant's second-occasion linear predictor:

```text
eta_target
= frozen scenario eta
+ true_change_logit * I(occasion = 2)
```

The scenario's practice shift, form shift, and S09 form-second interaction remain
active. Sensitivity true change is **not** injected into Stage-1 or Stage-2
calibration samples.

### 9.2 Adjusted change

Orientation:

```text
orientation_sign =
+1 for AB
-1 for BA
```

Adjusted change:

```text
D_adj
=
D_observed
- orientation_sign * F_hat
- P_hat
```

Because the decision pair is independent from both calibration stages:

```text
Cov(D_observed, F_hat) = 0
Cov(D_observed, P_hat) = 0
```

But `Cov(F_hat, P_hat)` is generally non-zero. Therefore the frozen full plug-in
variance is:

```text
V_adj_hat
= VD_hat
+ VF_hat
+ VP_hat
+ 2 * orientation_sign * CFP_hat

SE_adj_hat
= sqrt(V_adj_hat)
```

Standardized change:

```text
Z_change
=
D_adj / SE_adj_hat
```

If any required variance, inverse-variance weight, covariance, `V_adj_hat`, or
`SE_adj_hat` is non-finite; if `V1_hat <= 0`; if `V2_hat <= 0`; or if
`V_adj_hat <= 0`, the replicate is:

```text
INDETERMINATE / NUMERICAL FAILURE
```

and is never silently removed from its Monte Carlo denominator.

Frozen two-sided reference criterion:

```text
alpha_reference = .05
z* = 1.959963984540054
```

This is a **nominal normal-reference cutoff**. R1 does not claim exact finite-sample
`.05` control from the z cutoff alone. Actual operating false-positive behavior is
adjudicated by the already frozen Monte Carlo false-reliable-change acceptance gate.

Decision:

```text
Z_change >= +z*
→ RELIABLE_INCREASE_SUPPORTED

Z_change <= -z*
→ RELIABLE_DECREASE_SUPPORTED

otherwise
→ NO_RELIABLE_CHANGE_ESTABLISHED
```

Any failed/missing MeasurementSpec, comparability, calibration-integrity,
scope-binding, receipt-lineage, or measurement-model gate yields:

```text
INDETERMINATE
```

This is a statistical error-control criterion only. It is not a mastery,
learning, gameplay, or clinical-significance threshold.

---

## 10. Oracle simulation

For each scenario:

```text
R_oracle = 1,000,000
```

The oracle estimates the scenario population moments required by the frozen R1
variance functional:

```text
Stage-1 score variance for Form A
Stage-1 score variance for Form B
Var(d_AB)
Var(d_BA)
true form correction
true practice correction
```

For each candidate design and each target orientation, the executor substitutes
those oracle population moments into the same frozen variance/covariance algebra to
obtain the design-reference `SE_adj_reference`. This reference includes the
calibration-estimation variance of `F_hat` and `P_hat` and their covariance.

Finite-sample randomness caused by estimating the inverse-variance weights is not
assumed to disappear; it remains part of the end-to-end Monte Carlo operating
behavior and is directly policed by the false-positive gate.

Oracle random streams are independent from screening and confirmatory streams.

---

## 11. Monte Carlo execution plan

### Screening

```text
R_screen = 3,000
```

for every candidate design × scenario.

Screening can never PASS a design.

A design may be excluded before confirmatory execution only when a **99% Monte
Carlo interval** for at least one gating metric lies wholly on the failing side
of the frozen threshold.

### Confirmatory

```text
R_confirm = 20,000
```

per candidate design × required scenario.

No early PASS.

At a true false-positive rate near `.05`, `20,000` replications gives Monte Carlo
SE ≈ `.00154`.

---

## 12. Deterministic random streams and executable RNG contract

Frozen namespace:

```text
GBM01F_EXEC_V1_20260904
```

### 12.1 Required runtime and PRNG

Exact governed execution must use:

```text
Python implementation = CPython
Python version        = 3.13.5
NumPy version         = 2.3.5

PRNG
= numpy.random.PCG64DXSM

Generator
= numpy.random.Generator(numpy.random.PCG64DXSM(seed))

Normal draws
= numpy.random.Generator.normal

Binomial draws
= numpy.random.Generator.binomial
```

The frozen binomial count is:

```text
K = 18
```

A different CPython or NumPy version is not an execution-equivalent implementation
for this freeze. It requires a prospective amendment and fresh independent review
before governed execution.

### 12.2 Canonical design and shift tokens

Candidate design ID:

```text
GBM01-N1-{n_stage1_per_form:03d}-N2-{n_stage2_per_order:03d}
```

Examples:

```text
GBM01-N1-050-N2-025
GBM01-N1-400-N2-200
```

Oracle design token:

```text
ORACLE
```

True-change token:

```text
oracle / screen / confirm
→ TC_NULL

sensitivity_false_negative
→ TC_{true_change_logit:+0.6f}
```

Therefore the four frozen sensitivity tokens are:

```text
TC_-0.500000
TC_-0.250000
TC_+0.250000
TC_+0.500000
```

R2 intentionally does **not** use common random numbers across sensitivity shifts.

### 12.3 Replicate and component seed derivation

For screen, confirm, and sensitivity:

```text
replicate_index
= 0-based within phase
```

For oracle:

```text
replicate_index
= 0 ... R_oracle-1
```

Canonical seed key:

```text
{namespace}|{phase}|{design_id}|{scenario_id}|{shift_token}|{replicate_index}|{component}
```

Component seed:

```python
component_seed = int.from_bytes(
    sha256(
        (
            f"{namespace}|{phase}|{design_id}|{scenario_id}|"
            f"{shift_token}|{replicate_index}|{component}"
        ).encode("utf-8")
    ).digest()[:8],
    "big",
) & 0x7fffffffffffffff
```

Every component constructs its own:

```python
rng = numpy.random.Generator(
    numpy.random.PCG64DXSM(component_seed)
)
```

Frozen component labels:

```text
stage1_A
stage1_B
stage2_AB
stage2_BA
decision_AB
decision_BA
```

Only the target component matching the frozen replicate-parity order is used:

```text
even replicate_index → decision_AB
odd  replicate_index → decision_BA
```

Because components are independently keyed, changing the execution order of
Stage 1, Stage 2, or the decision pair—or parallelizing those components—must not
change another component's random stream.

No global RNG state is permitted.

### 12.4 Frozen draw sequence inside each component

Within a component, the following NumPy call order is part of the freeze.

Stage-1 A or B, vector length `n1`:

```text
1. theta
   rng.normal(0, person_sd, size=n1)

2. assigned-form u
   rng.normal(0, person_by_form_sd, size=n1)

3. occasion-1 v
   rng.normal(0, person_by_occasion_sd, size=n1)

4. compute p from the frozen eta

5. score count
   rng.binomial(18, p, size=n1)

6. score = count / 18
```

Stage-2 AB, vector length `n2`:

```text
1. theta
2. u_A
3. u_B
4. v_occ1
5. v_occ2
6. A-occ1 binomial count
7. B-occ2 binomial count
```

Stage-2 BA, vector length `n2`:

```text
1. theta
2. u_A
3. u_B
4. v_occ1
5. v_occ2
6. B-occ1 binomial count
7. A-occ2 binomial count
```

For both Stage-2 orders, steps 1–5 use `rng.normal` with their frozen standard
deviations and `size=n2`; steps 6–7 use `rng.binomial(18, p, size=n2)` after the
corresponding frozen eta is converted through the logistic function.

Independent target decision pair:

```text
1. theta
2. u_A
3. u_B
4. v_occ1
5. v_occ2
6. first-form / occasion-1 binomial count
7. second-form / occasion-2 binomial count
```

The target uses scalar calls and the same DGM; the second-occasion eta receives the
frozen sensitivity `true_change_logit` only in
`sensitivity_false_negative`.

### 12.5 No unfrozen randomness

Forbidden:

```text
OS entropy
wall-clock seeds
implicit/default NumPy RNG construction
Python random module
hand-edited seed lists
executor-selected PRNG
executor-selected distribution implementation
executor-selected component partition
shared mutable global RNG state
```

All governed execution must report the actual:

```text
CPython version
NumPy version
PCG64DXSM declaration
seed namespace
seed-key format
```

and must fail closed before simulation if they do not match this freeze.


## 13. Core confirmatory acceptance gates — S01 through S08

A design must satisfy **all** gates in **every** core scenario.

### A. Null false reliable-change control

Under true no change:

```text
upper 95% Wilson bound
<= .060
```

for any false reliable-change decision.

Report false increase and false decrease separately.

### B. Calibration indeterminate / numerical failure

```text
upper 95% Wilson bound
<= .050
```

Invalid replications are counted here and never silently dropped.

### C. `SE_adj` signed relative bias

```text
r
=
(SE_adj_hat - SE_adj_reference)
/
SE_adj_reference
```

The 95% Monte Carlo CI for `mean(r)` must lie entirely inside:

```text
[-.050, +.050]
```

### D. `SE_adj` mean absolute relative error

```text
a
=
abs(SE_adj_hat - SE_adj_reference)
/
SE_adj_reference
```

Upper 95% Monte Carlo bound for `mean(a)`:

```text
<= .100
```

### E. Form-correction bias

```text
(F_hat - F_true) / SE_adj_reference
```

Upper 95% confidence bound for absolute mean bias:

```text
<= .100
```

### F. Practice-correction bias

```text
(P_hat - P_true) / SE_adj_reference
```

Upper 95% confidence bound for absolute mean bias:

```text
<= .100
```

These numeric tolerances are project-local preregistered acceptance choices.

---

## 14. S09 misspecification-sentinel gates

Required:

```text
upper 95% Wilson bound
of CALIBRATION_PASS rate
<= .200
```

and:

```text
upper 95% Wilson bound
of overall false reliable-change rate
<= .060
```

The intended behavior is fail-closed / indeterminate under material model
misspecification.

---

## 15. False-negative / power reporting

There is no validated Math Challenge smallest meaningful change (`SESOI`).

Therefore power/FNR **must not choose N**.

Report only, for latent logit changes:

```text
-.50
-.25
+.25
+.50
```

Metrics:

```text
directional power
false-negative rate
wrong-direction rate
indeterminate rate
```

They are descriptive sensitivity outputs, not gating outputs.

Frozen sensitivity population:

```text
one independent decision pair per replicate
AB/BA balanced by the same replicate-parity rule
calibration samples remain null with respect to true_change_logit
true_change_logit applies to decision occasion 2 only
scenario scope = S01-S08 only
S09 = excluded from sensitivity/power; it remains the misspecification sentinel
R = R_confirm per confirmatorily evaluated design x core scenario x true-change shift
```

The denominator for each sensitivity rate is all attempted sensitivity replications
for that design/scenario/shift; indeterminate/numerical-failure replications remain
in the denominator.

---

## 16. Monte Carlo uncertainty

For rates:

```text
Wilson confidence interval
```

For continuous across-replication means:

```text
MCSE = sample SD / sqrt(R)

95% MC CI
=
mean ± 1.96 * MCSE
```

Screening uses the corresponding 99% bounds.

Every metric must report:

```text
estimate
R
MCSE where applicable
confidence interval
```

---

## 17. Frozen minimum-design ordering

With `K = 18`:

```text
Stage-1 response burden = 36 * n1
Stage-2 response burden = 72 * n2
```

where:

```text
n1 = Stage-1 participants per form
n2 = Stage-2 participants per order
```

Sort the 49 designs by:

```text
1. ascending total_response_burden
   = 36*n1 + 72*n2

2. ascending total_participants
   = 2*n1 + 2*n2

3. ascending repeated_measurement_participants
   = 2*n2

4. ascending n1

5. lexicographic design_id
```

The first confirmatorily passing design in this order is the selected minimum.

---

## 18. Worst-case rule

No averaging across scenarios.

```text
PASS
=
all gates pass in S01–S08
AND S09 safety gates pass
```

If none passes:

```text
NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID
```

Then do **not**:

```text
interpolate
extrapolate a larger N
loosen tolerances
drop a difficult scenario
```

Any amendment becomes a new prospective protocol version and must use fresh
simulation streams.

---

## 19. Required `01F-EXEC` outputs

Codex must emit:

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
R1 variance components: VD_hat, VF_hat, VP_hat, CFP_hat, V_adj_hat, SE_adj_hat
software/runtime versions
manifest SHA-256
seed namespace/derivation
execution timestamps
code hash
result-file hashes
```

No execution artifact may silently modify the manifest.

---

## 20. Governance

```text
Protocol Owner R1 freeze
= COMPLETE

Independent Protocol Approval
= REQUIRED BEFORE 01F-EXEC

Executor
= MUST NOT EDIT FROZEN INPUTS

Independent Outcome Review
= REQUIRED WHERE FEASIBLE
```

This recovery package was authored in this conversation, so its author does not
self-label the review as independent.

Independent pre-execution verdict must be exactly one of:

```text
PASS / APPROVED_FOR_01F_EXEC
REQUIRED_CHANGES
```

R2 is v1.2 prospectively because no `01F-EXEC` output has yet been seen. A fresh independent R2 pre-execution review is required before execution.

---

## 21. Source-supported principles vs project-local values

### Source-supported methodological principles

The source record supports:

- reliable change must account for measurement variability;
- comparable repeated measurement and a reliability/error model are required;
- practice/retest effects can matter;
- reliable-change computation options must be explicitly documented;
- Generalizability Theory is useful where multiple measurement-error sources
  matter;
- reliability/SEM precision depends on design rather than one universal N;
- simulation studies should justify replications through Monte Carlo error and
  report simulation uncertainty;
- bounded/discrete scores can behave differently from ordinary linear-score
  assumptions.

### Project-local preregistered values

Not claimed universal:

```text
18 items/form
the Stage-1 and Stage-2 N grids
S01–S09 numeric parameter values
.060 false-positive tolerance
.050 indeterminate/failure tolerance
±5% signed SE_change bias tolerance
10% mean absolute SE_change error tolerance
10% normalized form/practice bias tolerances
S09 calibration-pass ceiling .200
```

These are tested, not assumed valid.

---

## 22. Bibliographic anchors

- Zahra, Hedge, Pesola, & Burr (2016), *Accounting for test reliability in
  student progression: the reliable change index*. Medical Education.
  DOI `10.1111/medu.13059`.

- Blampied (2022), *Reliable change and the reliable change index: still useful
  after all these years?* DOI `10.1017/S1754470X22000484`.

- Alkharusi (2011), *Generalizability Theory: An Analysis of Variance Approach
  to Measurement Problems in Educational Assessment*.

- Vispoel, Morris, & Kilinc (2017/2018), Generalizability-theory applications
  for multiple error sources and changes to measurement procedures.

- Briesch, Chafouleas, & Johnson (2016), *Use of Generalizability Theory Within
  K–12 School-Based Assessment*.

- Mokkink, de Vet, Diemeer, & Eekhout (2022), *Sample size recommendations for
  studies on reliability and measurement error: an online application based on
  simulation studies*. DOI `10.1007/s10742-022-00293-9`.

- Koehler, Brown, & Haneuse (2009), *On the Assessment of Monte Carlo Error in
  Simulation-Based Statistical Analyses*. DOI `10.1198/TAST.2009.0030`.

- Mundform et al. (2011), *Number of Replications Required in Monte Carlo
  Simulation Studies*. DOI `10.22237/JMASM/1304222580`.

- de Andrade Moral, Diaz-Orueta, & Oltra-Cucarella (2022), *Logistic versus
  linear regression-based reliable change index: A simulation study with
  implications for clinical studies with different sample sizes*.
  DOI `10.1037/pas0001138`.

---

## 23. Current status

```text
GB-MEASURE-01F-INPUT-FREEZE-RECOVERY-R2
= AUTHORED / PROSPECTIVELY FROZEN BY PROTOCOL OWNER

R1 CORRECTION SCOPE
= RC-1 + RC-2 COMPLETE / INDEPENDENTLY RE-REVIEWED AS RESOLVED

R2 CORRECTION SCOPE
= RC-3 + RC-4 COMPLETE

SIMULATION RUN
= NOT STARTED

SIMULATION OUTPUTS SEEN
= NO

FRESH INDEPENDENT R2 APPROVAL
= PENDING

01F-EXEC
= BLOCKED PENDING FRESH INDEPENDENT R2 APPROVAL
```
