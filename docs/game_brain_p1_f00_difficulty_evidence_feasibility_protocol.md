# P1-F00 v1 - Difficulty Evidence Feasibility Protocol

## Protocol record

| Field | Value |
| --- | --- |
| `protocol_version` | `P1-F00 v1` |
| `status` | `DRAFT_REVISED_FOR_INDEPENDENT_REVIEW` |
| Decision context | `chooseDifficulty` |
| Scope | Phase-1 observational feasibility only |
| Baseline contract | `docs/game_brain_integration_architecture.md`, "Phase-1 `chooseDifficulty` contract freeze" |
| Repository date | 2026-08-21 |
| Independent approval | `PENDING_RE_REVIEW` |

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

## Measurement populations

The future governed P1-F01 measurement seam must produce records at the
canonical `chooseDifficulty` opportunity boundary. GEI-04B
`QuestionExperienceObservation` records alone are not difficulty decision
opportunities.

Use these prospective populations:

| Symbol | Name | Definition |
| --- | --- | --- |
| `O_raw` | raw opportunity analysis set | Every future measured Phase-1 `chooseDifficulty` opportunity record in the frozen envelope before missing-field exclusions. Unsupported modes/mechanics are outside this set and reported separately. |
| `O_valid` | eligible opportunities | Records from `O_raw` with all required fields present, one linked accepted GEI-04B question observation, a supplied legal-candidate set, and an executed difficulty contained in that supplied set. |
| `S_support` | candidate-support strata | Partitions of `O_valid` by the full common-support key below, including strata with zero executed exposure for one or more legal candidates. |
| `S_qual` | qualifying common-support strata | Three-candidate strata from `S_support` whose exact legal set is `{Easy, Medium, Hard}`, whose required support fields match exactly, and whose executed exposure has at least 10 observations for each difficulty with imbalance no greater than 3.0. |
| `C_qual` | comparable evidence set | Records in `O_valid` that belong to `S_qual`. |

Required fields for `O_valid` are: opportunity id, `chooseDifficulty` decision
locus, decision-locus reason, exact supplied legal-candidate set, executed
difficulty, opportunity-to-question link, operation, number type, answer
style, mode, mechanic, run type, player count, canonical-selection mechanism,
player-agency constraint or selection route, activity/run context, run segment
id, within-segment or cross-segment order, and accepted terminal outcome.

Missing, unsupported, duplicated, or unlinked records remain in `O_raw` for
missingness calculations when they originate from the future governed
measurement seam. They are excluded from `O_valid` and are never recoded as bad
fit for any candidate.

## Common support

A valid three-candidate Phase-1 comparison requires common support. Easy,
Medium, and Hard evidence from different contexts must not masquerade as one
comparison.

The full common-support key is:

```text
decisionContext
+ decisionLocus
+ decisionLocusReason
+ exact supplied legal-candidate set
+ player-agency constraint / selection route
+ canonical-selection mechanism
+ operation
+ numberType
+ answerStyle
+ runType
+ playerCount
+ gameMode
+ questionMechanic
+ relevant activity/run context
```

For Phase 1, `decisionContext` must be `chooseDifficulty`, `runType` must be
normal, `playerCount` must be 1, `gameMode` must be Standard, `answerStyle`
must be Choice4, `questionMechanic` must be standard, and the legal-candidate
set for a qualifying three-candidate stratum must be exactly
`{Easy, Medium, Hard}`.

All values in the key must match before records may be pooled. Missing key
values do not form support; they count toward missingness and produce
`INCONCLUSIVE` if required thresholds cannot be evaluated.

Pairwise support may be reported only as a diagnostic reason for why the full
Phase-1 three-candidate claim failed or abstained. Pairwise support cannot
satisfy `FEASIBLE` for the Easy/Medium/Hard envelope.

## Formal metrics

P1-F01 must calculate these metrics before terminal adjudication. All
threshold comparisons are strict at the written boundary: for example, 28
against a threshold of 30 fails that criterion.

