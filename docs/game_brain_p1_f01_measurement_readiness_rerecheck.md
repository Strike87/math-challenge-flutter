# P1-F01 measurement readiness re-check after truthful linkage

## Baseline / provenance

| Item | Value |
| --- | --- |
| Baseline | 232b46c57d86d497cef93f9707ccbe334b4a2189 |
| Branch | codex/p1-f01-measurement-readiness-rerecheck |
| Prior implementation | P1_F01_OPPORTUNITY_LINKAGE = IMPLEMENTED |
| Lifecycle input | CANONICAL_TIMER_LIFECYCLE = AMBIGUOUS; P1_F01_TIMER_EVIDENCE = POTENTIALLY_CONTAMINATED |

This is a documentation-only audit: no outcome data was inspected, no
confirmatory window was opened, and no authorization or protocol amendment is
created. SEARCH-INCOMPLETE is not a claim of absence.

## Locked protocol/version

docs/game_brain_p1_f00_difficulty_evidence_feasibility_protocol.md records
P1-F00 v1 as LOCKED, PROSPECTIVE_ONLY, and confirms P1-F01 has not run or been
inspected. The frozen envelope is normal, single-player, Standard, Choice4,
standard mechanic, supported ordinary operation/context, and Easy/Medium/Hard.
It requires a future governed measurement path at a canonical chooseDifficulty
opportunity.

Locked requirements are: |O_valid| >= 300; at least 60 eligible executed
exposures per difficulty; at least 30 comparable exposures per difficulty
across at least 3 qualifying strata; imbalance <= 3.0; legal coverage >= 40%;
global/candidate missingness <= 5%/<= 10%; starvation <= 20%; temporal
concentration <= 50%; at least 10 run segments with no candidate segment above
25%; and 95% Wilson Y_correct half-width <= .15.

## Implemented measurement foundation

- **IMPLEMENTED:** Canonical QuestionDifficultyLegality supplies a direct
  nullable legal set, resolved difficulty, and canonical route. Null remains
  null; GEI does not infer legality.
- **IMPLEMENTED:** The run-local collector records nullable legality,
  canonical runId, questionId, and 1-based active-run ordinal.
- **IMPLEMENTED:** Exact (runId, questionId) linkage attaches an accepted QEO
  once only. QEO contains operation, number type, difficulty, answer style,
  and terminal outcome.
- **IMPLEMENTED:** The collectors are in-memory and cleared on invalidation;
  they are neither a governed P1-F01 path nor durable evidence.

## Capability matrix

Status is capability for the named fact, never authority to collect or
adjudicate. DERIVABLE_NOW applies only where every input for that narrow fact
exists; it does not make a protocol metric evaluable.

