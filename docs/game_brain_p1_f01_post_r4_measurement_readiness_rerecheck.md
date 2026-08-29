# P1-F01 post-R4 measurement readiness rerecheck

## Baseline

| Item | Value |
| --- | --- |
| Primary workspace | `D:\FlutterProjects\math_challenge_flutter_repo` |
| Merged R4 baseline | `57bc7e68edd99b90dcfd9d9a3bd456b78557e996` |
| Included implementation commit | `703bee7d3afa3fe569fedefcb7389a23cb0dd874` |
| Protocol basis | `docs/game_brain_p1_f00_difficulty_evidence_feasibility_protocol.md` plus `docs/game_brain_p1_f00_v1_1_lifecycle_process_loss_amendment.md` |
| Confirmatory window | CLOSED / NOT OPENED |
| Outcome data | NOT INSPECTED |
| Authority change | NONE |

This artifact is a source-backed rerecheck only. It does not inspect study
outcomes, does not open confirmatory collection, does not expand authority,
and does not claim feasibility.

## Current implementation inventory

`P1F01IntegrityStore` is a local SQLite integrity store with one window table
(`p1_f01_integrity_window`) and one legal-set counter table
(`p1_f01_integrity_legal_set_count`). The store persists integrity version,
window sequence, `OPEN` / `CLEANLY_CLOSED` / `LEFT_UNCLEAN`, admitted
`O_raw` count, last admitted ordinal, last legal-set code, last reconciled
ordinal, known-integrity-defect flag, clean-closure signal, and exact
legal-set counters. It does not persist QEO content, answers, timestamps,
player identity, telemetry, or study outcome data.

`GameState` owns the current wiring. On load it calls
`recoverOpenWindows()`. On supported run start it may call `admitWindow()`.
For supported canonical opportunities it may call `admitOpportunity(...)`.
After each terminal-linkage attempt it may call `reconcileTerminal(...)` with the accepted-link result; rejection fails the window closed. Known
integrity failure paths call `markLeftUnclean()`. Clear GameBrain Data and
reset delete local rows through `deleteAll()`.

Supported P1-F01 integrity runs are fail-closed and bounded to:
effective-enabled, normal, one-player, Standard, standard mechanic, no Weak
Skills plan, Choice4, nonadaptive, player-configured Easy/Medium/Hard, and
supported ordinary operation contexts. Unsupported or failed integrity paths
must not affect canonical gameplay.

## 11-property matrix

Labels:

- `SOURCE_PRESENT`: implementation and test sources exist.
- `UNIT_EVIDENCE`: focused unit/widget coverage exists in source.
- `REOPEN_EVIDENCE`: reopen/recovery coverage exists in source.
- `DEVICE_UNPROVEN`: no physical-device kill/restart proof established.

| # | Locked property | Status | Source-backed basis |
| ---: | --- | --- | --- |
| 1 | Complete detection of admitted unclean windows | SOURCE_PRESENT; UNIT_EVIDENCE; REOPEN_EVIDENCE; DEVICE_UNPROVEN | `recoverOpenWindows()` converts durable `OPEN` to `LEFT_UNCLEAN`; reopen coverage exists in `test/p1_f01_integrity_store_test.dart`. |
| 2 | Monotonic admitted `O_raw` | SOURCE_PRESENT; UNIT_EVIDENCE; DEVICE_UNPROVEN | `admitted_o_raw_count` increments on admission and is never decremented by reconcile or close paths. |
| 3 | Exact legal-set / candidate membership | SOURCE_PRESENT; UNIT_EVIDENCE; DEVICE_UNPROVEN | Canonical legality is encoded as exact Phase-1 mask or `V1_UNKNOWN`; counter rows are keyed by stored legal-set code. |
| 4 | Crash-consistent durable commits | SOURCE_PRESENT; UNIT_EVIDENCE; DEVICE_UNPROVEN | The store uses SQLite transactions, but real-device kill/power-loss proof is not established. |
| 5 | Finite outstanding-accounting gap | SOURCE_PRESENT; UNIT_EVIDENCE; DEVICE_UNPROVEN | Ordinal mismatch/gap paths fail closed to `LEFT_UNCLEAN`; device boundary behavior remains unproven. |
| 6 | Idempotent recovery/retry or finite duplicate bound | SOURCE_PRESENT; UNIT_EVIDENCE; REOPEN_EVIDENCE; DEVICE_UNPROVEN | Same ordinal/same legal-set retry is exact; contradictory retry fails closed; reopen coverage exists. |
| 7 | Finite `K_under` | TARGET_ONLY; NOT_VALIDATED | The implementation targets zero undercount for admitted committed openings, but no device/scientific proof is established. |
| 8 | Finite `K_over` | TARGET_ONLY; NOT_VALIDATED | The implementation targets zero overcount via idempotence, but no device/scientific proof is established. |
| 9 | Defensible divergence direction | TARGET_ONLY; NOT_VALIDATED | The intended direction is `NONE`, but that is not validated evidence. |
| 10 | Conservative confirmatory threshold evaluability | PROTOCOL_PRESENT; STUDY_EVALUATOR_NOT_IMPLEMENTED | v1.1 defines conservative abstention semantics; no confirmatory evaluator is implemented here. |
| 11 | Protocol/source boundary and gameplay independence | SOURCE_PRESENT; UNIT_EVIDENCE | Storage-failure and reset/clear tests show fail-closed local integrity handling without canonical gameplay mutation; protocol authority is still separate from capture/storage existence. |