| Metric | Unit | Numerator | Denominator | Scope / exclusions |
| --- | --- | --- | --- | --- |
| Eligible-opportunity count | opportunity record | `|O_valid|` | none | Excludes records outside the Phase-1 envelope and records missing required validity fields; those exclusions are still counted in missingness when they came from `O_raw`. |
| Eligible executed exposure count for candidate `c` | opportunity record | Count of records in `O_valid` with executed difficulty `c` | none | Candidate-specific; executed difficulty must be in the supplied legal set. |
| Candidate exposure proportion for `c` | opportunity record | Executed exposure count for `c` | `|O_valid|` | Candidate-specific; undefined if `|O_valid| = 0`, which forces `INCONCLUSIVE`. |
| Legal-option coverage for `c` | opportunity record | Count of records in `O_valid` whose supplied legal set contains `c` | `|O_valid|` | Candidate-specific global availability. Useful comparable coverage is also enforced by `S_qual`; global coverage alone cannot pass the protocol. |
| Global missingness | raw opportunity record | Count of records in `O_raw` missing any required `O_valid` field, invalidly linked, duplicated, or not linkable to one accepted QEO | `|O_raw|` | Global; unsupported out-of-envelope records are reported separately, not counted in this denominator. |
| Candidate missingness for `c` | raw opportunity record | Count of records whose supplied legal set is present and contains `c` but that are missing any candidate-relevant required field or valid QEO linkage | Count of records in `O_raw` whose supplied legal set is present and contains `c` | Candidate-specific. If legal sets are missing too often to assign candidate denominators, the missingness reason is global measurement unavailability. |
| Candidate imbalance in stratum `s` | stratum | `max(n_s,Easy, n_s,Medium, n_s,Hard)` | `min(n_s,Easy, n_s,Medium, n_s,Hard)` | Computed only for three-candidate support strata. A zero count makes the ratio infinite and the stratum cannot qualify. |
| Starvation | support stratum | Count of strata in `S_support` with exact legal set `{Easy, Medium, Hard}` where any difficulty has fewer than 10 executed observations, including zero | Count of strata in `S_support` with exact legal set `{Easy, Medium, Hard}` | Not circular: starvation is measured before qualifying strata are selected. Undefined when the denominator is zero; that forces `INCONCLUSIVE` unless a `NOT_FEASIBLE` predicate below applies. |
| Qualifying-stratum count | stratum | Count of strata in `S_qual` | none | A stratum qualifies only after exact common-support matching, per-candidate count floor, and imbalance checks pass. |
| Comparable exposure for `c` | opportunity record | Count of records in `C_qual` with executed difficulty `c` | none | Candidate-specific evidence used for the three-candidate claim. |
| Run concentration for `c` | run segment | Maximum records contributed by one run segment to comparable exposure for `c` | Comparable exposure for `c` | Candidate-specific. Segment ids must be canonical measurement facts, not inferred from results. |
| Run diversity | run segment | Distinct run segment ids represented in `C_qual` | none | Global comparable evidence. Missing segment ids count toward missingness. |
| Temporal concentration for `c` | ordered quintile | Maximum records for `c` in one temporal quintile | Comparable exposure for `c` | Quintiles are built by sorting `C_qual` by canonical run segment order and within-segment opportunity order, then splitting into five bins as evenly as possible. Missing order fields count toward missingness. |
| Wilson precision for `c` | candidate | Two-sided 95% Wilson half-width for `Y_correct` among comparable records for `c` | Comparable records for `c` with an accepted Phase-1 terminal outcome | Candidate-specific, pooled across all `S_qual` strata. It is not calculated on multinomial terminal labels. |

`Y_correct = 1` only for `AnsweredCorrect`. `AnsweredIncorrect`,
`QuestionTimedOut`, `QuestionSkipped`, and `QuestionReplaced` are
`Y_correct = 0`. Unknown, missing, duplicated, unlinked, or unauthorized
terminal observations are excluded from the Wilson denominator and counted in
missingness. `QuestionAbandoned` is not an accepted Phase-1 terminal category
unless a later locked protocol explicitly adds it prospectively.

