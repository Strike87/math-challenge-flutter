# P1-F01 — Minimum concrete integrity mechanism design

## 1. Baseline / protocol

This design is based exactly on `b7a77db760b1b6e0b65409f26c45c2d892139cdf`.
`docs/game_brain_p1_f00_v1_1_lifecycle_process_loss_amendment.md` is locked;
this document does not amend it or authorize collection.

## 2. Existing storage audit

The repository's `Storage` wrapper uses `SharedPreferences` scalar/key writes.
It provides no repository-documented multi-key transaction, crash-consistent
commit boundary, or recovery protocol. The current QEO and difficulty
measurement collectors are in-memory lists and are cleared on run invalidation.
They cannot establish process-loss integrity. The inspected `pubspec.yaml` has
no local transactional database primitive.

## 3. Current lifecycle insertion points

`GameState` creates a run, assigns question/run identities and canonical
difficulty legality, accepts one terminal claim, links the in-memory QEO, and
invalidates/clears collectors for quit, replay, and other run replacement.
Application resume currently refreshes UI state; it does not recover an
integrity record. These are future insertion points only: run start, eligible
opening after canonical legality exists, accepted terminal/linkage, explicit
close/invalidation, and process-start recovery.

## 4. Locked integrity requirements

The mechanism must preserve gameplay independence, crash-consistent admission,
complete admitted-window disposition, monotonic admitted `O_raw`, legal-set
membership or `UNKNOWN`, idempotent/finite recovery, and then finite
`K_under`/`K_over` with validated divergence direction. The required proof order
remains G, then F, then E.

## 5. Recommended minimal mechanism

Use one future **local SQLite transactional window-summary store**. It is not a
general event log and stores neither question text, answer, outcome, timestamp,
player identity, nor QEO. It has one active window at most, one durable window
row, and its exact-legal-set counter map. SQLite is selected because a single
transaction can atomically advance the window summary and one counter; the
existing `SharedPreferences` primitive cannot truthfully provide that claim.

## 6. Durable data schema

The proposed local-only schema is intentionally small:

| Record | Required fields |
| --- | --- |
| `integrity_window` | auto-increment `window_sequence`, `integrity_version`, `status` (`OPEN`, `CLEANLY_CLOSED`, `LEFT_UNCLEAN`), `last_committed_ordinal`, `last_committed_legal_set_code`, cumulative `admitted_o_raw_count`, `clean_closure_signal` |
| `integrity_legal_set_count` | `window_sequence`, exact canonical `legal_set_code` (or `UNKNOWN`), cumulative `count`; unique by window and set |

`window_sequence` is an internal durable sequence, not a user identifier.
`last_committed_ordinal` and `last_committed_legal_set_code` identify the latest
durably admitted opening for acknowledgement-safe retry. No per-question
receipt table is proposed.

## 7. Admission state machine

`NOT_ADMITTED` → transactionally insert `OPEN` window → `WINDOW_ADMITTED`.
For each eligible canonical opening, `WINDOW_ADMITTED` → one in-flight candidate
transaction → `OPENING_ADMITTED` only on commit; busy, failed, or uncertain
write acknowledgement leaves that canonical question `NONADMITTED` and gameplay
continues. There is at most one in-flight candidate opening. A future explicit
clean closure transaction reaches `CLEANLY_CLOSED`; known defect, explicit
unlinked closure, or recovery reaches `LEFT_UNCLEAN`.

## 8. O_raw accounting

For an opening, one SQLite transaction verifies `OPEN`, advances
`last_committed_ordinal`, increments `admitted_o_raw_count`, and upserts the
supplied exact legal-set counter. Only a successful commit admits that opening
to confirmatory `O_raw`; closure never decrements it. A failed/busy candidate is
not fabricated into `O_raw`, and is never retried as an admitted opening.

## 9. Legal-set accounting

The canonical owner supplies the legal set; the mechanism only serializes its
exact bounded code (for Phase 1, the supplied Easy/Medium/Hard subset) or
`UNKNOWN`. It never derives legality from enum order, historical exposure, or
scenario knowledge. The counter map preserves admitted-set totals without
recording question content. Candidate-specific analysis still requires the
separately governed evidence store described below.

## 10. Commit-frequency analysis

The `OPEN` admission, every potentially admitted `O_raw` opening, and every
closure/recovery transition require their own transaction. There is no batching,
timer flush, or best-effort queue. This is the minimum frequency that makes an
opening's admission boundary meaningful; it does not block, delay, or alter
canonical gameplay when storage is busy or fails.

