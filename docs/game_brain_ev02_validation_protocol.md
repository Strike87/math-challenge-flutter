# GameBrain EV-02 — Run-Bounded Difficulty-Evidence Validation Protocol

## Status

**STATUS:** DESIGN FROZEN
**EXECUTION:** NOT AUTHORIZED
**GAMEPLAY AUTHORITY:** FALSE
**P0:** DORMANT

## 1. Purpose

EV-02 records a finite validation design for one possible future claim:

> During this run, evidence suggests repeated difficulty with [operation] in
> this mathematical context.

This is an observable context-performance claim only. It does not identify a
learner misconception, hidden cognitive mechanism, stable learner trait,
global ability, causal explanation, or future certainty. This design does not
authorize the wording for production UI.

## 2. Frozen validation question

Can a run-bounded pattern of correctness, incorrectness, and timeout in one
supported GameBrain context predict poorer performance on independently
selected held-out items in the same context and controlled condition envelope?

## 3. Pilot context

The first pilot context is:

```text
Addition + Natural + directNumeric
```

It is selected for clear structured mapping, simple independent item
construction, and low initial interpretive complexity. It does not claim that
Addition is the most common, weakest, or most important context. Production
exposure distribution remains **NOT MEASURED**.

## 4. Controlled condition envelope

The first pilot is limited to all of the following:

- single player;
- Standard mode in a normal run;
- Choice4 and the standard mechanic;
- Addition only, Natural numbers, and directNumeric representation;
- adaptive difficulty off and Easy difficulty held fixed;
- the existing Standard per-question timer held constant;
- no power-up use; and
- no Master, Daily Boss, Operation Quest, True/False, Missing Number, or
  Missing Operation.

Follow-up/reinforcement items are excluded from evidence and reference
scoring. This envelope controls confounding for the pilot; it does not
establish generalization to other modes or conditions.

## 5. Held-out reference design

Held-out assessment items must be independently authored or selected, match
Addition + Natural + directNumeric, and be allocated before participant or run
outcomes are inspected. A reference item cannot appear in the evidence window
or be selected because of GameBrain output.

The independent reference criterion is matched held-out performance. Canonical
mastery, Weak Skills ranking, and GameBrain output are not ground truth.

## 6. Candidate signal family

The family, not final numerical values, is frozen. A candidate may use only:

- exposure count;
- incorrect count;
- timeout count; and
- error proportion derived from explicit incorrect answers plus timeouts.

There may be at most four variants: two predeclared minimum-exposure values by
two predeclared error-proportion values.

**EXECUTION PARAMETERS UNSET INTENTIONALLY:** this design chooses none of
those values.

Candidates must not use canonical mastery, confidence, latency scoring,
response-time models, misconception features, hints, multiple attempts,
self-correction, BRAIN-06 synthetic thresholds, or ML/neural models.

## 7. Pre-registration

Before any real-data execution, separately freeze the exact candidate values,
held-out poorer-performance criterion, item pool and allocation, condition
envelope/version, primary metrics, analysis plan, discovery/validation split
if used, acceptance/safety thresholds, terminal outcomes, sample-size
calculation, and privacy/consent/retention approval.

No post-validation retuning is allowed. If discovery is used, it may select one
predeclared candidate; untouched validation evaluates that candidate only.

## 8. Primary metrics

Required metrics are positive predictive value (claim precision), false-claim
rate, coverage, abstention rate, and uncertainty intervals. Recall/sensitivity
is secondary. Accuracy alone is not an acceptance metric.

High abstention may be preferable to higher coverage with unsafe false claims.

## 9. Operational definitions

- **True signal:** a candidate fires and independent held-out performance meets
  the separately pre-registered poorer-performance criterion.
- **False claim:** a candidate fires and held-out performance does not meet
  that criterion.
- **Abstention:** a candidate does not fire.

These classifications describe observable performance evidence only; they do
not establish learner cognition or traits.

## 10. Acceptance gate

No numerical acceptance threshold is set here. Before execution, governance
must separately freeze acceptable claim precision, false-claim risk, minimum
useful coverage, and required stability.

Required qualitative properties are materially better-than-trivial/base-rate
prediction, low false-claim behavior, useful nonzero coverage, stability on
untouched validation, no dependence on one pathological item, and compatibility
with uncertainty- and abstention-first semantics.