## Proposed P1-F00 v1 thresholds

Every number in this table is a **PROPOSED P1-F00 v1 THRESHOLD - subject to
independent protocol re-review**. These are conservative methodological and
product judgments for a small observational first slice, not learner-derived
facts or empirically validated cutoffs.

| Metric | Final proposed threshold | Why / failure protected against |
| --- | --- | --- |
| Total eligible opportunities | `|O_valid| >= 300` | Avoids declaring feasibility from a handful of ordinary runs; raw N alone never passes the protocol. |
| Natural exposure per difficulty | At least 60 eligible executed episodes each for Easy, Medium, and Hard | Prevents a difficulty with only incidental exposure from appearing evaluable. |
| Effective comparable sample | At least 30 comparable episodes per difficulty across at least 3 qualifying common-support strata | Means 30 total per difficulty across the qualifying strata, not 30 per difficulty inside each stratum. Each counted stratum already requires at least 10 observations per difficulty. |
| Candidate balance within qualifying strata | Largest candidate count / smallest candidate count no greater than 3.0 | Limits domination by one naturally selected difficulty inside every common-support stratum. |
| Legal-option coverage | Each candidate legal in at least 40% of eligible opportunities | Separates lack of canonical availability from poor evidence. The old count limb was redundant once `|O_valid| >= 300` is required. |
| Missingness | No more than 5% global and no more than 10% for any candidate | Prevents incomplete linkage/fields from silently determining a candidate's result. |
| Natural/canonical starvation | No more than 20% of three-candidate support strata have any legal candidate with fewer than 10 observations | Detects observational starvation before qualifying-stratum selection. It is not GameBrain-caused self-influence. |
| Temporal balance | No temporal quintile supplies more than 50% of any candidate's comparable observations | Guards against a candidate being represented only in one time segment. |
| Sample diversity | At least 10 independent run segments represented in comparable evidence, with no segment contributing more than 25% of an individual candidate's comparable observations | Prevents one uninterrupted activity period from masquerading as repeated evidence. This is run diversity, not player identity. |
| Decision-relevant precision | For each difficulty's pooled comparable `Y_correct` proportion, two-sided 95% Wilson interval half-width no greater than 0.15 | Applies Wilson only to a declared binomial estimand. |
| Candidate precision coverage | The precision rule must be met for each candidate over evidence drawn from at least 3 qualifying common-support strata | Prevents one well-measured context from standing in for the envelope without requiring invalid per-stratum multinomial Wilson calculations. |

### Threshold changes after independent review

| Area | Old proposal | New proposal | Reason | Failure mode addressed | Judgment status |
| --- | --- | --- | --- | --- | --- |
| Protocol status | `DRAFT_FOR_INDEPENDENT_REVIEW` | `DRAFT_REVISED_FOR_INDEPENDENT_REVIEW` | Records that this is the Protocol Owner's response, not approval. | Accidental protocol lock. | Administrative. |
| Comparable sample | "30 episodes per difficulty in at least 3 qualifying strata" | 30 total per difficulty across at least 3 qualifying common-support strata; each such stratum requires at least 10 observations per difficulty | Removes the ambiguous "30 in three" reading. | False fail from requiring 30 per candidate in each of 3 strata, and false pass from disjoint strata. | Methodological clarification; numeric floor retained. |
| Legal-option coverage | At least 40% and at least 30 opportunities | At least 40% of `O_valid` | With `|O_valid| >= 300`, 40% implies at least 120 opportunities, so the 30-count limb is redundant. | Inconsistent implementation and threshold clutter. | Redundancy removal. |
| Wilson precision scope | Terminal-outcome proportion in each qualifying stratum | Pooled candidate-specific correctness proportion over `C_qual` | Wilson requires a binary estimand; per-stratum terminal-category wording was not reproducible. | Invalid precision pass/fail on multinomial terminal labels. | Methodological correction; confidence level and half-width retained. |
| Candidate precision coverage | Wilson rule met for each candidate in at least 3 qualifying strata | Wilson rule met per candidate on pooled `C_qual`, and `C_qual` must draw from at least 3 qualifying strata | Keeps repeated-context coverage while avoiding arbitrary per-stratum precision failure. | Permanent `INCONCLUSIVE` from fragmented natural evidence. | Methodological clarification. |