| # | Required fact / metric | Authoritative source | Current source | Status | Why / exact blocker |
| ---: | --- | --- | --- | --- | --- |
| 1 | Canonical difficulty opportunity existence | P1-F00 populations | GameState._generateQ | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Generated-question record is not an explicitly opened chooseDifficulty opportunity. |
| 2 | Canonical legal difficulty set | P1-F00 O_valid | QuestionDifficultyLegality.legalDifficulties | AVAILABLE_NOW — IMPLEMENTED | Direct nullable canonical set exists. |
| 3 | Resolved/executed difficulty | P1-F00 O_valid | legality / QEO | AVAILABLE_NOW — IMPLEMENTED | Canonical resolved and presented difficulty exist. |
| 4 | Selection route/provenance | P1-F00 support key | legality route | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Difficulty route is not agency/selection-route provenance. |
| 5 | Canonical run identity | P1-F00 O_valid | collector | AVAILABLE_NOW — IMPLEMENTED | In-memory runId. |
| 6 | Canonical question identity | P1-F00 O_valid | collector | AVAILABLE_NOW — IMPLEMENTED | In-memory questionId. |
| 7 | Opportunity ordinal within run | P1-F00 ordering | collector | AVAILABLE_NOW — IMPLEMENTED | 1-based active-run ordinal; not segment order. |
| 8 | Exact opportunity ↔ accepted QEO linkage | P1-F00 O_valid | collector link | AVAILABLE_NOW — IMPLEMENTED | Exact token and exactly-once accepted terminal link. |
| 9 | Terminal outcome | P1-F00 O_valid | QEO | AVAILABLE_NOW — IMPLEMENTED | Available for supported enabled QEO. |
| 10 | Y_correct | P1-F00 metrics | QEO terminal | DERIVABLE_NOW — IMPLEMENTED | Correct is one terminal type; C_qual is still absent. |
| 11 | O_raw | P1-F00 populations | collector | BLOCKED_BY_PROTOCOL_SILENCE — PROTOCOL-SILENT | Cannot retain every governed opportunity, including missing, unlinked, duplicated, and silently lost records. |
| 12 | O_valid | P1-F00 populations | legality/linkage/QEO | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Locus/reason, support context, agency, mechanism, segment/order absent. |
| 13 | Opportunity count | P1-F00 metrics | collector | BLOCKED_BY_PROTOCOL_SILENCE — PROTOCOL-SILENT | Truthful O_valid count cannot be formed. |
| 14 | Executed candidate exposure | P1-F00 metrics | legality/QEO | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Needs protocol-valid opportunities and selection context. |
| 15 | Candidate exposure proportions | P1-F00 metrics | none | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Depends on valid count and exposures. |
| 16 | Legal-option availability | P1-F00 metrics | direct legality | DERIVABLE_NOW — IMPLEMENTED | Candidate inclusion is derivable per retained legality, not complete population. |
| 17 | Legal coverage | P1-F00 metrics | none | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Needs complete O_valid denominator. |
| 18 | Common-support strata | P1-F00 key | partial QEO/legality | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Required key dimensions are missing. |
| 19 | Exact legal-set comparability | P1-F00 support | legality | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Per-question set exists; opportunity/locus/full key does not. |
| 20 | Operation | P1-F00 key | QEO | AVAILABLE_NOW — IMPLEMENTED | Captured for supported QEO. |
| 21 | Number type | P1-F00 key | QEO | AVAILABLE_NOW — IMPLEMENTED | Captured for supported QEO. |
| 22 | Answer style | P1-F00 key | QEO | AVAILABLE_NOW — IMPLEMENTED | Captured for supported QEO. |
| 23 | Mode/mechanic/activity context | P1-F00 key | none retained | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | No retained run type, player count, mode, mechanic, or activity context. |
| 24 | Agency/selection route | P1-F00 key | none | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Required bounded agency/route is absent. |
| 25 | Canonical selection mechanism | P1-F00 key | none | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Adaptive/canonical classification is absent. |
| 26 | Missingness numerator | P1-F00 metrics | none | BLOCKED_BY_PROTOCOL_SILENCE — PROTOCOL-SILENT | No truthful raw accounting for missing/unlinked/duplicated/silent loss. |
| 27 | Missingness denominator | P1-F00 metrics | none | BLOCKED_BY_PROTOCOL_SILENCE — PROTOCOL-SILENT | Clearing and process loss remove raw records. |
| 28 | Candidate missingness | P1-F00 metrics | partial legality | BLOCKED_BY_PROTOCOL_SILENCE — PROTOCOL-SILENT | Needs raw candidate denominators including lost opportunities. |
| 29 | Imbalance | P1-F00 metrics | none | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Needs complete exact three-candidate support strata. |
| 30 | Starvation | P1-F00 metrics | none | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Needs S_support before qualification. |
| 31 | Temporal quintile | P1-F00 metrics | active-run runId and ordinal | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | In-memory runId/ordinal exist, but no P1-F01-defined/reliably retained cross-run segment identity or order exists for locked quintile construction. |
| 32 | Run segments | P1-F00 metrics | collector runId | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | In-memory runId exists, but no P1-F01-defined/reliably retained cross-run run-segment identity or canonical cross-segment order exists. |
| 33 | Per-run/per-segment concentration | P1-F00 metrics | none | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Needs comparable evidence keyed by segments. |
| 34 | Cross-run evidence | P1-F00 thresholds | run-local collectors | REQUIRES_GOVERNANCE_AUTHORIZATION — UNAUTHORIZED | Pooled/ten-segment evidence exceeds authorized run-local buffer. |
| 35 | Wilson precision | P1-F00 metrics | QEO terminal | REQUIRES_FUTURE_MEASUREMENT_SEAM — DESIGN-ONLY | Y_correct exists but required C_qual does not. |
| 36 | Background/lifecycle contamination | timer audit | GameState / main.dart | BLOCKED_BY_PROTOCOL_SILENCE — PROTOCOL-SILENT | Wall-clock timeout may include background time; treatment is absent. |
| 37 | Observable unclean closure | P1-F00 denominators | none | REQUIRES_GOVERNANCE_AUTHORIZATION — UNAUTHORIZED | Lifecycle/dirty-marker capture is not authorized. |
| 38 | Silent process-loss/censoring | P1-F00 denominators | in-memory collector | BLOCKED_BY_PROTOCOL_SILENCE — PROTOCOL-SILENT | Process death drops window; no protocol loss treatment. |
| 39 | Cross-restart measurement integrity | P1-F00 cross-run rules | none | REQUIRES_GOVERNANCE_AUTHORIZATION — UNAUTHORIZED | Restart never restores QEO or measurement state. |
| 40 | Governed P1-F01 analysis path | P1-F00 construction | repository inspection | SEARCH-INCOMPLETE | No established path was found; that does not establish impossibility. |

## O_raw / O_valid analysis

P1-F00 starts O_raw at every future measured in-envelope canonical
chooseDifficulty opportunity before exclusions. It retains missing, duplicated,
and unlinked records for missingness; unsupported modes/mechanics are outside
O_raw and reported separately. O_valid requires
every field, one linked accepted QEO, supplied legal set, and executed
difficulty in that set.

