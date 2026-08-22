# GameBrain governance decisions

## GD-P1F01-INTEGRITY-001

| Field | Decision |
| --- | --- |
| Date | 2026-08-22 |
| Owner role | Product/Data Owner (solo project) |
| Status | AUTHORIZED |
| Effective commit | Effective on this decision's Git commit; the SHA is reported outside this artifact. |

### Purpose

Authorize only future local crash-consistent integrity state sufficient to
determine whether a Phase-1 P1-F01 measurement window and its eligible
`chooseDifficulty` opportunities can be truthfully admitted to future
confirmatory measurement under locked P1-F00 v1.1.

### Authorized durable facts

Only these local integrity facts are authorized:

- integrity schema/version;
- internal local measurement-window sequence/generation;
- window status: `OPEN`, `CLEANLY_CLOSED`, or `LEFT_UNCLEAN`;
- cumulative admitted `O_raw` opening count;
- current/last integrity ordinal and legal-set code needed for idempotence;
- exact legal-set counters for candidate-denominator integrity; and
- minimum recovery/idempotence and closure/reconciliation metadata.

### Storage and retention

Storage is local device only. A future local SQLite transactional store may be
used, but no package is selected by this decision. There is no remote
synchronization, cloud copy, backup, telemetry, analytics, or other transport.

Retention is bounded to restart survival, reconciliation, and the local
measurement state needed for P1-F01 readiness or future confirmatory execution;
it does not authorize indefinite player-history retention. Before confirmatory
collection begins, its bounded study-retention lifecycle remains to be defined.

Full application/data reset must delete this local integrity state. Future Clear
GameBrain Data behavior must be explicitly wired and tested before release if
this state is GameBrain user data. Test or development reset must not masquerade
as a clean scientific closure, and deletion must not fabricate a terminal
outcome or clean-window status.

### Allowed use

This state may be used only for measurement-window admission, detection of
previously admitted unclean windows, monotonic `O_raw` accounting,
legal-set/candidate-denominator integrity, recovery/idempotence, G → F → E
proofs, and future P1-F01 readiness validation.

### Prohibited facts and uses

This decision does not authorize question prompts, operands, generated choices,
selected or correct answers, raw QEO history, player/student or account
identity, age or age-range, mastery history, misconception hypotheses,
GameBrain predictions, scenario states, Player Experience Model,
CandidateEvaluation, DecisionEpisode, timestamps, device or advertising
identifiers, telemetry, analytics, Sentry/Firebase transport, cloud copies,
remote backups, or generic future fields.

The retained state must not choose difficulty, personalize gameplay, modify
Adaptive, alter question generation, scoring, timers, or rewards, infer ability
or intelligence, generate scenarios, build a Player Experience Model, advertise,
analyze, profile, or transmit data. `mayAffectGameplay = false` remains true.

### Protocol boundary

This capture authorization does not authorize confirmatory P1-F01 collection,
and it does not prove that an implementation satisfies P1-F00 v1.1. After a
future implementation, G → F → E and all 11 locked integrity properties still
require validation before confirmatory collection. No P1 data is currently
captured.
