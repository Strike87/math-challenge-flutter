# P1-F00 v1.1 — Prospective lifecycle and process-loss amendment

## 1. Status / lineage

| Field | Value |
| --- | --- |
| `protocol_version` | `P1-F00 v1.1` |
| `status` | `LOCKED / CURRENT PROSPECTIVE PROTOCOL` |
| Parent | `P1-F00 v1` in `docs/game_brain_p1_f00_difficulty_evidence_feasibility_protocol.md` |
| Parent status | `LOCKED / HISTORICAL` |
| Amendment policy | Prospective only |
| Confirmatory window | `CLOSED` / not opened |
| Outcome-blind status | No real P1-F01 outcome data informed this amendment |

### Lock provenance

- First independent review: `62732fe37b7b2ab9a2ac16c4db11a73a69646dbc`
  → `REQUIRED_CHANGES`.
- Required-changes revision: `c4339b1d5ada59397854bb65f0c2ce0d3205c788`.
- Independent re-review record: `1abe8c934b1b4d13e3162a435b5ff21e86bb0f86`
  → `APPROVED_FOR_LOCK`.

The confirmatory window remains unopened. Future amendments are prospective,
versioned, outcome-blind where required, and independently reviewed; locked
semantics are not edited in place.

P1-F00 v1 remains historically immutable. This prospective successor neither
rewrites nor unlocks v1. It addresses the readiness finding that lifecycle
interruption and silent process loss leave v1 denominator rules unexecutable.

### Revision note

Revised after independent review `REQUIRED_CHANGES` and the corrected G → F → E
proof ordering: admission is now explicitly crash-consistent,
opportunity-level, and independently re-reviewable; no mechanism or capture is
authorized.

## 2. Why amendment is required

Canonical timers use wall-clock `DateTime` deltas without a gameplay lifecycle
pause rule. Background duration can contribute to a canonical timeout, and
in-memory state can disappear on process loss without a durable closure receipt.
This amendment freezes treatment of those facts if they later become measurable.

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

## 5. Canonical gameplay and scientific admission

A **canonical gameplay window** remains under canonical gameplay authority.
Measurement integrity or storage success must never decide whether gameplay
opens, proceeds, closes, generates a question, or records a canonical terminal.

An **admitted confirmatory measurement window** is a separate scientific
population. It may be admitted only after required integrity admission state
reaches the future mechanism's defined crash-consistent durable commit boundary.
If admission cannot be established, gameplay continues normally, but that
window is nonadmitted to confirmatory P1-F01; this is nonadmission, not
fabricated confirmatory `O_raw` evidence or a gameplay effect.

The canonical owner's eligible `chooseDifficulty` opening remains the
conceptual canonical `O_raw` event. The confirmatory `O_raw` population
contains only admitted canonical openings. Admission does not redefine gameplay
or canonical legal options.

## 6. Lifecycle terminology

| Term | Prospective meaning |
| --- | --- |
| `ACTIVE` | An admitted opportunity is open and no interruption is known. |
| `BACKGROUNDED_OR_INTERRUPTED` | An admitted opportunity existed and a lifecycle interruption is known; this is not closure or player intent. |
| `EXPLICIT_CLEAN_CLOSURE` | An observable closure establishes required fields and accepted terminal linkage without known interruption. |
| `EXPLICIT_UNLINKED_CLOSURE` | An admitted opportunity is known to have existed and closed, but has no accepted terminal linkage. |
| `LEFT_UNCLEAN` | An admitted measurement window is established not to have cleanly closed; causal classification is not required. |

`BACKGROUND != CLOSURE`, `TIMEOUT != MISSING`, `NO_OPPORTUNITY != UNKNOWN`,
and canonical terminal truth != study eligibility.

## 7. O_raw prospective definition

For every admitted confirmatory measurement window, integrity accounting for
canonical eligible `O_raw` openings must be cumulative and monotonic: it
represents historical admitted openings, not currently open opportunities.
Terminal completion must not decrement historical opening counts. This prevents
survivor-only accounting.

The canonical owner supplies the legal-candidate set and required decision
context at the eligible opening. Entry is not question generation, execution,
QEO linkage, or completion.

An admitted opportunity that later explicitly closes unlinked remains in the
confirmatory `O_raw` population even though it cannot become `O_valid`.
Out-of-envelope opportunities remain outside `O_raw` as in v1.

## 8. O_valid lifecycle treatment

