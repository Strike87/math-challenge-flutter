# P1-F00 v1.1 — Independent re-review record

## 1. Provenance

This record preserves the completed independent, outcome-blind re-review of
P1-F00 v1.1 from baseline
`c4339b1d5ada59397854bb65f0c2ce0d3205c788`.

## 2. Independence / outcome-blind status

The reviewer was procedurally separate from the amendment authoring. No
P1-F01 outcome data was inspected, the confirmatory window remains closed, and
this record authorizes neither collection nor a protocol lock.

## 3. Previous required-change reconciliation

The prior `REQUIRED_CHANGES` are resolved as protocol requirements. The
revision specifies observable integrity properties without selecting a storage
technology or claiming that the current repository implements them.

## 4. Scientific admission review

**PASS.** Failed measurement admission leaves canonical gameplay unchanged and
makes the window scientifically nonadmitted; measurement storage has no
gameplay authority.

## 5. Unclean-window completeness

**PASS.** A future compliant mechanism must make every admitted window
distinguishable after restart as `CLEANLY_CLOSED` or `LEFT_UNCLEAN`. A window
that could silently disappear cannot be admitted.

## 6. Monotonic O_raw

**PASS.** Admitted canonical `O_raw` openings are cumulative and monotonic;
terminal closure never decrements historical opening accounting.

## 7. Candidate/legal-set integrity

**PASS.** Candidate denominators require preserved legal membership or explicit
`UNKNOWN`. Unknown membership is not allocated to any candidate, and an
unevaluable candidate criterion is `INCONCLUSIVE`.

## 8. Crash consistency

**PASS.** Before confirmatory reliance, future admission, opening, closure, and
recovery accounting must reach crash-consistent durable boundaries that prevent
torn or partial accounting and silent loss of acknowledged committed state.

## 9. Recovery/idempotence

**PASS.** Future recovery/retry must be idempotent or have a separately proven
finite duplicate bound. Unbounded retry amplification makes integrity
unavailable.

## 10. K_under / K_over

**PASS.** `K_under` is the proven maximum true admitted canonical `O_raw`
openings absent from durable accounting at an integrity-failure boundary.
`K_over` is the proven maximum durable accounting units without corresponding
admitted canonical `O_raw` truth, including duplicate/recovery effects. Neither
has a default value; both must be finite and validated before collection.

## 11. Divergence semantics

**PASS.** A future mechanism must establish `NONE`, `UNDERCOUNT_ONLY`,
`OVERCOUNT_ONLY`, or `BOTH` from its validated commit/recovery pipeline.
Nominal write order alone is insufficient.

## 12. Conservative uncertainty

**PASS.** A locked criterion resolves only when every defensible value in its
uncertainty range has the same result. A range crossing a locked threshold is
`INCONCLUSIVE`, never a favorable-edge selection or `NOT_FEASIBLE` conclusion.

## 13. G → F → E dependency review

**PASS.** The protocol requires complete admitted-window detection first (G),
then idempotent recovery or a finite duplicate bound (F), then finite validated
`K_under`/`K_over` and divergence direction (E). It makes no premature finite
bound claim.

## 14. False-pass analysis

**PASS.** A compliant mechanism cannot admit a silently disappearing window,
allow unbounded retry duplication, omit bounded accounting lag, count durable
units without admitted truth, fabricate unknown candidate membership, select a
favorable uncertainty edge, or block gameplay on measurement-storage failure.

## 15. False-fail analysis

**PASS.** Integrity uncertainty preserves the frozen terminal treatment:
`MEASUREMENT_UNAVAILABLE` produces `INCONCLUSIVE`, not `NOT_FEASIBLE`.

## 16. Capture firewall

**PASS.** The protocol does not authorize persistence, integrity markers,
counters, receipts, lifecycle capture, telemetry, cloud, or recovery metadata.
Protocol requirement is not collection authorization.

## 17. Scientific-scope preservation

**PASS.** P1-F00 v1 remains `LOCKED / HISTORICAL`; v1.1 remains prospective.
The Phase-1 `chooseDifficulty` context, natural-play envelope, common support,
`Y_correct`, thresholds, legal coverage, exposure requirements, Wilson
precision, and terminal precedence are unchanged. No timing decision,
Scenario Library, Player Model, CandidateEvaluation, or DecisionEpisode is
introduced.

## 18. Lock-readiness finding

**APPROVED_FOR_LOCK.** The amendment now provides deterministic,
implementation-neutral properties against which a future integrity mechanism
can be tested. This approves the protocol requirements only. It does not claim
that a future mechanism has already proved complete detection, idempotence, or
finite `K_under`/`K_over`; those proofs remain prerequisites to confirmatory
collection after separate authorization.

## 19. Final outcome

No material protocol blocker remains.

`P1_F00_V1_1_INDEPENDENT_REREVIEW = APPROVED_FOR_LOCK`
