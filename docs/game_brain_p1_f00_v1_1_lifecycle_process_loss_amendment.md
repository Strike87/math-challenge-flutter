# P1-F00 v1.1 — Prospective lifecycle and process-loss amendment

## 1. Status / lineage

| Field | Value |
| --- | --- |
| `protocol_version` | `P1-F00 v1.1` |
| `status` | `DRAFT_FOR_INDEPENDENT_REVIEW` |
| Parent | `P1-F00 v1` in `docs/game_brain_p1_f00_difficulty_evidence_feasibility_protocol.md` |
| Parent status | `LOCKED / HISTORICAL` |
| Amendment policy | Prospective only |
| Confirmatory window | `CLOSED` / not opened |
| Outcome-blind status | No real P1-F01 outcome data informed this amendment |

P1-F00 v1 remains historically immutable. This prospective successor neither
rewrites nor unlocks v1. It addresses the readiness finding that lifecycle
interruption and silent process loss leave v1 denominator rules unexecutable.

## 2. Why amendment is required

Canonical timers use wall-clock `DateTime` deltas without a gameplay lifecycle
pause rule. Background duration can contribute to a canonical timeout, and
in-memory state can disappear on process loss without a durable closure receipt.
This draft freezes treatment of those facts if they later become measurable.

## 3. Scope boundaries

This amendment is only about lifecycle/process-loss treatment of opportunity
integrity, `O_raw`, `O_valid`, missingness, and measurement-window integrity.
It authorizes no production code, tests, instrumentation, capture, persistence,
collection, analysis, or confirmatory P1-F01 execution.

The Phase-1 natural-play envelope remains normal, single-player, Standard,
Choice4, standard mechanic, supported ordinary operation/context, and
Easy/Medium/Hard. It excludes Master, Quest, Survival, Blitz, Combo, Death,
two-player, True/False, missing-number, missing-operation, `chooseTimingCondition`,
Deep Thinking, Untimed, Time Bank, experimental manipulation, and F11 work.

## 4. Unchanged P1-F00 v1 rules

All v1 numbers remain unchanged: `|O_valid| >= 300`; at least 60 eligible
executed exposures per difficulty; at least 30 comparable exposures per
difficulty across at least 3 qualifying strata; imbalance <= 3.0; legal
coverage >= 40%; global/candidate missingness <= 5%/10%; starvation <= 20%;
temporal concentration <= 50%; at least 10 run segments; <= 25% per candidate
per segment; and 95% Wilson `Y_correct` half-width <= 0.15.

`Y_correct` remains 1 only for `AnsweredCorrect`; `AnsweredIncorrect`,
`QuestionTimedOut`, `QuestionSkipped`, and `QuestionReplaced` remain 0 when
they meet v1 validity requirements. The full v1 common-support dimensions,
Phase-1 envelope/natural-play requirement, and ordered terminal precedence are
unchanged. In particular, v1 Step 1 remains `INCONCLUSIVE` with
`MEASUREMENT_UNAVAILABLE`; this draft creates no terminal status or precedence.

## 5. Lifecycle terminology

| Term | Prospective meaning |
| --- | --- |
| `ACTIVE` | Opportunity is open and no interruption is known. |
| `BACKGROUNDED_OR_INTERRUPTED` | Opportunity existed and a lifecycle interruption is known; this is not closure or player intent. |
| `EXPLICIT_CLEAN_CLOSURE` | An observable closure establishes required fields and accepted terminal linkage without known interruption. |
| `EXPLICIT_UNLINKED_CLOSURE` | Opportunity is known to have existed and closed, but has no accepted terminal linkage. |
| `SILENT_PROCESS_LOSS` | Process/window disappears without durable observable closure; the current non-persistent system cannot claim this as observed. |

`BACKGROUND != CLOSURE`, `TIMEOUT != MISSING`, `NO_OPPORTUNITY != UNKNOWN`,
`MISSING != SILENT_PROCESS_LOSS`, and canonical terminal truth != study
eligibility.

## 6. O_raw prospective definition

An opportunity enters `O_raw` at the canonical owner's eligible
`chooseDifficulty` opening in the frozen envelope. The owner must supply the
canonical legal-candidate set and required decision context at that boundary,
but a future measurement path failing to record either does not prevent
`O_raw` membership: it counts toward global missingness and makes any affected
candidate denominator unavailable. Entry is not question generation,
execution, QEO linkage, or completion. This avoids completed-run-only survivor
selection.

An opportunity that later explicitly closes unlinked remains an `O_raw` member
conceptually. A future governed seam must account for that opening even though
it cannot become `O_valid`. Out-of-envelope opportunities remain outside
`O_raw` as in v1.

## 7. O_valid lifecycle treatment

`O_valid` retains every v1 requirement and additionally requires a
`CLEAN_WINDOW`: no known lifecycle interruption and no observed unclean
closure. A known `BACKGROUNDED_OR_INTERRUPTED` opportunity is lifecycle-
censored: it remains in `O_raw`, is excluded from `O_valid`, and is excluded
from `Y_correct` and Wilson denominators. It is not player failure.

An explicit unlinked opportunity remains `O_raw`, is excluded from `O_valid`,
and is never recoded as incorrect or no opportunity. Silent disappearance is
never silently valid. If required integrity facts are unavailable, v1 Step 1
returns `INCONCLUSIVE` / `MEASUREMENT_UNAVAILABLE`.

## 8. Missingness numerator / denominator

Global missingness is the count of `O_raw` openings with a required `O_valid`
field absent, invalid/duplicated linkage, no accepted QEO link, explicit
unlinked closure, known lifecycle censoring, or observed unclean-window
condition, divided by the complete measurable `O_raw` opening population.
Known interruption counts as integrity missingness, not player failure.