No threshold was changed because of observed P1-F01 data. P1-F01 has not been
run or inspected for this revision.

## Confounding flags and treatment

Flags are descriptive of observational limitations; no association may be
labeled causal.

| Flag | Detection rule | Treatment |
| --- | --- | --- |
| `PLAYER_SELECTION_CONFOUNDING` | Player-agency constraint or selection route differs within a proposed pool, or is unavailable for more than 5% of `O_raw` records with otherwise valid support fields. | Do not pool unmatched records. If thresholds cannot be evaluated after exact matching, return `INCONCLUSIVE`. |
| `ADAPTIVE_CANONICAL_SELECTION_CONFOUNDING` | Adaptive/non-Adaptive canonical-selection classifications are mixed within a proposed pool, or classification is unavailable for more than 5%. | Stratify by canonical-selection mechanism. If qualifying strata cannot meet thresholds, return `INCONCLUSIVE`. |
| `MODE_CONTEXT_CONFOUNDING` | Any supposedly eligible record differs from the frozen Phase-1 envelope. | Exclude out-of-envelope records from `O_valid`; if more than 5% of `O_raw` is affected by uncertain mode/mechanic fields, return `INCONCLUSIVE`. |
| `TEMPORAL_IMBALANCE` | A candidate exceeds the 50% temporal concentration threshold, or time/run order is unavailable for more than 5%. | Return `INCONCLUSIVE` unless all thresholds remain evaluable after predeclared stratification. |
| `ANSWER_FORMAT_NUMBER_TYPE_IMBALANCE` | Candidate comparison pools different answer styles or number types, or either field is absent. | Never pool. Count missing fields in missingness. |
| `LEGAL_OPTION_AVAILABILITY_CONFOUNDING` | Candidate legal-option coverage fails its rate threshold. | No candidate penalty; terminal result follows the mechanical rules. |
| `REPEATED_EVIDENCE_FAILURE` | Any candidate misses comparable-sample, qualifying-strata, precision-coverage, or run-segment diversity thresholds. | Terminal result follows the mechanical rules. |

Resolved confounding means the predeclared stratification rule has been applied
and every remaining qualifying stratum still meets all thresholds. It does not
create causal evidence.

## Prospective terminal rules

P1-F01 must apply this decision tree in order and stop at the first terminal
status reached. A result set must produce exactly one terminal status.

1. **Measurement construction.** Build `O_raw`, `O_valid`, `S_support`,
   `S_qual`, and `C_qual` using the definitions above. If a required
   measurement category was not captured at all, or the governed measurement
   path does not exist, return `INCONCLUSIVE` with
   `MEASUREMENT_UNAVAILABLE`.
2. **Critical measurable `NOT_FEASIBLE` predicates.** If measurements are
   available and any predicate below is true, return `NOT_FEASIBLE` with the
   matching root-cause label:
   - `LEGAL_OPTION_COVERAGE_FAILURE`: with `|O_valid| >= 300`, a candidate has
     zero legal-option opportunities.
   - `EXPOSURE_STARVATION`: with `|O_valid| >= 300`, a candidate is legal in
     at least 40% of eligible opportunities and has zero executed exposure.
   - `COMPARABILITY_FAILURE`: with `|O_valid| >= 300`, there is no
     three-candidate support stratum in which the exact legal set is
     `{Easy, Medium, Hard}`.
   - `INSUFFICIENT_REPEATED_EVIDENCE`: with `|O_valid| >= 300`, all
     three-candidate support strata fail to produce even one qualifying
     common-support stratum after exact matching.
   - `MODE_CONTEXT_CONFOUNDING`, `PLAYER_SELECTION_CONFOUNDING`, or
     `ADAPTIVE_CANONICAL_SELECTION_CONFOUNDING`: the condition affects more
     than 20% of otherwise eligible records and cannot be stratified or
     excluded without eliminating the required measurement.
