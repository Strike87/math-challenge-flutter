# GB-PREVIEW-01 — GameBrain Interpretation Shadow Experiment

## 1. Status and authority

```text
Contract ID      = GB-PREVIEW-01
Contract version = 1.0
Contract status  = FROZEN
```

Implementation remains NOT AUTHORIZED.

GB-PREVIEW-01 is a finite synthetic interpretation-architecture preview. It is not empirical learner validation, P1-F01 confirmatory evidence, EV-02 execution, production EST, learner diagnosis, gameplay policy, gameplay authority, or a production player model.

```text
mayAffectGameplay             = false
real player data              = prohibited
production Study capture      = OFF / NOT AUTHORIZED
confirmatory window           = CLOSED
player-model persistence      = prohibited
policy activation             = prohibited
canonical gameplay mutation   = prohibited
production EST implementation = prohibited
telemetry / analytics         = prohibited
new evidence collection       = prohibited
```

Only deterministic, synthetic, test-style fixtures are permitted. A result has `authority = NONE` and cannot be consumed by canonical execution.

## 2. Purpose and non-goals

The experiment asks whether an interpretation layer can distinguish bounded synthetic evidence situations, explain its basis, expose uncertainty or contradiction, and abstain when appropriate more usefully than an accuracy-only baseline.

Truthful evidence flows only through interpretation/scenario reasoning, then any future player-experience model, future decision context or policy, authority, and canonical execution. Interpretation is neither policy, authority, nor execution. GameBrain remains central intelligence, not central authority.

The experiment must not infer misconception, intelligence, ability trait, motivation, cognitive mechanism, learning disability, stable learner characteristic, or causal explanation.

## 3. Taxonomy freeze

### Interpretive scenario hypotheses

| Hypothesis | Bounded meaning |
|---|---|
| `ProductiveChallengeCandidate` | Supplied performance is generally successful while supplied challenge or friction signals remain meaningful but not overwhelming. |
| `OverchallengeCandidate` | Convergent supplied evidence indicates persistently poor performance under the supplied challenge/friction conditions in this synthetic context. |
| `UnderchallengeCandidate` | Supplied evidence shows consistently strong performance with insufficient supplied challenge evidence. |
| `RecentImprovementCandidate` | The supplied recent segment is materially better than the supplied earlier segment; this does not claim durable improvement. |

### Cross-cutting epistemic states

`SparseEvidence` and `ConflictingEvidence` are evidence states, not educational scenarios. Sparse evidence lacks enough supplied material for a substantive scenario interpretation. Conflicting evidence materially supports incompatible interpretations, so the result must expose both rather than force a scenario winner.

For the same evidence scope, `ProductiveChallengeCandidate`, `UnderchallengeCandidate`, and `OverchallengeCandidate` are mutually incompatible primary challenge-state interpretations. `RecentImprovementCandidate` is temporally orthogonal and may coexist with any of them; that coexistence alone is not `CONFLICTING`. `CONFLICTING` requires materially incompatible support for interpretations that cannot simultaneously describe the same declared evidence scope.

## 4. Synthetic input contract

Every field has provenance `SYNTHETIC_FIXTURE`. The conceptual fixture shape permits only: evidence count; correct, incorrect, and timeout counts; accuracy derived from those counts; synthetic latency category; supplied earlier-versus-recent summary; optional supplied segmentation; declared context identifier; and explicit missing fields.

Synthetic latency is exactly one of `LOW`, `MODERATE`, `ELEVATED`, or `MISSING`. It is a categorical fixture input only.

The input reconciliation invariants are:

```text
evidenceCount = correctCount + incorrectCount + timeoutCount
accuracy      = correctCount / evidenceCount
```

Accuracy is derived only and is never independently supplied. When segmentation exists, segment evidence, count, and outcome totals must partition and reconcile exactly to aggregate totals. Missing fields must be explicitly declared.

Fixture IDs and context IDs are opaque identifiers. Their string contents must never be interpreted as evidence or used to infer a scenario.

### Test-oracle firewall

Interpreter input consists only of the fields explicitly authorized by this section. The following are test/oracle metadata only and MUST NOT be provided to, inspected by, or influence the interpreter: fixture title; fixture ID; baseline result; expected `interpretationState`; expected `primaryScenario`; expected `plausibleAlternatives`; expected `supportingEvidence`; expected `contradictingEvidence`; expected `missingEvidence`; forbidden interpretation; rationale; and expected-outcome matrix entries. Fixture IDs may be used only by the external test harness to identify a case.

### Segment shape and ordering firewall

