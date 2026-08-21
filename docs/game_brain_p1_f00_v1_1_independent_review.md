# P1-F00 v1.1 — Independent outcome-blind protocol review

## 1. Review provenance

This independent scientific/protocol review uses baseline
`14b12e8d919abfd44583e6227d7d9cc2b40e13fe` on
`codex/p1-f00-v1-1-independent-review`. It directly reviewed the locked
P1-F00 v1 protocol, the P1-F00 v1.1 amendment draft, the P1-F01 readiness
re-check, the canonical timer/app-lifecycle audit findings, the frozen
Phase-1 `chooseDifficulty` contract, and relevant integration/governance
sections.

## 2. Independence / outcome-blind confirmation

The reviewer acted as a falsifier, not an author, implementer, or fixer.
The preferred reviewer was unavailable; an independent fallback reviewer
performed this read-only review. No P1-F01 outcome data was inspected. No
capture, retention, collection, analysis, or confirmatory window was
authorized or opened.

## 3. Scope review

**PASS.** The amendment is limited to lifecycle interruption, background
contamination, process-loss censoring, `O_raw`, `O_valid`, missingness, and
window integrity. It does not silently change the difficulty claim,
natural-play envelope, common-support dimensions, `Y_correct`, thresholds,
terminal precedence, legal coverage, or candidate exposure semantics.

P1-F00 v1 remains historically `LOCKED`; v1.1 is a prospective
`DRAFT_FOR_INDEPENDENT_REVIEW` and does not retroactively relabel evidence.

## 4. O_raw review

`O_RAW_DEFINITION = SOUND`

Entry at the canonical eligible `chooseDifficulty` opening is upstream of QEO
linkage and terminal outcome, corresponds to an actual canonical opportunity,
and avoids completion-survivor bias. A later measurement failure or explicit
unlinked closure does not erase its conceptual membership. Silent process loss
does not fabricate a record.

## 5. O_valid review

**PASS.** Retaining all v1 validity requirements and adding clean lifecycle
integrity is an upstream eligibility condition, not an added matching
dimension. Known interruption is treated differently from unknown interruption
without recoding canonical gameplay truth. The resulting rule is coherent only
once complete integrity accounting is specified in the required changes below.

## 6. Background-timeout review

`BACKGROUND_TIMEOUT_RULE = SOUND`

A known interrupted wall-clock timeout remains canonical gameplay truth and
`O_raw`, but is lifecycle-censored, integrity missingness, and excluded from
`O_valid`, `Y_correct`, and Wilson. This avoids interpreting absence from the
screen as difficulty failure. It does not require identical treatment for a
timeout with no known interruption; that remains subject to the ordinary
canonical treatment. Correlation of interruption with a candidate remains
visible only if the required global and candidate integrity accounting exists.

## 7. Explicit-unlinked review

**PASS.** An opened opportunity with an explicit observable closure but no
accepted terminal QEO remains `O_raw`, contributes to missingness, and cannot
become incorrect, timeout, `NO_OPPORTUNITY`, or valid success/failure evidence.

## 8. Process-loss review

`PROCESS_LOSS_BOOTSTRAPPING = SOUND`

Pure non-persistent collection cannot estimate its own loss rate: killed
windows can vanish, leaving retained survivors to appear to have zero observed
loss. The amendment correctly rejects treating silent loss as observed, zero,
valid, or incorrect, and routes unavailable integrity facts to v1 Step 1
`INCONCLUSIVE / MEASUREMENT_UNAVAILABLE`.

## 9. Required-estimand review

The stated estimand is correct in intent but underspecified in executable
measurement mechanics:

```text
potentially_lost_O_raw_proportion =
  potentially lost canonical O_raw openings /
  (measurable clean + observed-unclean + potentially lost canonical O_raw openings)
```

Its numerator is **potentially lost canonical `O_raw` openings**. Its
denominator is **measurable clean + observed-unclean + potentially lost
canonical `O_raw` openings**. The denominator can itself disappear under
process loss unless opportunity-level durable accounting exists. Window-level
facts alone are insufficient. Candidate-specific loss also requires the legal
candidate membership at opening, or an explicit unknown state. An unknown
membership cannot supply a candidate denominator and instead leaves global
measurement unavailable.

## 10. Durability sufficiency review

`DURABILITY_SUFFICIENCY = B1_LIKE_SUFFICIENT_ONLY_WITH_EXPLICIT_OPPORTUNITY_COUNTERS`

