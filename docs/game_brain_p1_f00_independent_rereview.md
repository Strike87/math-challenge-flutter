# Independent re-review — P1-F00 difficulty evidence feasibility protocol

## Review record

| Field | Value |
| --- | --- |
| Review target | commit `ed0bcca2e400b72f34cce3c77f1688d52bf8264c` |
| Protocol | `P1-F00 v1`, `DRAFT_REVISED_FOR_INDEPENDENT_REVIEW` |
| Target document | `docs/game_brain_p1_f00_difficulty_evidence_feasibility_protocol.md` |
| Reviewer role | Independent Protocol Reviewer / Approver |
| Independence | `PROCEDURAL_INDEPENDENCE_ONLY` |
| Outcome visibility | Outcome blind; no actual dataset, synthetic dataset, or computed metric inspected |
| P1-F01 status | Not run; no P1-F01 outcome calculated or inspected |
| Recommendation | `APPROVE_FOR_PROTOCOL_LOCK` |

This artifact records an independent procedural re-review of the revised draft
only. It is not a P1-F01 result, protocol lock, gate adjudication, gameplay
approval, or authorization to add measurement seams, persistence, telemetry, or
runtime behavior.

## Disposition

| Severity | Count | Disposition |
| --- | ---: | --- |
| Blocking | 0 | None |
| Major | 0 | None |
| Minor | 0 | None |

Threshold coherence judgment: `INTERNALLY_COHERENT`.

Basis: hypothetical arithmetic and rule-trace inspection only. No actual
dataset, simulation output, runtime result, or P1-F01 metric was used.

## Resolution matrix

| Prior item | Status | Evidence in current draft |
| --- | --- | --- |
| 1. Common support incomplete | `RESOLVED` | The common-support key now explicitly includes `decisionLocus`, `decisionLocusReason`, exact supplied legal-candidate set, player-agency constraint / selection route, canonical-selection mechanism, and the frozen Phase-1 context fields; pairwise support is diagnostic only and cannot satisfy the three-candidate claim. |
| 2. Denominators and formulas incomplete | `RESOLVED` | The draft now defines `O_raw`, `O_valid`, `S_support`, `S_qual`, and `C_qual`, plus explicit numerators, denominators, zero handling, run concentration, run diversity, starvation denominator, and temporal quintile construction. |
| 3. Comparable-sample and threshold interaction ambiguity | `RESOLVED` | The threshold table and change log now state that "30 in three strata" means at least 30 total comparable observations per difficulty across at least 3 qualifying strata, and the redundant legal-count limb was removed because `|O_valid| >= 300` and 40% legal coverage already imply a larger count. |
| 4. Wilson estimand undefined | `RESOLVED` | `Y_correct` is now defined exactly as `AnsweredCorrect = 1` and `AnsweredIncorrect`, `QuestionTimedOut`, `QuestionSkipped`, and `QuestionReplaced = 0`, with unknown, missing, duplicated, unlinked, or unauthorized terminals excluded from the Wilson denominator and counted in missingness. |
| 5. Terminal precedence contradictory | `RESOLVED` | The prospective terminal rules now require a first-match chain: measurement construction; critical measurable `NOT_FEASIBLE` predicates; `FEASIBLE` all-pass check; default `INCONCLUSIVE` abstention. The text requires exactly one terminal result. |
| 6. Taxonomy / availability / governance clarifications incomplete | `RESOLVED` | The draft now separates `NOT_FEASIBLE` root-cause labels from `INCONCLUSIVE` abstention reasons, truthfully labels runtime/test-visible versus future-measurement dependencies, preserves `SEARCH_INCOMPLETE` rather than overstating absence, and keeps amendments prospective with role separation and `independent_approval = PENDING_RE_REVIEW`. |

## Required protocol checks

| Check | Result | Notes |
| --- | --- | --- |
| `Y_correct` definition exactness | `PASS` | `AnsweredCorrect = 1`; `AnsweredIncorrect`, `QuestionTimedOut`, `QuestionSkipped`, and `QuestionReplaced = 0`. |
| Accepted terminal pool | `PASS` | The Wilson denominator is limited to accepted Phase-1 terminal outcomes, with `QuestionAbandoned` excluded unless a later locked protocol adds it prospectively. |
| Terminal first-match chain | `PASS` | The decision tree is ordered and mutually adjudicable. |
| Truthful availability language | `PASS` | Current QEO facts are identified as `AVAILABLE_NOW` / `DERIVABLE_NOW`; missing seams remain `REQUIRES_FUTURE_MEASUREMENT_SEAM`; analysis/export path remains `NOT_CONFIRMED / SEARCH_INCOMPLETE`. |
| Governance and prospective amendment | `PASS` | No new authority is granted; seen data cannot be silently reused as clean confirmatory evidence for a revised protocol. |
| No reviewer runtime or test changes | `PASS` | This re-review changed no source, runtime behavior, or tests. |

## False-pass / false-fail challenge

| Challenge | Verdict | Basis |
| --- | --- | --- |
| False-pass A: large total N but disjoint Easy/Medium/Hard contexts | `PASS` | Exact common support and three-candidate stratum requirements prevent `FEASIBLE`; the draft routes to measurable `NOT_FEASIBLE` or `INCONCLUSIVE` instead. |
| False-pass B: one candidate nearly absent wherever another is observed | `PASS` | Global legal coverage alone cannot pass; `S_qual`, `C_qual`, comparable exposure, imbalance, starvation, and precision still gate the claim. |
| False-pass C: global legal coverage passes but comparable legal opportunity coverage is structurally weak | `PASS` | `S_qual` and `C_qual` require qualifying common-support strata, not just aggregate legal coverage. A candidate cannot pass on broad global availability alone when comparable opportunity is too thin inside the exact support used for the estimand. |
| False-pass D: one run or segment dominates most candidate evidence | `PASS` | The draft does not treat pooled counts as sufficient by themselves; qualifying evidence must remain diverse enough across runs/segments that a single dominant run concentration does not masquerade as stable support. Concentrated evidence fails the run/segment diversity basis for `S_qual`/`C_qual` instead of silently passing. |
| False-pass E: incompatible player-agency or canonical-selection routes pooled | `PASS` | Those facts are now part of the exact common-support key; unresolved route evidence fails closed. |
| False-pass F: one candidate has zero exposure in a three-candidate support stratum but aggregate appears balanced elsewhere | `PASS` | A zero for one candidate inside an otherwise qualifying three-candidate support stratum is a zero-to-infinite imbalance, so that stratum cannot qualify for `S_qual`/`C_qual`. Aggregate balance elsewhere does not override within-stratum nonqualification or starvation. |
| Healthy-evidence false-fail control | `PASS` | The clarified rule is feasible in principle, not just rhetorically. For a purely hypothetical internally consistent construction: 300 valid comparable observations, 100 per candidate, spread across 3 qualifying common-support strata with at least 10 observations per candidate in each stratum and at least 10 balanced segments overall, while all other thresholds also pass. That satisfies the rule without requiring the impossible reading of 30 per difficulty inside each of 3 strata. |

## Unresolved dissent

The numeric thresholds remain methodological judgments rather than empirically
validated cutoffs. That dissent remains noted, but it is acceptable at P1-F00
because the draft now labels those numbers prospectively, keeps them outcome
blind, and makes the arithmetic mechanically reproducible without claiming that
the values were learner-derived.

## Final recommendation

`APPROVE_FOR_PROTOCOL_LOCK`

`PROTOCOL FILE MODIFIED BY REVIEWER = NO`

No runtime changes were made. No test changes were made.