Properties 1 through 6 have source and focused-test evidence only. None is
physical-device crash proof. Properties 7 through 10 are not proven or not
implemented for confirmatory use. Property 11 remains a boundary claim, not a
gameplay-authority expansion.

## G -> F -> E

| Step | Current state | What is still missing |
| --- | --- | --- |
| G | Source path exists for durable `OPEN` recovery to `LEFT_UNCLEAN`. | Physical-device proof that every admitted interrupted window is preserved as nonclean, never silently clean. |
| F | Source path exists for exact retry, reopen recovery, and fail-closed mismatch handling. | Physical-device proof for interrupted admission, restart recovery, and repeated recovery without amplification. |
| E | Depends on G then F. | Validated finite `K_under`, finite `K_over`, and defensible divergence direction after device evidence. |

`K_under` and `K_over` both target zero in the current implementation model,
but zero is not validated and must not be stated as a proven result.

## Device validation scenarios still required

| Scenario | Expected durable integrity result | Expected gameplay result |
| --- | --- | --- |
| Durable `OPEN` kill/restart | Restart recovery preserves the prior admitted window as nonclean (`LEFT_UNCLEAN`), not silently clean. | Canonical gameplay remains preserved; later play may continue after recovery. |
| Interrupted admission | The interrupted opening is either nonadmitted or the window is left unclean when integrity is unknown. | Canonical gameplay remains preserved. |
| Restart recovery | Recovery runs before later admission and preserves prior unknown integrity as nonclean/unclean. | Canonical gameplay remains preserved. |
| Retry after interrupted commit acknowledgement | Exact same retry is idempotent or contradictory state fails closed to unclean; never clean by uncertainty. | Canonical gameplay remains preserved. |
| Clean close | `CLEANLY_CLOSED` appears only after consistent reconciliation; otherwise integrity remains open-then-unclean on recovery. | Canonical gameplay remains preserved. |
| Repeated recovery | Recovery does not duplicate admitted counts; repeated restart preserves nonclean status when already unclean. | Canonical gameplay remains preserved. |
| Storage failure | Integrity admission fails closed; unknown integrity never fabricates confirmatory admissibility. | Question generation, scoring, timers, rewards, BRAIN-07 observation, and QEO stay canonical. |
| Background / timer lifecycle | Any integrity-unknown interrupted window must remain nonadmitted or unclean/nonclean for confirmatory purposes. | Canonical gameplay timer behavior remains preserved. |

This rerecheck does not claim physical-device crash proof, complete unclean
detection under real device/process conditions, finite validated `K`, or
feasibility.

## Study evidence availability

Study evidence remains unavailable for confirmatory use in this branch:

| Requirement | Current rerecheck status | Why not confirmatory now |
| --- | --- | --- |
| `O_valid` | UNAVAILABLE_FOR_CONFIRMATORY_USE | Integrity state exists, but no retained confirmatory study-evidence path is established here. |
| Common support | UNAVAILABLE_FOR_CONFIRMATORY_USE | No retained confirmatory support-stratum evidence store/evaluator is established here. |
| Legal coverage | UNAVAILABLE_FOR_CONFIRMATORY_USE | Exact legal-set counters exist, but confirmatory coverage adjudication is not established here. |
| Missingness | UNAVAILABLE_FOR_CONFIRMATORY_USE | Integrity semantics exist, but confirmatory missingness evaluation is not established here. |
| Temporal/run ordering | UNAVAILABLE_FOR_CONFIRMATORY_USE | No confirmatory retained temporal/run-series evaluator is established here. |
| Cross-run evidence | UNAVAILABLE_FOR_CONFIRMATORY_USE | No confirmatory aggregation path is established here. |
| Wilson precision | UNAVAILABLE_FOR_CONFIRMATORY_USE | No confirmatory candidate-specific evaluator is established here. |

Focused P1 test-runner completion is unverified in this rerecheck and is not
counted as readiness evidence.

## Authority boundary

`mayAffectGameplay` remains false. The integrity mechanism does not choose
difficulty, alter legal options, execute gameplay changes, personalize play,
change Adaptive, persist study outcomes, transmit data, or create confirmatory
authority.

## Final verdict

P1_F01_MEASUREMENT_READINESS = READY_FOR_DEVICE_INTEGRITY_VALIDATION