## 11. Item-validity firewall

Before learner-level analysis, independently check each held-out item for:

- Addition/Natural/directNumeric membership;
- one unambiguous correct answer;
- non-misleading choices;
- no diagnostically confusing or redundant distractor problem relevant to the
  pilot;
- no hidden representation requirement outside the declared context; and
- the intended fixed Easy range.

This is a minimum pilot item audit, not full psychometric validation.

```text
mathematical membership != empirical measurement validity
```

## 12. Sample design

**SAMPLE SIZE REQUIRES PRE-STUDY CALCULATION.**

No participant count is set here. The calculation requires expected
candidate-signal rate, held-out poorer-performance base rate, desired precision
or false-claim uncertainty, discovery/validation allocation if used, and
attrition/exclusion assumptions.

## 13. Data minimization

If separately authorized, the minimum research data is limited to:

- a pseudonymous study/run identifier;
- protocol/envelope version;
- context identifier;
- ordered evidence outcomes: correct, incorrect, or timeout;
- follow-up/phase exclusion flag;
- held-out item-form identifier;
- held-out outcome; and
- required timer/difficulty metadata.

EV-02 does not require player name, account ID, email, full profile,
unnecessary demographics, full gameplay history, submitted answer values, or
response times. A later approved amendment must demonstrate necessity for any
additional field.

## 14. Privacy

**EV-02 DESIGN AUTHORIZES NO DATA COLLECTION.**

Any future real-learner execution needs separate approval for research purpose,
child/privacy requirements where applicable, consent or legal basis where
applicable, storage boundary, retention period, deletion process, and minimum
necessary data.

## 15. Exposure feasibility

Current GameBrain memory is FIFO-bounded to ten observations total. For the
fixed single-operation pilot, this is **FEASIBLE BUT EXPOSURE-LIMITED**; it is
not proof of ordinary-game viability. If future study data do not provide enough
qualifying evidence windows, the outcome is **INCONCLUSIVE**.

Do not increase FIFO capacity, alter question distribution, manufacture
exposure, or change generator behavior automatically.

## 16. Timeout treatment

Timeouts count as errors in the primary candidate rule because evidence and the
held-out assessment share the same controlled per-question time condition. The
timeout count remains separately observable and reportable.

The interpretation is limited to observable poorer performance under that
declared timed condition, not pure mathematical weakness independent of timing.

## 17. Difficulty treatment

The first pilot uses Easy only with adaptive difficulty off. It must not pool
multiple difficulty bands or create a difficulty-adjustment model.

## 18. Terminal outcomes

Exactly one future execution outcome is permitted:

- **VALIDATED_FOR_BOUNDED_CLAIM:** authorizes only a later product-design
  discussion; it does not automatically authorize UI, code, or gameplay
  authority.
- **INCONCLUSIVE:** evidence, precision, or exposure is insufficient; stop and
  do not tune automatically.
- **NOT_VALIDATED:** the simple observable baseline failed; stop.

## 19. Process-channel stop rule

Latency, hints, attempts, and self-correction remain out of scope.
`NOT_VALIDATED` does not authorize another study. A separate future
product/research decision is required before examining one additional channel;
no EV-03 is authorized.

## 20. Intentionally unset execution parameters

The following remain unset until pre-study authorization:

1. exact minimum-exposure candidate values;
2. exact error-proportion candidate values;
3. exact held-out poorer-performance criterion;
4. exact acceptance/safety thresholds;
5. sample size;
6. final item pool;
7. discovery/validation allocation, if needed; and
8. privacy/consent/retention execution approval.

These values are intentionally not invented during protocol design.

## 21. Authority boundary

`mayAffectGameplay = false`. EV-02 does not activate the Real Gameplay
Authority Gate, and no P0 implementation is required by this design freeze.

It authorizes no MeasurementConditions, ObservationProvenance, or
InterventionPurpose implementation; no GameBrain, Adaptive, Weak Skills, or
generator authority; and no production `difficultyEvidence`.

## 22. Finiteness

EV-02 is finite: one target claim, one pilot context, one condition envelope,
one tiny candidate family, one independent reference criterion, predeclared
metrics, and three terminal outcomes.

It must not expand automatically into threshold tuning, process channels, a
larger model, ML, or a decoder program.