Window-level B1 facts such as start, clean close, and dirty marker cannot
distinguish a window that loses eight eligible openings from one that loses
one. They therefore cannot calculate the required numerator. B1-like
diagnostic integrity can be sufficient only if it explicitly requires a
durable opening-level receipt or count before loss, per-opening legal-set
membership (or explicit unknown), and reconcilable closure accounting.

That B1-like minimum need not recover QEOs, outcomes, responses, or study
records; B2-like recovery is therefore not required for this narrow integrity
estimand. The draft does not yet make those B1 mechanics deterministic.

## 11. Global missingness review

Global missingness remains conceptually correct for linked valid records,
explicit unlinked closures, known interruptions, lifecycle-censored timeouts,
invalid or missing context, and silent process loss. It cannot meet the
`<= 5%` threshold without survivor bias until the opportunity-level B1 facts
above establish the complete measurable `O_raw` denominator. Until then Step 1
must yield measurement unavailability.

## 12. Candidate missingness review

Candidate missingness can be evaluated only where the legal set at opportunity
opening is known. Assigning a lost opportunity to the executed difficulty, all
candidates, no candidates, or an inferred historical set would manufacture
truth. Without durable legal-set membership or an explicit unknown state,
candidate denominators are unavailable and the result is global measurement
unavailability; the `<= 10%` threshold is not evaluable.

## 13. False-pass analysis

| Path | Finding under the draft as written |
| --- | --- |
| A. Retained clean runs hide many killed runs | Vulnerable while B1 remains window-level/vague. |
| B. Difficult-candidate windows are disproportionately interrupted or killed | Vulnerable until opportunity-level legal membership is durable. |
| C. Background-generated timeouts leak into `Y_correct` | Blocked by the lifecycle-censored timeout rule. |
| D. Unlinked closures disappear from denominators | Vulnerable if durable opening/closure reconciliation is unspecified. |
| E. Pure non-persistence reports zero dirty windows | Vulnerable absent explicit opportunity-level durability; the conceptual bootstrap rule alone does not measure loss. |
| F. Legal-set information disappears before candidate accounting | Vulnerable until the opening receipt preserves membership or explicit unknown. |

## 14. False-fail analysis

**PASS.** The frozen Step 1 treatment is appropriate: inadequate integrity
measurement produces `INCONCLUSIVE / MEASUREMENT_UNAVAILABLE`, not
`NOT_FEASIBLE`. Lifecycle uncertainty therefore does not falsely reject the
scientific claim.

## 15. Threshold-coherence review

**PASS AFTER REQUIRED CLARIFICATION.** The v1 thresholds, including global and
candidate missingness, legal coverage, `|O_valid|`, exposure, concentration,
and Wilson precision, remain unchanged and meaningful. They require no
prospective numeric redefinition, but cannot be evaluated until durable
opportunity-level integrity accounting makes their denominators truthful.

## 16. Common-support review

**PASS.** Lifecycle-clean status is an upstream `O_valid` eligibility
condition, not an additional common-support matching dimension. The frozen
common-support key remains unchanged.

## 17. Capture-authority firewall

`CAPTURE_FIREWALL = PASS`

The amendment identifies facts a future authorized measurement mechanism would
need; it does not authorize lifecycle capture, background flags, durable
markers, opportunity counters, persistence, telemetry, cloud, analytics, or
any automatic admissibility of future capture.

## 18. Phase-1 scope firewall

**PASS.** `DecisionContext = chooseDifficulty` remains unchanged. This review
does not introduce timing decisions, Time Bank, Deep Thinking personalization,
Scenario Library execution, Player Model, CandidateEvaluation, DecisionEpisode
authority, difficulty manipulation, experimental exploration, or changed
candidate allocation.

## 19. Required changes

Before lock, amend the prospective durability requirement to make the B1-like
minimum deterministic: it must require durable opportunity-level opening
accounting before loss, legal-set membership or explicit unknown for each such
opening, and reconcilable closure accounting. It must state how these facts
produce the integrity estimand and when unavailable membership forces global
measurement unavailability. This review does not repair the amendment.

## 20. Final review outcome

The v1 lineage, prospective/outcome-blind posture, lifecycle classifications,
scope firewalls, and false-fail treatment pass review. The material unresolved
denominator ambiguity makes a lock premature.

`P1_F00_V1_1_INDEPENDENT_REVIEW = REQUIRED_CHANGES`