When segmentation exists, each segment may contain only `evidenceCount`, `correctCount`, `incorrectCount`, `timeoutCount`, and a synthetic latency category. Segment identifiers and presentation order are opaque. No temporal relationship may be inferred from a segment name, A/B label, alphabetical ordering, list ordering, or presentation order. Earlier/recent semantics exist only when explicitly declared by the fixture. Aggregate/segment reconciliation invariants remain mandatory.

It forbids raw answers, identity, real timestamps, hidden state, learned weights, and pseudo-probability. Synthetic latency and timeout inputs do not authorize production response-time capture, timing-derived inference, changes to canonical timing rules, P1-F01 timing evidence, or EV-02 process-channel expansion.

## 5. Interpretation output contract

Each result contains conceptually:

- `primaryScenario`: optional interpretive scenario hypothesis;
- `interpretationState`: `SUPPORTED`, `MIXED`, `INSUFFICIENT`, `CONFLICTING`, or `NO_CLEAR_MATCH`;
- `supportingEvidence`, `contradictingEvidence`, and `missingEvidence`;
- `evidenceSufficiency`: `LOW`, `MODERATE`, or `HIGH` evidence sufficiency only;
- `plausibleAlternatives`;
- an explanation derived only from supplied fixture fields; and
- `authority = NONE`.

These ordinal terms are neither calibrated confidence nor probability. Multiple scenarios may remain plausible. A primary scenario is allowed only when supplied evidence clearly supports it relative to alternatives.

Frozen interpretation-state semantics:

- `SUPPORTED` = one primary scenario is positively supported and no material contradictory supplied evidence remains.
- `MIXED` = one primary scenario remains best supported, but material contradictory supplied evidence also exists without co-equal incompatible support.
- `NO_CLEAR_MATCH` = evidence is sufficient for assessment, but no scenario hypothesis has justified support as primary.
- `INSUFFICIENT` = supplied evidence is insufficient for substantive scenario assessment.
- `CONFLICTING` = materially incompatible scenario interpretations have co-existing support and no justified aggregate winner.

## 6. Accuracy-only baseline

The frozen comparison baseline inspects aggregate accuracy only:

| Aggregate accuracy | Baseline result |
|---|---|
| at least 80% | `HIGH_PERFORMANCE / POSSIBLY_HARDER` |
| at least 60% and below 80% | `KEEP_CURRENT` |
| below 60% | `LOW_PERFORMANCE / POSSIBLY_EASIER_OR_REVIEW` |

These are preview comparison scaffolding only: not production thresholds, empirically validated thresholds, or GameBrain production policy. Fixtures must not be designed merely to defeat this baseline.

## 7. Eight frozen fixtures

The following expected outcomes are frozen before implementation. Counts define aggregate accuracy as `correct / evidence count`; they are synthetic supplied values, not player observations.

### GBP01-F01 — baseline agreement / UnderchallengeCandidate

Supplied evidence: 20 observations; 18 correct, 2 incorrect, 0 timeouts; latency `LOW`; segmentation explicitly absent; declared context `GBP01-CTX-A`; no other missing fields. Baseline: `HIGH_PERFORMANCE / POSSIBLY_HARDER`. Expected: `SUPPORTED`, `primaryScenario = UnderchallengeCandidate`, alternatives none, sufficiency `HIGH`.

Supporting: sustained strong accuracy, low latency, and no supplied friction. Contradicting: two incorrect observations. Missing: richer challenge-demand measure. Forbidden: `ProductiveChallengeCandidate`, diagnosis, or gameplay recommendation. Rationale: this is the baseline-agreement case, not a claim about a learner trait.

### GBP01-F02 — ProductiveChallengeCandidate counterfactual

Supplied evidence: 20 observations; 18 correct, 2 incorrect, 0 timeouts; latency `ELEVATED`; segmentation explicitly absent; declared context `GBP01-CTX-A`; no other missing fields. Baseline: `HIGH_PERFORMANCE / POSSIBLY_HARDER`. Expected: `MIXED`, `primaryScenario = ProductiveChallengeCandidate`, no plausible scenario alternative, sufficiency `MODERATE`.

Supporting: strong aggregate accuracy and elevated latency. Contradicting: zero timeouts; only two incorrect observations do not independently corroborate a broader high-friction outcome pattern. Missing: independent non-time-pressure challenge evidence. Forbidden: `UnderchallengeCandidate`, diagnosis, or a causal claim. Rationale: identical accuracy to GBP01-F01 permits a different bounded interpretation because the supplied friction differs.

### GBP01-F03 — OverchallengeCandidate