3. **`FEASIBLE` all-pass check.** Return `FEASIBLE` only if every threshold in
   the table passes, no critical confounding remains, and all required metrics
   are evaluable.
4. **Default abstention.** Return `INCONCLUSIVE` for any remaining failed,
   borderline, missing, or unevaluable criterion. This includes insufficient
   precision, insufficient comparable exposure, unresolved major confounding,
   legal-option coverage below threshold but not zero, missingness above
   threshold, starvation above threshold, temporal/run concentration failure,
   or missing required measurement.

The narrow meaning of `FEASIBLE` is only that natural gameplay appears
sufficient for the Phase-1 observational evidence claim under this protocol.
It does not validate GameBrain decisions, the Scenario Library,
CandidateEvaluation, or gameplay personalization, and it does not decide that
exploration is never needed.

`NOT_FEASIBLE` does not authorize exploration, gameplay-distribution changes,
or any runtime change. It records one or more predeclared measurable root
causes only.

### Root-cause and abstention taxonomy

Use these labels only for asserted `NOT_FEASIBLE` root causes:

```text
EXPOSURE_STARVATION
COMPARABILITY_FAILURE
PLAYER_SELECTION_CONFOUNDING
ADAPTIVE_CANONICAL_SELECTION_CONFOUNDING
MODE_CONTEXT_CONFOUNDING
INSUFFICIENT_REPEATED_EVIDENCE
LEGAL_OPTION_COVERAGE_FAILURE
```

Use these labels for `INCONCLUSIVE` abstention reasons:

```text
MEASUREMENT_UNAVAILABLE
MISSINGNESS_ABOVE_THRESHOLD
THRESHOLD_UNEVALUABLE
PRECISION_INSUFFICIENT
COMMON_SUPPORT_INSUFFICIENT
LEGAL_COVERAGE_INSUFFICIENT
RUN_OR_TEMPORAL_DIVERSITY_INSUFFICIENT
UNRESOLVED_MAJOR_CONFOUNDING
```

`INCONCLUSIVE` may report observational flags, but it does not convert them
into asserted root causes.

## Protocol-level negative controls

These hypothetical patterns must not produce `FEASIBLE`:

| Control | Expected protocol behavior |
| --- | --- |
| Large total N, but Easy, Medium, and Hard evidence exists only in disjoint contexts. | Fails common support; return `NOT_FEASIBLE` only if the measurable predicate is met, otherwise `INCONCLUSIVE`. |
| All candidates have exposure, but one candidate has almost no common-support exposure. | Fails comparable sample, starvation, imbalance, or precision; never `FEASIBLE`. |
| Global legal-option coverage passes while useful comparable legal coverage fails for one candidate. | Global coverage alone is insufficient; `S_qual` and `C_qual` must still pass. |
| One or a few run segments dominate candidate evidence. | Fails run concentration or diversity; never `FEASIBLE`. |
| Pooling incompatible Adaptive/canonical selection pathways creates apparent balance. | Exact common-support key prevents pooling; unresolved route evidence forces `INCONCLUSIVE`. |

The healthy-evidence false-fail control is the clarified comparable-sample
rule: "30 in three strata" means at least 30 total comparable observations per
difficulty across at least 3 qualifying common-support strata. It does not
mean 30 observations per difficulty inside each of 3 strata.

## Measurement availability audit

The current GEI-04B collector is in-memory for the active run and exposes an
immutable snapshot of truthful question observations to runtime/test-visible
callers. It contains operation, number type, difficulty, answer style, and
terminal outcome only. It does not persist, transmit, identify players, or
create DecisionEpisodes.

Test-visible state is not by itself an authorized P1-F01 analysis/export path.
`SEARCH_INCOMPLETE` must not be treated as `NOT_FOUND`.