Candidate missingness for candidate `c` is the count of those deficient
`O_raw` openings whose supplied legal set is known and contains `c`, divided
by `O_raw` openings whose supplied legal set is known and contains `c`.
Candidate denominators exist only when legal membership is known. Where it is
unknown, no denominator is fabricated: that is global measurement unavailability.

Silent process loss is not added as if observed. If it makes complete `O_raw`
unknowable, missingness is unevaluable and v1 Step 1 applies.

## 9. Background-timeout treatment

An otherwise canonical `QuestionTimedOut` with a known interruption is
lifecycle-censored. It remains `O_raw`, counts as integrity missingness, and
is excluded from `O_valid`, `Y_correct`, and Wilson. A timeout without known
interruption retains v1 treatment. This does not infer interruption when the
fact is unavailable.

## 10. Window-integrity semantics

| Status | Meaning |
| --- | --- |
| `CLEAN_WINDOW` | Required opening and clean closure/linkage facts are observable with no known interruption. |
| `OBSERVED_UNCLEAN_WINDOW` | A known interruption, explicit unlinked closure, or other observable integrity defect occurred. |
| `INTEGRITY_UNKNOWN` | A required integrity fact is not measurable; it is neither clean nor unclean evidence. |
| `PROCESS_LOSS_CENSORING_RISK` | Durable integrity accounting indicates an opening may have been lost before closure accounting; risk, not fabricated observed loss. |

Only known facts make a window observed-unclean. A non-persistent disappearance
remains unobserved, not a falsely observed `SILENT_PROCESS_LOSS` event.

## 11. Silent process loss / censoring

The current in-memory system cannot establish that a vanished window existed,
cannot conclude its loss rate is zero, and cannot call it valid or incorrect.
It therefore cannot truthfully form the complete `O_raw`/missingness
denominator needed for confirmatory adjudication.

## 12. Bootstrapping constraint

A pure non-persistent measurement system cannot validate its own silent-loss
rate when process death erases evidence that the window existed. Confirmatory
P1-F01 remains closed until a governed path can establish the minimum required
integrity claim. This is a protocol dependency, not mechanism authorization.

## 13. Required integrity estimand

```text
potentially_lost_O_raw_proportion =
  potentially lost canonical O_raw openings /
  (measurable clean + observed-unclean + potentially lost canonical O_raw openings)
```

This estimates denominator-integrity risk, not recovered outcomes. A
candidate-specific denominator also requires legal-candidate membership at
opening for every included term; otherwise no candidate loss proportion is
measurable. Observable unclean-window frequency is additionally required but
does not substitute for this potentially-lost-opening estimand.

## 14. Minimum conceptual durability class

The minimum class is `B1-LIKE_DIAGNOSTIC_INTEGRITY`: bounded opening/closure
integrity receipts and legal-set membership sufficient for the stated
denominator risk and known unclean closures. It must not recover QEO outcomes,
responses, or study episodes; that would be B2-like study recovery. This is a
requirement only, not capture, persistence, or implementation authorization.

## 15. Capture-authority firewall

P1-F00 v1.1 specifying a needed fact does **not** authorize capture. Lifecycle
transitions, dirty markers, durable counters, opportunity persistence,
process-loss markers, and legal-set receipts each need separate governance
authorization. No current implementation may pretend unavailable facts exist.

## 16. Protocol-authority semantics

Capture authority does not automatically make a fact admissible. This draft
permits adjudication use only as written: known interruption/observed unclean
closure affects `O_valid` and missingness; bounded receipts support only the
stated denominator estimand. Capture authority != protocol authority, and
protocol silence != permission.

## 17. Confirmatory-window prerequisites

No window opens until independent outcome-blind review, a subsequent lock, a
governed natural-play path for all unchanged v1 fields, and measurable required
integrity estimands. Synthetic/tests may later validate instrumentation but are
never confirmatory evidence. No real P1-F01 data has been inspected.

## 18. Falsification / false-pass cases

| Case | Required result |
| --- | --- |
| A. Only clean completed runs remain after silent kills. | Missingness cannot falsely pass; denominator is unavailable without integrity accounting. |
| B. Background causes canonical timeout. | It is not automatic difficulty-failure evidence; known interruption censors it. |
| C. Opportunity exists, explicit quit, no terminal QEO. | It stays `O_raw`, counts missingness, and is not `NO_OPPORTUNITY`. |
| D. Process dies without durable state. | Do not pretend loss was observed, zero, or valid. |
| E. Pure non-persistent collection sees zero unclean windows. | Do not infer zero process-loss rate. |
| F. Future lifecycle fact proposed. | A requirement must not silently authorize capture. |
| G. Capture later authorized. | Authorization does not permit use outside this adjudication rule. |

These rules prevent false pass from survivor-only data. They may cause a
conservative `INCONCLUSIVE` abstention when integrity is not measurable; that
is not a conclusion that natural-play feasibility failed.

## 19. No-effect / unchanged scope

This amendment does not implement DecisionEpisode, CandidateEvaluation,
Scenario Library, gameplay selection, GameBrain authority, persistence, cloud,
telemetry, long-term memory, or Player Experience Model. `mayAffectGameplay`
remains `false`. It changes none of v1 thresholds, `Y_correct`, common support,
legal-option ownership, natural play, or terminal precedence.

## 20. Independent review requirements

This is a draft only. An independent outcome-blind reviewer must assess
denominator integrity, global/candidate missingness, lifecycle classifications,
process-loss bootstrapping, false-pass/false-fail risk, coherence of retained
thresholds, any accidental scientific-claim change, and any implied capture
authority. No confirmatory data may be inspected before review and lock.

P1_F00_V1_1_LIFECYCLE_AMENDMENT = DRAFT_READY_FOR_INDEPENDENT_REVIEW