## 11. G — unclean-window completeness

On process start, before any new admission, a transaction converts every
durable `OPEN` window to `LEFT_UNCLEAN`. A fresh window cannot be admitted until
that recovery completes. Thus an admitted window has durable evidence and ends
as `CLEANLY_CLOSED` or `LEFT_UNCLEAN`; noncommitted candidates were never
admitted. G is **COMPLETE_BY_DESIGN**, proposed only and unproven until concrete
implementation and interruption validation.

## 12. F — recovery/idempotence

One in-flight candidate plus a guarded transaction makes a known retry either
match its already-advanced ordinal and legal-set code or make no change; a
mismatch is an integrity failure, not a retry. After process loss, recovery
marks the window unclean rather than replaying openings. The proposed F result
is **EXACT** (no duplicate admitted opening), but it is a design claim only
until storage and failure-injection validation proves it.

## 13. E — K_under/K_over design analysis

Because an opening joins admitted `O_raw` only at the atomic increment, failed
or busy candidates are nonadmitted. The design targets `K_under = 0`,
`K_over = 0`, and divergence direction `NONE` for admitted truth. Those are
not established facts: the concrete transaction, acknowledgement, recovery,
concurrency, and interruption tests must validate them after G then F. Until
then P1-F01 remains `INCONCLUSIVE` / `MEASUREMENT_UNAVAILABLE`.

## 14. Clean close / restart behavior

Only a successful closure transaction with the required validated linkage and
no observed integrity defect writes `CLEANLY_CLOSED`. Explicit unlinked closure
or known interruption writes `LEFT_UNCLEAN`; a close-write failure leaves
`OPEN`, prevents further admission, and recovery later writes `LEFT_UNCLEAN`.
Restart never assumes cleanliness: it first converts `OPEN` to `LEFT_UNCLEAN`.

## 15. Integrity vs study-evidence separation

This store is only integrity summary state. A future separately governed,
bounded local study-evidence store would hold the necessary QEO/decision
linkage for `O_valid` and candidate analysis. Nothing in this design captures
P1 evidence now, and the integrity store must not become a substitute event log.

## 16. Retention/reset semantics

Future governance must define local retention. Until then, the design requires
an atomic local delete of both tables for the future GameBrain-data clear/reset
path; no existing preference-only clear is claimed to erase this future store.
Reset must not upload, migrate, or retain a shadow copy.

## 17. Data minimization

Persist only version, internal window sequence, state, ordinal, cumulative
counts, and exact legal-set codes. Do not persist names, account/device IDs,
question text, operands, answers, terminal outcomes, timestamps, predictions,
or telemetry fields.

## 18. Gameplay independence

Storage success, failure, busy state, recovery, and reset never choose a
difficulty, alter legal options, generate a question, record a canonical
terminal, pause a timer, or prevent play. `mayAffectGameplay` remains `false`.

## 19. Governance facts requiring authorization

Adding SQLite/a local database, lifecycle observation, new durable fields,
retention/delete behavior, and any linkage to a future study-evidence store all
require separate governance and implementation approval. This document grants
none. No cloud state, analytics, telemetry, parental-data expansion, or capture
authorization follows from this design.

## 20. Rejected alternative

Do not use a JSON or multi-key `SharedPreferences` summary with a marker flag.
It cannot establish a documented atomic boundary across status, `O_raw`, and
the exact legal-set counter. Per-opening event records are also rejected: the
single window summary plus counter map is sufficient for this integrity scope.

## 21. Implementation proof obligations

Before confirmatory collection, prove the database's crash-consistent
transaction boundary; one-active-window enforcement; all lifecycle insertion
points; recovery-before-admission; clean/unclean closure signal validation;
idempotence under lost acknowledgement; no torn counter/status updates;
`K_under = 0`, `K_over = 0`, and `NONE`; reset deletion; local-only behavior;
and gameplay noninterference. Validate `UNKNOWN` legal-set handling and that
measurement unavailability remains `INCONCLUSIVE`.

## 22. Final recommendation

Adopt this one local SQLite transactional window-summary design for a future,
separately governed implementation. It is the smallest credible route to the
locked integrity requirements; it is not an implementation approval and does
not open confirmatory P1-F01 collection.

`P1_F01_MINIMUM_INTEGRITY_DESIGN = DESIGN_READY_FOR_GOVERNANCE`