Supplied evidence: 20 observations; 8 correct, 6 incorrect, 6 timeouts; latency `ELEVATED`; segmentation explicitly absent; declared context `GBP01-CTX-A`; no other missing fields. Baseline: `LOW_PERFORMANCE / POSSIBLY_EASIER_OR_REVIEW`. Expected: `SUPPORTED`, `primaryScenario = OverchallengeCandidate`, alternatives none, sufficiency `HIGH`.

Supporting: low aggregate accuracy, frequent timeouts, and elevated latency converge. Contradicting: eight correct observations. Missing: independent contextual explanation. Forbidden: an ability, motivation, or causal claim. Rationale: the scenario requires convergent supplied signals, not one weak signal.

### GBP01-F04 — RecentImprovementCandidate

Supplied evidence: 20 observations; 12 correct, 8 incorrect, 0 timeouts. Earlier segment: 10 observations, 2 correct, 8 incorrect, 0 timeouts. Recent segment: 10 observations, 10 correct, 0 incorrect, 0 timeouts. Latency `MODERATE`; declared context `GBP01-CTX-A`; no missing fields. Baseline: `KEEP_CURRENT`. Expected: `SUPPORTED`, `primaryScenario = RecentImprovementCandidate`, plausible alternatives none, sufficiency `MODERATE`.

Supporting: the supplied recent segment is materially better than the supplied earlier segment. Contradicting: none supplied. Missing: additional ordered segments needed to assess durability. Forbidden: stable mastery, long-term trend, causal learning, or future persistence. Rationale: the conclusion is limited to the supplied earlier-versus-recent contrast.

### GBP01-F05 — SparseEvidence

Supplied evidence: 2 observations; 2 correct, 0 incorrect, 0 timeouts; latency `MISSING`; segmentation and declared context explicitly missing. Baseline: `HIGH_PERFORMANCE / POSSIBLY_HARDER`. Expected: `INSUFFICIENT`, no primary scenario, plausible alternatives none, sufficiency `LOW`.

Supporting: two correct observations. Contradicting: none supplied. Missing: sufficient quantity, latency, segmentation, and context. Scenario hypotheses are not assessable from the supplied evidence. Forbidden: every substantive scenario and every recommendation. Rationale: sparse supplied evidence requires abstention despite the baseline output.

### GBP01-F06 — ConflictingEvidence

Supplied evidence: 20 observations; 14 correct, 0 incorrect, 6 timeouts; derived aggregate accuracy = 70%; aggregate latency `MISSING`; declared context `GBP01-CTX-A`. Segment A: 10 observations, 10 correct, 0 incorrect, 0 timeouts, latency `LOW`. Segment B: 10 observations, 4 correct, 0 incorrect, 6 timeouts, latency `ELEVATED`. No temporal ordering is supplied between Segment A and Segment B. Baseline: `KEEP_CURRENT`. Expected: `CONFLICTING`, no primary scenario, plausible alternatives `UnderchallengeCandidate` and `OverchallengeCandidate`, sufficiency `MODERATE`.

Supporting: Segment A supports an underchallenge interpretation through strong performance and low latency. Contradicting: Segment B supports an overchallenge interpretation through frequent timeouts and elevated latency. These supplied segments support materially incompatible whole-context challenge-state interpretations. Missing: context that resolves the conflict. `RecentImprovementCandidate` must not be inferred because no earlier/recent ordering is supplied. Forbidden: a forced winner. Rationale: conflict is an epistemic state, not a scenario label.

### GBP01-F07 — adversarial noisy control

Supplied evidence: 20 observations; 15 correct, 5 incorrect, 0 timeouts; latency `ELEVATED`; segmentation explicitly absent; declared context `GBP01-CTX-A`; no other missing fields. Baseline: `KEEP_CURRENT`. Expected: `NO_CLEAR_MATCH`, no primary scenario, plausible alternative `ProductiveChallengeCandidate`, sufficiency `MODERATE`.

Supporting: elevated latency is one supplied friction signal. Contradicting: zero timeouts; five incorrect observations prevent a strong-success interpretation. Missing: segmentation; corroborating challenge/friction evidence. Forbidden: `ProductiveChallengeCandidate` as a winner or any over-interpretation. Rationale: extra signals that are noisy or non-decisive must not create a substantive label.

### GBP01-F08 — low accuracy without OverchallengeCandidate

Supplied evidence: 20 observations; 11 correct, 9 incorrect, 0 timeouts; latency `LOW`; segmentation explicitly absent; declared context `GBP01-CTX-A`; no other missing fields. Baseline: `LOW_PERFORMANCE / POSSIBLY_EASIER_OR_REVIEW`. Expected: `NO_CLEAR_MATCH`, no primary scenario, no plausible scenario alternative, sufficiency `MODERATE`.

