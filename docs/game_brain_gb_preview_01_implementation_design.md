# GB-PREVIEW-01 — Implementation Design

## 1. Status and authority

```text
Design ID                     = GB-PREVIEW-01-IMPL-DESIGN
Design version                = 0.1
Design status                 = FROZEN
Implementation authorization = NOT AUTHORIZED
Ruleset authorization         = NOT AUTHORIZED
mayAffectGameplay             = false
```

This is a finite synthetic, test-only design. Every future interpretation has
`authority = NONE`; it is not policy, execution, real-player behavior, or
production evidence validity.

## 2. Source-contract immutability

The frozen GB-PREVIEW-01 v1.0 experiment contract is upstream and immutable.
This design cannot alter its taxonomy, epistemic or interpretation semantics,
input invariants, latency vocabulary, fixture values or expectations, baseline
thresholds, oracle or segment-ordering firewalls, success/failure or
GO/REFINE/SIMPLIFY semantics, or authority boundaries. Any such change needs a
new experiment-contract version, never an implementation-design workaround.

## 3. Scope and non-goals

The future work is limited to executing the already-frozen eight synthetic
fixtures. This design authorizes neither Dart nor tests, rules, a production
call path, GameBrain Core/GBI/`GameState` changes, Adaptive or mastery changes,
Study capture, confirmatory-window opening, EST, persistence, schemas,
analytics, telemetry, real data, UI, or gameplay mutation.

No generic rule engine, registry, DI/service locator, scenario DSL, ML or EST
abstraction, evidence platform, player model, persistence, or telemetry schema
is proposed. Explicit small immutable types and one pure interpreter are the
whole intended future seam.

## 4. Recommended experiment placement

The future implementation belongs outside `lib/`, under the existing
test-feature convention: `test/features/game_brain/preview/`. Its design-only
targets are `gb_preview_01_types.dart`, `gb_preview_01_interpreter.dart`,
`gb_preview_01_baseline.dart`, `gb_preview_01_fixtures.dart`, and
`gb_preview_01_interpreter_test.dart`.

Production remains unaware of the preview: no import or caller from
`GameState`, the GameBrain facade, GBI, UI, persistence, or telemetry. The
external test harness may read pure preview code only.

## 5. Dependency boundaries

The future acyclic shape is:

```text
preview types  <-  interpreter
preview types  <-  baseline
preview types  <-  fixture/oracle definitions
interpreter + baseline + fixtures/oracle  <-  external tests
```

The interpreter imports neither fixtures, expected outputs/matrix, baseline,
oracle metadata, fixture IDs, nor oracle lookup callbacks. The baseline cannot
affect interpretation. The harness invokes both independently and performs
comparison.

## 6. Input model

Conceptual immutable vocabulary is `PreviewEvidence`, `PreviewSegment`,
`PreviewTemporalRelation`, and `PreviewLatencyCategory` (`LOW`, `MODERATE`,
`ELEVATED`, `MISSING`). Evidence contains only aggregate counts, derived
accuracy, synthetic latency, opaque declared/missing context, optional
segmentation, optional explicit temporal relation, explicit missing fields,
and fixed `SYNTHETIC_FIXTURE` provenance.

Accuracy is derived, never supplied. Context identifiers are opaque: equality
may be preserved, but strings, prefixes, suffixes, names, and literal values
cannot influence interpretation.

`PreviewEvidence` is the sole data object supplied across the interpreter
boundary. The interpreter must not receive fixture IDs, expected outcomes,
oracle labels, baseline labels, fixture metadata, or hidden scenario identity.

## 7. Validation invariants

Before interpretation, fail closed on an invalid fixture construction:

```text
evidenceCount = correctCount + incorrectCount + timeoutCount
accuracy      = correctCount / evidenceCount
```

Counts are non-negative and `evidenceCount` is positive. Where segments exist,
their four totals partition and exactly reconcile to the aggregate. Invalid
input is a harness/design error, not an added `INVALID` interpretation state.

An optional field is **ABSENT** only when it is intentionally not applicable or
not supplied by design; it is **MISSING** only when relevant evidence is
unavailable. A concrete supplied field or evidence family cannot also be
declared missing: this includes context, segmentation, temporal relation, and
every other explicitly supplied evidence family. Such a contradictory
construction fails validation before interpretation; it is neither coerced nor
given a synthetic value.

## 8. Segmentation and temporal model

