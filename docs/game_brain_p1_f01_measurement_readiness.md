# P1-F01 Measurement Readiness

## Record

| Field | Value |
| --- | --- |
| Artifact | `P1-F01 measurement readiness` |
| Repository date | `2026-08-21` |
| Locked protocol basis | `docs/game_brain_p1_f00_difficulty_evidence_feasibility_protocol.md` |
| Locked protocol content basis | `ed0bcca2e400b72f34cce3c77f1688d52bf8264c` |
| Locked basis commit | `02a36a948...` |
| Role | `P1-F01 Analyst / Executor` |
| Outcome visibility before this artifact | `NO OUTCOME DATA INSPECTED` |
| Adjudication status | `NOT PERFORMED` |
| Result | `BLOCKED_BY_MEASUREMENT_DEPENDENCY` |

This artifact is a source-backed readiness audit only. It does not run P1-F01,
does not calculate protocol metrics from outcome data, and does not perform
gate adjudication.

## Current inspected basis

The current GEI-04B question-observation path is
`lib/features/game_brain/experience/question_experience_observation.dart`.
`QuestionPresentedSnapshot` currently stores only `operation`, `numberType`,
`difficulty`, and `answerStyle`, and `QuestionExperienceObservation` pairs that
presented snapshot with one terminal observation. The terminal types currently
present are `AnsweredCorrect`, `AnsweredIncorrect`, `QuestionTimedOut`,
`QuestionSkipped`, `QuestionReplaced`, and `QuestionAbandoned`.

The collector at
`lib/features/game_brain/experience/run_local_question_experience_collector.dart`
is in-memory and active-run only. It exposes `count`, an immutable
`snapshot`, `add`, and `clear`.

`GameState` exposes the collector only through debug-facing accessors
(`debugQuestionExperienceObservationCount` and
`debugQuestionExperienceObservations` at `lib/engine/game_state.dart:454-457`).
Capture is gated by `effectiveGameBrainEnabled`
(`lib/engine/game_state.dart:481-486`) and by the supported-run filter in
`_captureQuestionExperienceIfSupported`
(`lib/engine/game_state.dart:2631-2665`): normal run type, one player,
Standard mode, standard mechanic, no weak-skills plan, Choice4 answer style,
supported ordinary operation, and non-null question number type and
difficulty.

The active run configuration snapshot exists in `GameRunSnapshot`
(`lib/engine/game_state.dart:171-203`), but current QEO records do not carry
run snapshot identity, opportunity identity, legal-candidate sets, route, or
ordering facts. The active-run collector is cleared when the run is invalidated
(`lib/engine/game_state.dart:2728-2733`). Current save/export paths
(`lib/engine/game_state.dart:744-832`) do not persist or export QEO records.

## Measurement readiness matrix

Statuses are restricted to `AVAILABLE_NOW`, `DERIVABLE_NOW`,
`NOT_CONFIRMED_SEARCH_INCOMPLETE`, and
`REQUIRES_FUTURE_MEASUREMENT_SEAM`.