Supporting: low aggregate accuracy. Contradicting: no supplied timeouts, low latency, and no convergent friction evidence. Missing: challenge-demand and contextual evidence. Forbidden: `OverchallengeCandidate` or a recommendation. Rationale: low or moderate accuracy alone is insufficient for OverchallengeCandidate.

## 8. Expected-outcome matrix

| Fixture | Baseline | State | Primary scenario | Required alternatives |
|---|---|---|---|---|
| GBP01-F01 | HIGH_PERFORMANCE / POSSIBLY_HARDER | SUPPORTED | UnderchallengeCandidate | none |
| GBP01-F02 | HIGH_PERFORMANCE / POSSIBLY_HARDER | MIXED | ProductiveChallengeCandidate | none |
| GBP01-F03 | LOW_PERFORMANCE / POSSIBLY_EASIER_OR_REVIEW | SUPPORTED | OverchallengeCandidate | none |
| GBP01-F04 | KEEP_CURRENT | SUPPORTED | RecentImprovementCandidate | none |
| GBP01-F05 | HIGH_PERFORMANCE / POSSIBLY_HARDER | INSUFFICIENT | none | none |
| GBP01-F06 | KEEP_CURRENT | CONFLICTING | none | UnderchallengeCandidate; OverchallengeCandidate |
| GBP01-F07 | KEEP_CURRENT | NO_CLEAR_MATCH | none | ProductiveChallengeCandidate |
| GBP01-F08 | LOW_PERFORMANCE / POSSIBLY_EASIER_OR_REVIEW | NO_CLEAR_MATCH | none | none |

## 9. Explanation, determinism, and anti-overfitting controls

An explanation must list supplied supporting, contradicting, and missing evidence separately. It may not invent hidden causes, traits, or unsupplied evidence.

The same synthetic fixture and contract version must yield identical output. There is no RNG, wall-clock dependency, network, persistence, cross-fixture memory, or mutable hidden state.

The experiment includes a baseline-agreement fixture, a same-accuracy counterfactual pair, an adversarial noisy control, abstention under sparse evidence, and genuine conflict. Expected outcomes are frozen before implementation. Implementation may not be tuned after failures without a `REFINE` decision and a new contract version. Fixture values must not be copied from future implementation thresholds, hardcoded per fixture, or selected so all value appears only by construction against the baseline.

## 10. Success and failure criteria

Success requires all of the following:

1. Same-accuracy counterfactuals differ only where supplied context justifies it.
2. Distinct scenario fixtures are not collapsed into one generic label.
3. Sparse evidence yields `INSUFFICIENT`.
4. Material contradictory evidence yields `MIXED` when one primary scenario remains best supported; materially incompatible co-existing scenario support with no justified winner yields `CONFLICTING`.
5. Every conclusion traces only to supplied evidence.
6. The layer differentiates beyond the baseline where warranted and agrees when extra evidence adds no justified distinction.

Failure includes a substantive sparse-evidence scenario; a forced conflict winner; unsupplied explanation evidence; hidden mutable state; nondeterminism; numeric pseudo-confidence; a gameplay recommendation or authority other than `NONE`; real-player-data dependence; canonical gameplay change; fixture-specific hardcoding; baseline thresholds reused in production; baseline-winning-by-construction; or educational or diagnostic claims beyond supplied evidence.

## 11. GO / REFINE / SIMPLIFY

| Outcome | Frozen rule |
|---|---|
| GO | All frozen fixture expectations and safety, abstention, and contradiction requirements pass; useful justified differentiation beyond baseline is shown; no prohibited inference or authority leak occurs. |
| REFINE | The architecture appears useful but scenario definitions, evidence semantics, or expected outcomes are ambiguous or internally inconsistent. Any refinement requires a new contract version before implementation changes. |
| SIMPLIFY | The scenario layer adds little justified value beyond baseline, depends on brittle arbitrary rules, or creates explanations more complex than the justified discrimination. |

GO does not authorize production integration. It authorizes only a separate implementation-design decision.

## 12. Relationship to existing work and implementation boundary

| Work | Distinct scope |
|---|---|
| P1-SE-EVAL-00 | Protocol-specific Study evidence feasibility/adjudication evaluator. |
| EV-02 | Separately frozen real-data validation design; execution is not authorized. |
| Future EST | Reusable evidence-science/statistical toolkit; not implemented here. |
| GB-PREVIEW-01 | Synthetic interpretation-architecture preview only. |
| Scenario Knowledge Library | Future versioned hypothesis/template layer; not production-authorized here. |

These concepts must not be silently collapsed. No Dart implementation, tests, GameBrain Core/GBI/GameState change, Adaptive or gameplay change, capture activation, persistence, telemetry, production EST, or authority work is authorized by this contract.