A segment has only counts, synthetic latency, and an opaque key when required
to bind an explicit relation. Keys, list/presentation order, A/B labels, and
alphabetical order are not evidence. A `PreviewTemporalRelation` names an
`earlierSegmentKey` and `recentSegmentKey`; both must resolve to supplied
segments. Only that relation permits `RecentImprovementCandidate` inspection.

## 9. Output model

Future immutable vocabulary is `PreviewInterpretation`, `PreviewScenario`,
`PreviewInterpretationState`, `PreviewEvidenceSufficiency`, and a small typed
reason/evidence-reference vocabulary. Scenarios are exactly
`ProductiveChallengeCandidate`, `OverchallengeCandidate`,
`UnderchallengeCandidate`, and `RecentImprovementCandidate`. States are exactly
`SUPPORTED`, `MIXED`, `INSUFFICIENT`, `CONFLICTING`, and `NO_CLEAR_MATCH`;
sufficiency is exactly `LOW`, `MODERATE`, or `HIGH`.

An interpretation has optional primary scenario, state, supplied supporting,
contradicting, and missing evidence, sufficiency, plausible alternatives,
typed explanation, and constant `authority = NONE`. It has no confidence,
probability, score, configurable authority, recommendation, or consumer hook.
The first three challenge-state scenarios are mutually incompatible primaries;
recent improvement is temporally orthogonal and does not alone create conflict.

Structural output validity is independent of any future ruleset:

```text
SUPPORTED       => primaryScenario REQUIRED
MIXED           => primaryScenario REQUIRED
INSUFFICIENT    => primaryScenario MUST BE ABSENT
NO_CLEAR_MATCH  => primaryScenario MUST BE ABSENT
CONFLICTING     => primaryScenario MUST BE ABSENT
```

`plausibleAlternatives` remains separate from `primaryScenario`. The
`plausibleAlternatives`, `supportingEvidence`, `contradictingEvidence`, and
`missingEvidence` collections are duplicate-free, set-semantic, and emitted
and compared in canonical stable order. Scenario collections use the canonical
scenario taxonomy order stated above. Evidence and missing-evidence references
use this total canonical typed taxonomy order: (1) supplied aggregate
count/outcome references, ordered `evidenceCount`, `correctCount`,
`incorrectCount`, then `timeoutCount`; (2) supplied derived-accuracy reference;
(3) supplied synthetic-latency reference; (4) supplied declared-context
reference; (5) supplied segmentation reference; (6) supplied temporal-relation
reference; (7) direct missing-field references, ordered
`MISSING_SYNTHETIC_LATENCY`, `MISSING_DECLARED_CONTEXT`, then
`MISSING_SEGMENTATION`; then (8) non-direct missing-evidence references,
ordered `RICHER_CHALLENGE_DEMAND_EVIDENCE`,
`INDEPENDENT_NON_TIME_PRESSURE_CHALLENGE_EVIDENCE`,
`INDEPENDENT_CONTEXTUAL_EXPLANATION`, `ADDITIONAL_ORDERED_DURABILITY_EVIDENCE`,
`INSUFFICIENT_EVIDENCE_QUANTITY`, `CONFLICT_RESOLVING_CONTEXT`,
`ADDITIONAL_SEGMENTATION_EVIDENCE`,
`CORROBORATING_CHALLENGE_FRICTION_EVIDENCE`, `CHALLENGE_DEMAND_EVIDENCE`, then
`CONTEXTUAL_EVIDENCE`. Counts are required/reconciled inputs and accuracy is
derived, so none has a missing-reference type. A reference type appears at
most once in a set. The frozen missing-evidence expectations have this
vocabulary-only coverage: `GBP01-F01` ->
`RICHER_CHALLENGE_DEMAND_EVIDENCE`; `GBP01-F02` ->
`INDEPENDENT_NON_TIME_PRESSURE_CHALLENGE_EVIDENCE`; `GBP01-F03` ->
`INDEPENDENT_CONTEXTUAL_EXPLANATION`; `GBP01-F04` ->
`ADDITIONAL_ORDERED_DURABILITY_EVIDENCE`; `GBP01-F05` ->
`INSUFFICIENT_EVIDENCE_QUANTITY`, `MISSING_SYNTHETIC_LATENCY`,
`MISSING_SEGMENTATION`, `MISSING_DECLARED_CONTEXT`; `GBP01-F06` ->
`CONFLICT_RESOLVING_CONTEXT`; `GBP01-F07` ->
`ADDITIONAL_SEGMENTATION_EVIDENCE`,
`CORROBORATING_CHALLENGE_FRICTION_EVIDENCE`; and `GBP01-F08` ->
`CHALLENGE_DEMAND_EVIDENCE`, `CONTEXTUAL_EVIDENCE`. This mapping proves
vocabulary coverage only; it adds no predicate, threshold, weight, importance,
or fixture-specific scenario branch. This leaves no tie resolved by insertion,
hash/map iteration, fixture order, oracle order, lexical/string sorting, or
implementation accident. The order is serialization/comparison structure only:
it expresses no evidence importance, precedence, weighting, scenario
preference, threshold logic, or ruleset semantics.