`O_valid` retains every v1 requirement and additionally requires a
`CLEAN_WINDOW`: no known lifecycle interruption and no observed unclean
closure. A known `BACKGROUNDED_OR_INTERRUPTED` opportunity is lifecycle-
censored: it remains in confirmatory `O_raw`, is excluded from `O_valid`, and is excluded
from `Y_correct` and Wilson denominators. It is not player failure.

An explicit unlinked opportunity remains `O_raw`, is excluded from `O_valid`,
and is never recoded as incorrect or no opportunity. Silent disappearance is
never silently valid. If required integrity facts are unavailable, v1 Step 1
returns `INCONCLUSIVE` / `MEASUREMENT_UNAVAILABLE`.

## 9. Legal-set membership and missingness

Integrity facts for admitted openings must preserve enough legal-set or
candidate-membership information to evaluate locked candidate denominators
truthfully. This does not require question text, prompt, answer, timestamp, or
unrelated payload. Uncertain membership must remain explicit and must not be
assigned to no candidates, the executed candidate, all candidates, or an
arbitrary distribution.

Global missingness is the count of admitted `O_raw` openings with a required `O_valid`
field absent, invalid/duplicated linkage, no accepted QEO link, explicit
unlinked closure, known lifecycle censoring, or observed unclean-window
condition, divided by the complete measurable admitted `O_raw` opening population.
Known interruption counts as integrity missingness, not player failure.

Candidate missingness for candidate `c` is evaluable only where legal
membership is known and contains `c`. If uncertain openings could belong to a
candidate and conservative candidate-specific bounds cannot be evaluated, that
candidate criterion is `INCONCLUSIVE`. No candidate denominator is fabricated.

If global accounting is unavailable, v1 Step 1 returns `INCONCLUSIVE` /
`MEASUREMENT_UNAVAILABLE`. Measurement uncertainty is never `NOT_FEASIBLE`.

## 9. Background-timeout treatment

An otherwise canonical `QuestionTimedOut` with a known interruption is
lifecycle-censored. It remains `O_raw`, counts as integrity missingness, and
is excluded from `O_valid`, `Y_correct`, and Wilson. A timeout without known
interruption retains v1 treatment. This does not infer interruption when the
fact is unavailable.

## 10. Complete admitted-window detection (G)

Every admitted confirmatory measurement window must later be distinguishable,
including after process death or restart, as `CLEANLY_CLOSED` or
`LEFT_UNCLEAN` / not cleanly closed. This requires complete integrity detection
for admitted windows, not attribution to crash, OS kill, device shutdown, or
any other cause.

A window that can disappear without durable evidence of admission and later
clean/unclean disposition must not be admitted. In-memory disappearance is not
evidence of cleanliness, observed loss, zero loss, validity, or player failure.

## 11. Window-integrity semantics

| Status | Meaning |
| --- | --- |
| `CLEAN_WINDOW` | Required opening and clean closure/linkage facts are observable with no known interruption. |
| `OBSERVED_UNCLEAN_WINDOW` | A known interruption, explicit unlinked closure, or other observable integrity defect occurred. |
| `INTEGRITY_UNKNOWN` | A required integrity fact is not measurable; it is neither clean nor unclean evidence. |
| `PROCESS_LOSS_CENSORING_RISK` | Validated finite accounting bounds indicate possible divergence; not fabricated observed loss. |

Only known facts make a window observed-unclean. A non-persistent disappearance
cannot support confirmatory admission.

## 12. Retry, duplication, and finite divergence (F → E)

Recovery/retry must be idempotent, or the future mechanism must separately
prove a finite maximum duplicate divergence. An uncertain acknowledgement or
retry must not silently inflate admitted `O_raw` accounting. Unbounded duplicate
divergence makes measurement integrity unavailable: `INCONCLUSIVE`.

`K_under` is the proven maximum number of true admitted canonical `O_raw`
openings that may be absent from durable accounting at an integrity-failure
boundary. `K_over` is the proven maximum number of durable accounting units
that may exist without corresponding admitted canonical `O_raw` truth,
including duplicate/recovery effects. No numerical values are frozen. Both must
be finite and validated before confirmatory P1-F01 collection; neither may be
inferred to be one from single-question gameplay.

The future mechanism must establish divergence direction from its validated
commit/recovery pipeline: `NONE`, `UNDERCOUNT_ONLY`, `OVERCOUNT_ONLY`, or
`BOTH`. Nominal write ordering alone does not establish `UNDERCOUNT_ONLY`.
Proof order is G complete admitted-window detection, then F idempotent recovery
or a finite duplicate bound, then E finite `K_under`, `K_over`, and divergence
direction.

## 13. Bootstrapping constraint

