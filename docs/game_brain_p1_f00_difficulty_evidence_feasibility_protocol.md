# P1-F00 v1 — Difficulty Evidence Feasibility Protocol

## Protocol record

| Field | Value |
| --- | --- |
| `protocol_version` | `P1-F00 v1` |
| `status` | `DRAFT_FOR_INDEPENDENT_REVIEW` |
| Decision context | `chooseDifficulty` |
| Scope | Phase-1 observational feasibility only |
| Baseline contract | `docs/game_brain_integration_architecture.md`, “Phase-1 `chooseDifficulty` contract freeze” |
| Repository date | 2026-08-21 |
| Independent approval | `PENDING` |

This is a preregistration candidate, not a protocol lock and not a P1-F01
result. It designs how P1-F01 will answer this question without changing
gameplay distribution first:

> Does normal Math Challenge gameplay generate enough truthful, comparable
> `chooseDifficulty` evidence across the Phase-1 difficulty envelope for
> Phase 1 to be empirically testable?

`FEASIBLE`, `INCONCLUSIVE`, and `NOT_FEASIBLE` below are prospective terminal
labels only. P1-F00 does not apply any of them.

## Frozen contract and authority boundary

An eligible opportunity exists only when the canonical owner explicitly opens
one and supplies immutable context, player-agency constraints, and the legal
candidate subset of `{Easy, Medium, Hard}`. GameBrain neither creates an
opportunity nor reconstructs legality. The canonical system retains ownership
of legal difficulties, mode restrictions, question generation, Adaptive
legality, and execution. GameBrain may later reason about supplied candidates;
it does not execute a choice. `mayAffectGameplay` remains `false`.

This protocol is limited to normal, single-player, Standard, Choice4, standard
mechanic, supported ordinary operation/context, and the Easy/Medium/Hard
envelope already supported by GEI-04B. It excludes Master, Quest, Survival,
Blitz, Combo, Death, two-player, True/False, missing-number,
missing-operation, and every other future decision context.

## Definitions

### Eligible episode

An **eligible episode** is one canonical `chooseDifficulty` opportunity for
which all of the following are true:

1. GameBrain effective enablement was true at the accepted terminal question
   observation; this is capture eligibility, not authority.
2. The opportunity and completed question are normal, single-player,
   Standard, Choice4, standard mechanic, and a supported ordinary operation
   context.
3. The completed question has a truthful accepted GEI-04B
   `QuestionExperienceObservation`: operation, number type, executed
   difficulty, answer style, and one accepted terminal outcome.
4. The canonical owner actually opened the opportunity and supplied one or
   more legal difficulty candidates from `{Easy, Medium, Hard}`.
5. The executed difficulty is a supplied legal candidate.

A question observation alone is not an eligible episode. Unsupported,
invalid, absent, duplicated, or unlinked observations are excluded from the
denominator used for comparable evidence and recorded as missingness; they are
never recoded as bad fit for any candidate.

### Comparable context

Two eligible episodes are **comparable** only when they share this exact
stratum:

```text
operation + numberType + answerStyle + canonical mode/mechanic
+ canonical-selection mechanism + relevant activity/run context
```

For Phase 1, canonical mode/mechanic must always be normal / single-player /
Standard / Choice4 / standard mechanic. `canonical-selection mechanism` is
the recorded classification of whether the canonical difficulty arose from
Adaptive or another canonical route; different classifications must not be
pooled. `relevant activity/run context` is a predeclared canonical activity
classification, if one exists; otherwise it is `notAvailable` and this is a
measurement dependency, not a reason to invent a proxy.

Strata are pooled only when every listed value matches. No post-result merging
or splitting is allowed. The narrow rule protects against invalid pooling;
episodes that cannot form a qualifying stratum remain coverage failure/unknown,
not negative evidence.

## Proposed P1-F00 v1 thresholds