| Requested item | Status | Source-backed basis |
| --- | --- | --- |
| `O_raw` | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | The locked protocol defines `O_raw` as future measured `chooseDifficulty` opportunity records. Current GEI-04B records are question observations, not canonical `chooseDifficulty` opportunities. |
| `O_valid` | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | `O_valid` requires opportunity validity fields, legal set, executed difficulty legality, and one linked accepted QEO. Current QEO records do not contain the required opportunity fields or linkage key. |
| eligible opportunity count | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | This metric is `|O_valid|`; it cannot exist before `O_valid` exists. |
| legal availability | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Candidate legal-option coverage requires a canonically supplied legal-candidate set at the opportunity boundary. Current QEO records do not store legal sets and legality must not be reconstructed. |
| executed exposure | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | The protocol defines executed exposure over valid opportunity records with executed difficulty `c`. Current QEO difficulty is present, but without the opportunity/legal-set seam it is not protocol-valid executed exposure. |
| exposure proportion | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | This is executed exposure divided by `|O_valid|`; both dependencies require the future opportunity seam. |
| common-support strata | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | `S_support` requires decision context, decision locus, decision-locus reason, exact legal set, selection route, canonical-selection mechanism, run type, player count, mode, mechanic, and activity/run context. Current QEO records do not carry those fields. |
| legal coverage | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Qualifying legal coverage depends on the supplied legal-candidate set and exact-support stratification, both absent from current QEO records. |
| global missingness | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | The protocol defines missingness over `O_raw` opportunity records and their validity/linkage fields. There is no current governed `O_raw` seam to audit. |
| candidate missingness | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Candidate missingness requires `O_raw` records whose supplied legal sets contain candidate `c`; current QEO records do not contain supplied legal sets. |
| imbalance | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Candidate imbalance is computed inside three-candidate support strata. Those strata cannot be built without the future common-support seam. |
| starvation | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Starvation is measured over three-candidate support strata with exact legal set `{Easy, Medium, Hard}`. Current records cannot identify those strata. |
| temporal quintile | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | The protocol requires canonical run-segment order and within-segment order to build quintiles. Current QEO records carry neither timestamps nor canonical run order. |
| run segments | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | The protocol requires canonical run-segment ids and cross-segment diversity facts. Current collector state is active-run memory only and does not store run-segment ids on each observation. |
| per-run concentration | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Candidate run concentration depends on run-segment ids inside comparable evidence. Those ids are not present in current QEO records. |
| candidate `Y_correct` | `DERIVABLE_NOW` | Current QEO terminal types are sufficient to derive the locked binary mapping for accepted terminal categories only: `AnsweredCorrect = 1`; `AnsweredIncorrect`, `QuestionTimedOut`, `QuestionSkipped`, and `QuestionReplaced = 0`. `QuestionAbandoned` is currently present in code but is not an accepted Phase-1 terminal category unless a later locked protocol changes that prospectively. |
| Wilson precision | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | Even though `Y_correct` is derivable from accepted terminal types, the protocol applies Wilson to candidate-specific comparable evidence over `C_qual`, which depends on opportunity linkage, common-support strata, and repeated-run facts that are not currently captured. |
| selection route confounding | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | The locked protocol requires a bounded player-agency constraint / selection route fact. Current QEO records do not store it. |
| adaptive/canonical confounding | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | The locked protocol requires canonical-selection mechanism / Adaptive classification as a canonical measurement fact. Current QEO records do not store it. |
| activity/run context matching | `REQUIRES_FUTURE_MEASUREMENT_SEAM` | The locked protocol requires relevant activity/run context in the common-support key. Current QEO records do not store activity/run context labels. |

## Minimal bounded seam required

The minimal bounded seam is at the canonical `chooseDifficulty` opportunity
boundary. The canonical owner must supply immutable opportunity facts:

- opportunity presence at `chooseDifficulty`
- exact supplied legal-candidate set
- executed candidate
- canonical-selection mechanism / route
- bounded run-order facts sufficient for run segment and within-run ordering

Measurement must then associate the accepted QEO for the resulting presented
question with that canonical opportunity record.

This seam does not require or authorize policy execution, Scenario Library,
DecisionEpisode construction, a model, or a new player identifier.

## Retention and governance boundary

Current QEO state is not persisted and not exported. It is active-run memory
only and is cleared with run invalidation/lifecycle reset. Ephemeral multi-run
observation inside one still-running process could theoretically accumulate
more than one run if no invalidating lifecycle path fired, but the current
lifecycle does not provide a governed, reliable, local-retention basis for the
locked cross-run protocol metrics. Any local retention across restart is a
separate governance and implementation decision.

Natural gameplay evidence is the only confirmatory target contemplated by the
locked protocol. Tests, debug inspection, and synthetic generation are useful
for verification of capture mechanics only and are not confirmatory P1-F01
evidence.

Governance firewall: this readiness artifact does not authorize new
persistence, export, telemetry, cloud upload, remote research collection,
player identifiers, gameplay-distribution change, or GameBrain gameplay
authority.

## Conclusion

The current repository provides truthful run-local QEO raw facts and allows
locked `Y_correct` derivation from accepted terminal types, but it does not
currently provide the canonical `chooseDifficulty` opportunity, legal-set,
linkage, route, context, or cross-run ordering seam required by P1-F00 v1.

Result: `BLOCKED_BY_MEASUREMENT_DEPENDENCY`.