A pure non-persistent measurement system cannot validate its own silent-loss
rate when process death erases evidence that the window existed. Confirmatory
P1-F01 remains closed until a governed path can establish the minimum required
integrity claim. This is a protocol dependency, not mechanism authorization.

## 14. Conservative uncertainty and required integrity estimand

```text
potentially_lost_O_raw_proportion =
  potentially lost admitted canonical O_raw openings /
  (measurable clean + observed-unclean + potentially lost admitted canonical O_raw openings)
```

This estimates denominator-integrity risk, not recovered outcomes. When exact
denominator truth is unavailable but finite validated bounds exist, evaluation
may use conservative bounded uncertainty. A locked criterion may resolve only
when every defensible value in its range has the same locked criterion result.
If the range crosses a locked PASS/FAIL boundary, the result is `INCONCLUSIVE`;
never choose the favorable edge. Global bounds do not establish candidate
bounds, and no probabilistic allocation is permitted without a separately
authorized protocol.

## 15. Normative admission and integrity checklist

Any future confirmatory P1-F01 mechanism must satisfy all eleven items below
before a window may be admitted:

1. Canonical gameplay remains unaffected by measurement admission, commit, or
   storage success or failure.
2. An admitted confirmatory window is admitted only after its required
   integrity-admission state reaches a crash-consistent durable boundary.
3. After restart, every admitted window is deterministically distinguishable
   as cleanly closed or left unclean.
4. Admitted canonical eligible `O_raw` openings are cumulative and monotonic;
   closing a window never decrements them.
5. Each admitted opening preserves its legal-set membership, or preserves
   explicit membership `UNKNOWN`; neither may be fabricated.
6. Admission, opening, and closure/recovery accounting commits are
   crash-consistent: before confirmatory reliance, they prevent torn or
   partially applied accounting and silent loss of acknowledged committed state.
7. The proof order is G complete admitted-window detection, then F idempotent
   recovery or a finite duplicate bound, then E finite accounting divergence.
8. `K_under` and `K_over` are finite and validated: `K_under` bounds true
   admitted openings absent from durable accounting, and `K_over` bounds durable
   accounting units without corresponding admitted-opening truth.
9. The validated divergence direction is exactly `NONE`, `UNDERCOUNT_ONLY`,
   `OVERCOUNT_ONLY`, or `BOTH`.
10. A locked global integrity criterion resolves only if every defensible value
    in its conservative range gives the same result; otherwise it is
    `INCONCLUSIVE`.
11. Candidate uncertainty is evaluated separately: unknown legal membership or
    unevaluable conservative candidate bounds makes that candidate criterion
    `INCONCLUSIVE`, without fabricating a candidate denominator.

Failure of any required property makes measurement integrity unavailable.
The affected window is nonadmitted (or remains nonadmissible), and P1-F01
cannot fabricate evidence or return `FEASIBLE` from it.

## 16. Capture-authority firewall

P1-F00 v1.1 specifying a needed fact does **not** authorize capture. Lifecycle
transitions, dirty markers, durable counters, opportunity persistence,
process-loss markers, and legal-set receipts each need separate governance
authorization. No current implementation may pretend unavailable facts exist.

## 17. Protocol-authority semantics

Capture authority does not automatically make a fact admissible. This draft
permits adjudication use only as written: known interruption/observed unclean
closure affects `O_valid` and missingness; bounded receipts support only the
stated denominator estimand. Capture authority != protocol authority, and
protocol silence != permission.

## 18. Confirmatory-window prerequisites

No confirmatory window opens until this v1.1 revision has been independently
re-reviewed and locked; required capture governance is approved; a concrete
mechanism is specified; G → F → E proof has passed; and readiness confirms a
governed natural-play path for all unchanged v1 fields plus measurable required
integrity estimands. Synthetic/tests may later validate instrumentation but are
never confirmatory evidence. No real P1-F01 data has been inspected.

## 19. Falsification / false-pass cases

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

## 20. No-effect / unchanged scope

This amendment does not implement DecisionEpisode, CandidateEvaluation,
Scenario Library, gameplay selection, GameBrain authority, persistence, cloud,
telemetry, long-term memory, or Player Experience Model. `mayAffectGameplay`
remains `false`. It changes none of v1 thresholds, `Y_correct`, common support,
legal-option ownership, natural play, or terminal precedence.

## 21. Post-lock amendment rule

This is the locked current prospective protocol. Any future scientific change
must be a prospective, versioned amendment and receive outcome-blind
independent review where required. No confirmatory data may be inspected before
the applicable amendment is reviewed and locked.

P1_F00_V1_1_LOCK = LOCKED