Every number in this table is a **PROPOSED P1-F00 v1 THRESHOLD — subject to
independent protocol review**. These are conservative methodological/product
judgments for a small observational first slice, not learner-derived facts or
empirically validated cutoffs.

| Metric | Proposed threshold | Why / failure protected against |
| --- | --- | --- |
| Total eligible opportunities | at least 300 | Avoids declaring feasibility from a handful of ordinary runs; raw N alone never passes the protocol. |
| Natural exposure per difficulty | at least 60 eligible episodes each for Easy, Medium, and Hard | Prevents a difficulty with only incidental exposure from appearing evaluable. |
| Effective comparable sample | at least 30 episodes per difficulty in at least 3 qualifying strata | Requires repeated, context-controlled evidence rather than a globally pooled total. |
| Candidate balance within a qualifying stratum | largest candidate count / smallest candidate count no greater than 3.0 | Limits domination by one naturally selected difficulty. |
| Legal-option coverage | each candidate legal in at least 40% of all eligible opportunities and at least 30 opportunities | Separates lack of canonical availability from poor evidence; both a rate and count are needed. |
| Missingness | no more than 5% global and no more than 10% for any candidate | Prevents incomplete linkage/fields from silently determining a candidate’s result. |
| Natural/canonical starvation | no more than 20% of qualifying strata have any legal candidate with fewer than 10 observations | Detects observational starvation. It is not GameBrain-caused self-influence. |
| Temporal balance | no calendar/run-order quintile supplies more than 50% of any candidate’s comparable observations | Guards against a candidate being represented only in one time segment. |
| Sample diversity | at least 10 independent run segments, with no segment contributing more than 25% of an individual candidate’s comparable observations | Prevents one uninterrupted activity period from masquerading as repeated evidence. This is run diversity, not player identity. |
| Decision-relevant precision | for each difficulty’s terminal-outcome proportion in each qualifying stratum, two-sided 95% Wilson interval half-width no greater than 0.15 | Requires usable uncertainty, not raw count alone; 0.15 is a conservative practical-resolution judgment. |
| Candidate precision coverage | the precision rule must be met for each candidate in at least 3 qualifying strata | Prevents one well-measured context from standing in for the envelope. |

“Natural exposure” means canonical gameplay produced an eligible episode. It
does not mean GameBrain offered, selected, or preferred the difficulty.

### Primary feasibility metrics

P1-F01 must calculate, before terminal adjudication:

1. total eligible opportunities;
2. eligible exposure count and proportion for Easy, Medium, and Hard;
3. legal-option availability count and proportion per candidate;
4. comparable exposure count per candidate and stratum;
5. within-stratum candidate imbalance ratio;
6. global and candidate-specific missingness;
7. natural/canonical starvation rate;
8. temporal and run-segment concentration;
9. terminal-outcome proportions with the specified Wilson intervals; and
10. all confounding flags below.

An absent candidate is `UNKNOWN / coverage failure`, never evidence that it is
a bad candidate.

## Confounding flags and treatment

Flags are descriptive of observational limitations; no association may be
labeled causal.