| Required P1-F01 input / metric | Status | Basis / dependency |
| --- | --- | --- |
| Executed difficulty, operation, number type, answer style, accepted terminal outcome | `AVAILABLE_NOW` | Present in run-local `QuestionExperienceObservation` and exposed through immutable snapshot accessors. |
| Basic terminal-outcome proportions for current-run observations | `DERIVABLE_NOW` | Can be computed from the current collector snapshot, subject to eligibility filtering and governed analysis authorization. |
| GameBrain effective enablement at accepted observation | `DERIVABLE_NOW` | Capture is gated by effective enablement, so presence of a current QEO implies it; no independent per-observation provenance field exists. Independent auditability would require a future seam. |
| Explicit canonical `chooseDifficulty` opportunity | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | GEI-04B captures questions, not decision opportunities. |
| Supplied legal-option set at opportunity | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | The canonical owner must supply this; legality must not be reconstructed. |
| QEO-to-decision opportunity linkage and validation that executed difficulty was legal | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Requires opportunity id/linkage and canonical execution validation. |
| Canonical-selection mechanism / Adaptive classification | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Must be recorded as a canonical measurement fact, not inferred from outcomes. |
| Player-agency constraint / selection route | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Requires bounded route/constraint facts; no player identity is needed. |
| Activity/run context, run segment id, and ordering | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Current QEO has no run segment, activity classification, timestamp, or ordinal. |
| Cross-run total of 300 / diversity across runs | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Current run-local lifetime cannot provide cross-run evidence. Any persistence, telemetry, cloud, or research collection requires separate governance and implementation approval. |
| Authorized P1-F01 analysis/export path | `NOT_CONFIRMED / SEARCH_INCOMPLETE` | This protocol does not establish an execution path. Absence of a confirmed path is not a claim that no future path can exist. |

P1-F01 therefore cannot currently make a terminal feasibility adjudication
from GEI-04B alone. This is a measurement dependency, not an authorization to
expand collection.

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

`independent_approval = PENDING_RE_REVIEW`.

An amendment must be prospective. If P1-F00 v1 is changed after data has been
examined, the seen data becomes protocol-derivation evidence and cannot
silently serve as clean confirmatory evidence for the revised gate. Thresholds
must never be moved retroactively.

## Review-response trace

| Review finding | Resolution | Resulting section |
| --- | --- | --- |
| M1 common support incomplete | Added full common-support key, exact legal-set matching, player-agency/selection route, decision locus, and three-candidate support requirement. Pairwise support is diagnostic only. | Common support |
| M2 denominators/formulas incomplete | Added `O_raw`, `O_valid`, `S_support`, `S_qual`, `C_qual`, numerator/denominator table, zero handling, run segments, and quintile construction. | Measurement populations; Formal metrics |
| M3 threshold interactions ambiguous | Defined "30 in three", removed redundant legal-count limb, and documented old/new threshold changes without using outcome data. | Proposed thresholds; Threshold changes |
| M4 Wilson estimand undefined | Replaced multinomial terminal wording with candidate-specific binary `Y_correct` and pooled Wilson rule. | Formal metrics; Proposed thresholds |
| M5 terminal precedence contradictory | Replaced overlapping status prose with a first-match decision tree. | Prospective terminal rules |
| m1 taxonomy scope unclear | Split `NOT_FEASIBLE` root causes from `INCONCLUSIVE` abstention reasons. | Root-cause and abstention taxonomy |
| m2 test visibility not authorized analysis path | Distinguished runtime/test-visible QEO availability from a governed P1-F01 path. | Measurement availability audit |
| m3 enablement implied, not independently evidenced | Classified enablement as derivable from capture invariant, with independent auditability requiring a future seam. | Measurement availability audit |

All required changes from the independent review are resolved in this draft.
No review finding is intentionally retained as unresolved.

## Pre-review checklist

- P1-F01 has not been run and no P1-F01 result has been inspected.
- This protocol is not locked.
- Scenario Library, CandidateEvaluation, DecisionEpisode, policy, Experience
  Memory, and Player Model are not implemented by this document.
- No runtime capture, persistence, transmission, telemetry, analytics, or
  gameplay authority is added.