## 10. Explanation model

Interpreter reasons are typed and each references supplied evidence. Rendered
text, if any, is generated only from those reasons. It may not add hidden
causes, traits, diagnoses, or unsupplied evidence. The reason vocabulary stays
no larger than the frozen fixtures require.

## 11. Baseline isolation

The separate pure accuracy-only baseline returns only the frozen comparison
outputs: at least 80% `HIGH_PERFORMANCE / POSSIBLY_HARDER`; 60% through below
80% `KEEP_CURRENT`; below 60% `LOW_PERFORMANCE / POSSIBLY_EASIER_OR_REVIEW`.
It is comparison output only, is never passed to or imported by the
interpreter, and cannot become a production threshold.

## 12. Oracle isolation

`PreviewEvidence` is the sole interpreter-boundary data. Harness-only
`PreviewFixtureOracle` retains fixture ID, baseline expectation, expected
state/scenario/alternatives/evidence, forbidden interpretations, and rationale.
The interpreter has no reference, pointer, object, ID, callback, import, or
lookup path to it. Fixture IDs are reporting metadata only. No second
interpreter-boundary evidence alias is defined.

## 13. Determinism and state isolation

The same valid evidence, implementation version, and separately frozen ruleset
version must produce identical interpretation. There is no RNG, clock, network,
persistence, device state, cross-fixture memory, static mutable cache,
singleton, ML model, or iteration-order dependence. Collection ordering must
not depend on insertion order, fixture order, hash iteration, map iteration,
test registration order, or oracle ordering; it uses the canonical taxonomies
in section 9.

## 14. Ruleset gap

```text
Ruleset status = UNSET / REQUIRES SEPARATE AUTHORIZATION
```

The frozen fixtures define expectations, not scientifically justified decision
thresholds. Do not derive thresholds from their counts, timeouts, segments, or
baseline; do not use fixture-specific branches, fixture-ID tables, or expected
output matrices. A separate reviewed ruleset must first define independently
justified predicates/thresholds, precedence, ambiguity and abstention handling,
and scenario compatibility. Decision logic remains blocked until then.

## 15. Fixture harness

The future harness owns exactly GBP01-F01 through GBP01-F08, their evidence
construction, expected/forbidden outcomes, baseline and interpreter invocation,
comparison, determinism repetition, and oracle-leakage checks. It supplies only
`PreviewEvidence` to the interpreter and retains fixture IDs solely for
reporting.

## 16. Future test plan

After separate authorization, test only frozen-fixture conformance; aggregate,
segment, negative-count, and temporal-reference rejection; oracle isolation;
determinism; baseline isolation; no hidden state/order dependence; temporal
firewall; and forbidden outputs (confidence, gameplay recommendation,
non-NONE authority, traits, or diagnosis). No tests are created by this design.

## 17. Versioning

```text
Experiment contract      = GB-PREVIEW-01 v1.0
Implementation design    = GB-PREVIEW-01-IMPL-DESIGN v0.1
Future ruleset           = separate version / NOT YET AUTHORIZED
Future implementation    = separate version / NOT YET AUTHORIZED
```

Implementation cannot silently mutate the experiment contract; ruleset changes
need ruleset review/versioning; fixture or expected-outcome changes require a
new experiment-contract version.

## 18. Relationship to existing architecture

GameBrain remains central intelligence, not central authority. This preview is
not production GameBrain Core, GBI, P1-SE-EVAL-00, EV-02, EST, or a Player
Experience Model. It creates no production evidence validity or product
authority and preserves the closed Study/confirmatory boundaries.

## 19. Implementation authorization gate

This design becoming FROZEN does **not** authorize implementation. Future Dart
implementation requires all of: (1) this design frozen; (2) a separately frozen
preview ruleset; (3) explicit implementation authorization; (4) exact file
scope predeclared; (5) no production call path; (6) no gameplay authority;
(7) no real player data; and (8) `mayAffectGameplay = false`.

Until that gate is explicitly approved, implementation remains **NOT
AUTHORIZED**.