| Flag | Detection rule | Severity / treatment |
| --- | --- | --- |
| `PLAYER_SELECTION_CONFOUNDING` | Player-agency constraint or selection route differs by difficulty, or is unavailable for more than 5% of comparable episodes. | Major. Exclude unmatched episodes; unresolved major status forces `INCONCLUSIVE`. |
| `ADAPTIVE_CANONICAL_SELECTION_CONFOUNDING` | Adaptive/non-Adaptive canonical-selection classifications are mixed within a pooled stratum, or a classification is unavailable for more than 5%. | Major. Stratify by classification; if qualifying strata cannot meet thresholds, `INCONCLUSIVE`. |
| `MODE_CONTEXT_CONFOUNDING` | Any supposedly eligible episode differs in frozen mode/mechanic/activity context. | Critical. Exclude it; if more than 5% are affected, `INCONCLUSIVE`. |
| `TEMPORAL_IMBALANCE` | A candidate exceeds the 50% quintile concentration threshold or time/run order is unavailable for more than 5%. | Major. Stratify by quintile if all other criteria remain met; otherwise `INCONCLUSIVE`. |
| `ANSWER_FORMAT_NUMBER_TYPE_IMBALANCE` | Candidate comparison pools different answer styles or number types, or either field is absent. | Critical. Never pool; exclude unavailable fields. Threshold failure is `INCONCLUSIVE`. |
| `LEGAL_OPTION_AVAILABILITY_CONFOUNDING` | Candidate legal-option coverage fails its rate or count threshold. | Major. No candidate penalty; terminal result follows the rules below. |
| `REPEATED_EVIDENCE_FAILURE` | Any candidate misses comparable-sample, qualifying-strata, or run-segment diversity thresholds. | Major. Terminal result follows the rules below. |

Resolved confounding means the predeclared stratification rule has been applied
and every remaining qualifying stratum still meets all thresholds. It does not
create causal evidence.

## Prospective terminal rules

P1-F01 must apply these in order. There is no “close enough” exception; for
example, 28 against a threshold of 30 fails that criterion.

### FEASIBLE

Return `FEASIBLE` only if all of the following pass:

1. total eligible opportunities are at least 300;
2. every difficulty has at least 60 eligible episodes;
3. every difficulty has at least 30 comparable episodes in at least 3
   qualifying strata;
4. every qualifying stratum meets candidate imbalance no greater than 3.0;
5. every difficulty meets legal-option coverage of 40% and 30 opportunities;
6. global and candidate missingness meet their thresholds;
7. natural/canonical starvation is at most 20%;
8. temporal balance and run-segment diversity meet their thresholds;
9. every difficulty meets the precision rule in at least 3 qualifying strata;
   and
10. no critical or unresolved major confounding flag remains.

The narrow meaning is only that natural gameplay appears sufficient for the
Phase-1 observational evidence claim under this protocol. It does not validate
GameBrain decisions, the Scenario Library, CandidateEvaluation, or gameplay
personalization, and does not decide that exploration is never needed.

### INCONCLUSIVE

Return `INCONCLUSIVE` if no `NOT_FEASIBLE` rule applies and any feasibility
criterion fails or cannot be measured: insufficient precision, insufficient
comparable exposure, unresolved major confounding, borderline/unknown
threshold status, legal-option coverage failure, missingness above threshold,
or missing required measurement. `INCONCLUSIVE` is required rather than a
binary assertion when the method cannot distinguish adequacy from failure.

### NOT_FEASIBLE

Return `NOT_FEASIBLE` only when all required measurements are available and a
failure is unambiguous after the declared treatment: a candidate has zero
legal-option opportunities across at least 300 eligible opportunities; a
candidate has zero natural exposure despite being legal in at least 40% and 30
opportunities; all eligible evidence fails to form even one qualifying
comparable stratum for a candidate; or a critical confounding condition is
present in more than 20% of otherwise eligible episodes and cannot be
stratified/excluded without eliminating the required measurement.

`NOT_FEASIBLE` must record one or more root-cause classes and does not
authorize exploration, gameplay-distribution changes, or any runtime change.

### Root-cause taxonomy

Use all justified labels from:

```text
EXPOSURE_STARVATION
COMPARABILITY_FAILURE
PLAYER_SELECTION_CONFOUNDING
ADAPTIVE_CANONICAL_SELECTION_CONFOUNDING
MODE_CONTEXT_CONFOUNDING
INSUFFICIENT_REPEATED_EVIDENCE
LEGAL_OPTION_COVERAGE_FAILURE
TEMPORAL_IMBALANCE
ANSWER_FORMAT_NUMBER_TYPE_IMBALANCE
```

Multiple labels are allowed. A terminal `INCONCLUSIVE` may also report these
flags but does not convert them into an asserted root cause.