Current records are generated-question records, not explicit canonical decision
opportunities. Invalidation clears them. The repository cannot distinguish
clean completion, explicit unlinked closure, and silent disappearance. Process
death can understate O_raw; neither O_raw nor O_valid is ready.

## Common-support readiness

**IMPLEMENTED:** operation, number type, answer style, direct legal set,
resolved difficulty, identity, ordinal, and accepted QEO linkage.
**DESIGN-ONLY:** chooseDifficulty, decision locus/reason, agency/selection
route, canonical-selection mechanism, run type, player count, mode, mechanic,
and activity/run context. Exact legal-set matching cannot compensate for a
missing full key, so common support is blocked.

## Missingness readiness

Global and candidate missingness are defined over O_raw, not observations that
survived in memory. Current clearing and process loss cannot preserve
dangling/unlinked opportunities or distinguish explicit unlinked from silent
loss. The numerator and denominator are therefore **PROTOCOL-SILENT** material
requirements; neither rate is truthfully derivable.

## Temporal/run-segment readiness

The in-memory active-run ordinal and runId are **IMPLEMENTED**, but runId is
not a P1-F01-defined or reliably retained cross-run run-segment identity, and
there is no canonical cross-segment order. P1-F00's quintiles, ten-segment
diversity, and 25% concentration require a future governed multi-run path.
This establishes a need for multi-run evidence, not that cross-restart
persistence is necessarily required.

## Timer/background integrity

The timer audit found 100 ms periodic wall-clock DateTime timers, no gameplay
lifecycle pause handling, and possible background contribution to timeouts.
P1-F00 is **PROTOCOL-SILENT** on interruption, exclusion, O_raw/O_valid
treatment, and background-timeout eligibility. None is explicitly allowed or
prohibited. DG-00 makes lifecycle capture **UNAUTHORIZED**. No QEO/timer
change, TimingStyle, Deep Thinking/Untimed, or Time Bank is authorized.

## Process-loss/censoring

### A — pure non-persistent

The current in-memory design cannot self-estimate unclean-window frequency,
lost-run frequency, potentially lost O_raw proportion, or incomplete
opportunity frequency after silent process death: no trace remains that the
window existed.

### B1 — minimal integrity / diagnostic retention

A **B1-like** diagnostic retention category is the minimum category that might
make an unclean-window/lost-raw-opportunity frequency knowable. It is
**UNAUTHORIZED**, is not selected for implementation, and is not a study-grade
recovery claim.

### B2 — study-grade recovery retention

**B2-like** recovery is also **UNAUTHORIZED**. This audit selects neither B1
nor B2. DG-00 permits only five-field, in-memory, run-local QEO and prohibits
persistence, cloud, and telemetry.

## Capture-authority vs protocol-authority findings

| Future fact | DG-00 capture / retention authority | P1-F00 adjudication authority |
| --- | --- | --- |
| Background interruption | UNAUTHORIZED | PROTOCOL-SILENT |
| Clean/unclean window marker | UNAUTHORIZED | PROTOCOL-SILENT |
| Durable dirty flag | UNAUTHORIZED | PROTOCOL-SILENT |
| Lifecycle transition fact | UNAUTHORIZED | PROTOCOL-SILENT |

Capture permission is not adjudication permission; protocol permission is not
collection permission. P1-F00 authorizes neither persistence, telemetry,
cloud, research collection, nor a governed analysis path.

## Cross-run requirements

P1-F00 needs pooled evidence, at least ten segments, repeated qualifying
strata, temporal ordering, and concentration checks. Run-local collectors
cannot produce these after termination. Whether cross-restart persistence is
needed remains **UNRESOLVED / SEARCH-INCOMPLETE** until a bounded governed
design and lifecycle semantics are prospectively specified.

## Protocol silence findings

Material silence covers background interruption and timeout eligibility, clean
versus explicit-unlinked versus silent closure, process-loss censoring, and
effects on O_raw, O_valid, and missingness. Silence is not permission or an
exclusion rule. A prospective amendment is required before a truthful seam can
implement such treatment.

## Confirmatory-window status

The confirmatory window is closed/not opened. Only truthful natural canonical
gameplay under the locked protocol may become confirmatory evidence. Synthetic
and test evidence validate instrumentation only, never confirmatory evidence.

## Single smallest next task

Create a prospective, outcome-blind P1-F00 amendment limited to lifecycle
interruption and process-loss semantics for O_raw, O_valid, missingness, and
background-timeout eligibility. It must not authorize capture, retention, or
collection, alter thresholds, or inspect outcome data.

## Final readiness outcome

P1_F01_MEASUREMENT_READINESS = BLOCKED_BY_PROTOCOL_EXECUTABILITY

The nearest blocker is locked-protocol silence on lifecycle and process-loss
denominator semantics. This authorizes no runtime change, capture, retention,
aggregation, or confirmatory collection.