## Measurement availability audit

The current GEI-04B collector is in-memory for the active run and exposes an
immutable snapshot of truthful question observations. It contains operation,
number type, difficulty, answer style, and terminal outcome only. It does not
persist, transmit, identify players, or create DecisionEpisodes.

| Required P1-F01 input / metric | Status | Basis / dependency |
| --- | --- | --- |
| Executed difficulty, operation, number type, answer style, accepted terminal outcome | `AVAILABLE_NOW` | Present in run-local `QuestionExperienceObservation`. |
| Basic terminal-outcome proportions for current-run observations | `DERIVABLE_NOW` | Can be computed from the current collector snapshot, subject to eligibility filtering. |
| GameBrain effective enablement at accepted observation | `NOT_CURRENTLY_CAPTURED` | Capture is gated by it, but no per-observation enablement field is stored; a future measurement seam would need to make this auditable without duplicating authority. |
| Explicit decision opportunity and supplied legal candidates | `NOT_CURRENTLY_CAPTURED` | GEI-04B captures questions, not `chooseDifficulty` opportunities. Requires a future canonical opportunity/legality measurement seam. |
| Opportunity-to-question linkage and validation that executed difficulty was legal | `NOT_CURRENTLY_CAPTURED` | Requires the same future canonical seam. |
| Canonical-selection mechanism / Adaptive classification | `NOT_CURRENTLY_CAPTURED` | Requires a future canonical measurement seam; it must not infer from outcomes. |
| Player-agency constraint / selection route | `NOT_CURRENTLY_CAPTURED` | Requires a future canonical measurement seam; no identity is needed. |
| Activity/run context and independent run segments | `NOT_CURRENTLY_CAPTURED` | Collector has no run identifier or activity classification. Requires a future bounded run-local seam. |
| Time or run-order quintiles | `NOT_CURRENTLY_CAPTURED` | Collector has no timestamp/order field. Requires a future bounded run-local measurement seam. |
| Cross-run total of 300 / diversity across runs | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Current run-local lifetime cannot provide cross-run evidence. Any persistence, telemetry, cloud, or research collection requires separate governance and implementation approval. |

P1-F01 therefore cannot currently make a terminal feasibility adjudication
from GEI-04B alone. This is a measurement dependency, not an authorization to
expand collection. The future protocol lock must either approve a bounded,
separately governed measurement plan or retain the inability to execute P1-F01.

## Governance, roles, and amendment

P1-F00 itself authorizes no cross-run persistence, telemetry, analytics, cloud
upload, remote research collection, or player identifiers. Any P1-F01 method
requiring them is a separate pre-execution governance and implementation
dependency. Nothing here changes data governance, gameplay distribution, or
GameBrain authority.

Future role separation is required:

| Role | Responsibility |
| --- | --- |
| Protocol Owner | Maintains this draft and prospective amendments. |
| Independent Protocol Approver | Reviews and approves/locks the protocol; the draft implementer may not self-approve. |
| P1-F01 Analyst / Executor | Runs the locked protocol without changing thresholds. |
| Independent Outcome Reviewer | Verifies measurements, calculations, and rule application. |
| Gate Adjudicator | Records the terminal outcome and root-cause labels from the locked rules. |

`independent_approval = PENDING`.

An amendment must be prospective. If P1-F00 v1 is changed after data has been
examined, the seen data becomes protocol-derivation evidence and cannot
silently serve as clean confirmatory evidence for the revised gate. Thresholds
must never be moved retroactively.

## Pre-review checklist

- P1-F01 has not been run and no P1-F01 result has been inspected.
- This protocol is not locked.
- Scenario Library, CandidateEvaluation, DecisionEpisode, policy, Experience
  Memory, and Player Model are not implemented by this document.
- No runtime capture, persistence, transmission, telemetry, analytics, or
  gameplay authority is added.
