# GBI-00 — GameBrain Integration Architecture Contract

## Status and scope

GBI-00 is documentation and architecture only. It is based on the closed,
frozen GameBrain v1 Core baseline (`04a90b3`, `feat: complete GameBrain v1
shadow core`). It did not authorize gameplay integration, production Flutter
change, GameBrain Core change, telemetry, persistence, UI, or research.

GBI-01 is now complete as a shadow-only Adaptive interpretation foundation.
It adds a discarded post-observation interpretation, but it grants no gameplay
authority and does not change the authority or evidence semantics of the Core
observation.

The existing `GameBrain` facade and BRAIN-06/BRAIN-07 uncertainty semantics
remain stable. GBI-00 adds no Dart types, files, directories, adapters,
capabilities, registries, factories, or placeholders.

## Ownership and flow

```text
GAMEBRAIN CORE: evidence/advisory — “What does the evidence say?”
  -> immutable public evidence/advisory view
GBI: interpretation — “What product action might this justify?”
  -> integration-owned intent
AUTHORITY/CAPABILITY: “Is it permitted here?”
  -> authorized request or no adaptation
EXISTING SUBSYSTEM: “How does it happen?”
```

Core owns educational evidence semantics. GBI owns gameplay-oriented
interpretation. Existing domains own execution. Neither a Core advisory nor a
GBI integration intent is a gameplay command.

## Frozen Core and dependency boundary

Core must not import `GameState`, concrete modes, generator or distractor
implementations, adaptive implementation, Weak Skills, Skill Dashboard/UI,
Operation Quest, Master, Daily Boss, persistence, or analytics. Core has no
mode-specific conditionals.

Gameplay must not inspect Core memory, reasoning internals, detectors, private
evidence state, or research types. Communication uses only immutable public
boundaries. Integration may depend on public Core output and a specific
subsystem's public contract; it bypasses neither.

GBI-00 must not put `DifficultyIntent`, `VerificationIntent`,
`PracticeIntent`, `GeneratorIntent`, `DistractorIntent`, `ModeIntent`,
`BossIntent`, `QuestIntent`, or `HintIntent` into Core. A proposed Core
change must pass this test: would the concept belong in GameBrain if the
current gameplay subsystem did not exist? If not, it belongs in GBI or the
subsystem. Gameplay needs alone never justify a Core change.

## Integration-owned intent, capabilities, and constraints

Use the frozen Core's existing immutable public advisory/evidence output
wherever sufficient: observable mathematical context, evidence availability or
uncertainty status, bounded explanation, and other already-authorized public
advisory information. Core does not know the resulting gameplay action,
consumer subsystem, active mode, or whether verification, hints, difficulty,
or Weak Skills are product concepts.

A future GBI interpretation policy may combine public advisory, externally
supplied capabilities, and current mode/subsystem context to derive a minimal
immutable integration intent. Candidate intent families—difficulty direction,
context preference, verification, practice, and distractor preference—are
examples only. They are not implemented or frozen by GBI-00.

Capabilities answer whether a class of influence is allowed at all. Constraints
answer whether a specific request is legal now, including the current stage,
operation, representation, difficulty envelope, timing, progression, and
fairness limits. Both are external to Core. Keep any future capability model
small and justified; do not create a flag matrix.

An authority guard returns an immutable accepted request, explicit rejection,
or `noAdaptation`. Insufficient or conflicting evidence, unsupported context
or intent, missing adapter, unavailable capability, illegal constraint, and
ambiguous mapping all fail closed to `noAdaptation`; they are never coerced
into nearby behavior. Internal reason codes are testable but are not telemetry,
analytics, cloud logging, research data, or user-facing explanation.

## Coordinator, policy, adapter, and GameState

A future coordinator is optional and must be created with explicit
dependencies. It may receive public advisory, obtain capabilities/constraints,
invoke GBI interpretation, route one authorized request to an explicit adapter,
and return a deterministic immutable result. It must not be a singleton,
service locator, mutable learner store, second `GameState`, global registry,
giant mode switch, or cross-feature rule dump.

Adapters translate. Authority policies constrain. Existing domains execute.
Adapters do not recreate domain engines or call one another. Cross-subsystem
composition, if ever needed, belongs in an explicit higher policy layer.

`GameState` remains authoritative for mutation, timing, persistence,
navigation, and side effects, but must not interpret GameBrain evidence or
become a GBI switchboard. An authority-capable call site must remain one thin
boundary returning an authorized request or no-op. Core never mutates
`GameState` or canonical subsystem state directly. The Core observation
remains shadow-only and post-authoritative; GBI-01 now performs one
post-observation Adaptive interpretation whose decision is discarded.

Every future integration component must be unit-testable with fake public
advisory, capabilities, constraints, and owning subsystem contracts—without
Flutter UI, Firebase, networking, full `GameState`, or a complete session.

## Subsystem boundaries

Question Generator owns operands, correct answer, legal form, RNG,
mathematical validity, and mode generation constraints. Neither Core nor GBI
constructs raw questions. Distractor Generator owns legal distractor
construction; response compatibility is not learner-mechanism truth, and no
diagnosed-misconception semantics enter production.

Adaptive Difficulty remains canonical. GBI may eventually propose a bounded
increase/hold/decrease only if separately justified and authorized; Core need
not know this action exists. No adapter copies mastery calculation, EMA,
thresholds, transitions, or Expert/Insane behavior.

Canonical mastery remains the Weak Skills source of truth. GBI may interpret
evidence into a practice-oriented proposal, but Weak Skills retains ranking,
scheduling, focus locking, canonical mastery use, and progression. No duplicate
weak-skill score or parallel mastery exists.

Skill Dashboard is a read integration, not a gameplay adaptation adapter:

```text
Canonical mastery + public GameBrain evidence view -> presentation read model -> Skill Dashboard
```

It never accesses private memory, reasoning, raw malrules, or mutable
GameBrain state. Mastery value remains distinct from evidence status.

## Candidate mode envelopes

These are expected constraints and candidate envelopes only, not production
capability values or authorization. Every concrete integration must audit the
existing behavioral contract.

| Consumer | Non-overridable invariants | Candidate envelope / constraints |
| --- | --- | --- |
| Standard | Existing rules, scoring, count, configuration. | Broadest candidate envelope; no direct mutation or generator construction. |
| Blitz | 60-second timer and uninterrupted flow. | Only pre-question behavior that cannot delay or reshape timing. |
| Combo | 90-second timer, streak, multipliers. | Only non-disruptive preferences. |
| Death | One-error terminal rule and failure cost. | Avoid aggressive diagnostic probing or increased failure cost. |
| Survival | Lives, five-correct phases, ten-correct boss cadence, rewards. | Only phase-compatible preferences; never alter progression. Preserve the unsupported Survival + Master reference branch. |
| Master | Authored stage operation, difficulty envelope, boss rules. | Normally none; never override stage or authored content. |
| Daily Boss | Fixed daily configuration, challenge, reward. | Normally none; no personalization of daily content/reward. |
| Operation Quest | Authored trail, stage, forms, progress. | Normally none; never override stars or progression. |
| Two-player | Per-player turns/counts and fairness. | Only symmetric, separately fairness-reviewed behavior; no personal asymmetry or leakage. |

Master, Daily Boss, and Operation Quest are existing challenge/run
configurations rather than all ordinary `GameMode` values.

## Extensibility tests

**Tournament Mode:** it declares external capabilities and fixed
fairness/timing constraints, reuses an existing GBI interpretation if legal,
and otherwise returns `noAdaptation`. Core changes: zero.

**Hint Engine:** `public Core evidence -> GBI interpretation ->
HintIntegrationIntent -> Hint capability/policy -> HintAdapter -> Hint Engine`.
Core changes: zero unless an independently justified new educational evidence
concept is missing. The Hint Engine reads no Core internals.

## Current structure and incremental philosophy

GBI-01 added the smallest concrete boundary beneath
`lib/features/game_brain/integration/`, using only the existing public Core
contract. Its authority is permanently disabled and its decision is discarded.
This placement remains a convention, not an adapter framework.

Do not pre-commit to a long GBI-02…GBI-08 roadmap. No additional integration
follows automatically. Each concrete use case must be separately selected for
product value, coupling risk, safety, and architectural learning value, then
implement only the minimum its approved scope proves necessary.

## Synthetic research firewall

Integration does not increase evidence validity. It must not transfer Y2, Y3,
AA1, AA2, E3-P probabilities, synthetic false-claim rates, synthetic regimes,
simulator truth labels, synthetic decoder thresholds, or other synthetic
research assumptions into production authority. Core evidence remains bounded
by the BRAIN-07 production contract.

## GAMEBRAIN REAL GAMEPLAY AUTHORITY GATE

This is the authoritative conceptual gate before any future GBI integration
may move from conceptual `shadowOnly = true` to
`mayAffectGameplay = true`. Those expressions name target authority states,
not existing Dart fields or capabilities. All applicable requirements below
must be satisfied through an explicit review before real gameplay authority
can be enabled.

The governing separation is:

```text
research finding != architecture prerequisite != implementation work
```

A research result may identify a prerequisite. It neither proves that the
prerequisite is met nor authorizes implementation. This gate does not reopen
BRAIN-06, change GameBrain Core, add evidence channels or provenance
infrastructure, enable Adaptive execution, change question distribution, add
machine learning, or start empirical research.

### A. Measurement conditions

Relevant conditions under which evidence was produced must be represented,
explicitly controlled, or demonstrated irrelevant for the proposed use.
Potential conditions include mode, timed or untimed play, answer format,
session phase, assistance state, and other justified measurement conditions.
No field is required or authorized by this document. Important conditions
under which evidence was produced must not be erased.

Evidence must not be assumed invariant across modes or conditions. The gate
also forbids unsupported heuristic weights such as treating a Blitz wrong
answer as weaker evidence. Any such weighting requires empirical
justification.

Measurement conditions and provenance are separate:

- Measurement conditions answer, "Under what conditions was the response
  produced?" For example: Standard, untimed, Choice4.
- Observation provenance answers, "Why was this measurement opportunity
  presented?" For example: conceptual `normalGameplay` or
  `gameBrainVerification` provenance.

The same conditions may occur under different provenance. A future
implementation may store both in one metadata object, but it must not merge
their semantics.

### B. Item and context validity

An item/context relationship used by an authority-capable intervention must
have a defensible measurement basis:

```text
mathematical membership != empirical measurement validity
```

An item can mathematically belong to a context without performance on that
item being a reliable measurement of difficulty in that context. This
requirement neither reopens the context ontology nor requires an empirical
study in this documentation task.

### C. Observation and intervention provenance

Before GameBrain-created or adaptive opportunities may affect later evidence
interpretation, the system must be able to preserve why each measurement
opportunity occurred. Conceptual future labels might include
`normalGameplay`, `authoredMode`, `adaptiveEngine`, `weakSkillsPractice`,
`gameBrainIntervention`, or another explicitly defined source.

This is future-only semantics, not a Dart type or current implementation
requirement. Evidence influenced by GameBrain or another adaptive subsystem
must not later be silently treated as naturally occurring evidence. If an
intervention is authorized in the future, its provenance must remain available
to later interpretation.

### D. Evidence availability

An authority-capable integration must preserve the semantic distinction among
insufficient exposure, conflicting or mixed evidence, stable-performance
evidence, and difficulty evidence. A gameplay action being available does not
manufacture certainty:

```text
absence of evidence != evidence of absence
```

These are authority-gate semantics, not a claim that the current
`ContextEvidenceStatus` enum represents every state.

### E. Synthetic authority firewall

No BRAIN-06 or E3 synthetic artifact gains gameplay authority automatically.
Y2, Y3, AA1, AA2, E3-P probabilities, synthetic false-claim rates, synthetic
regimes, simulator truth labels, and synthetic decoder thresholds are all
prohibited from direct production authority. GBI architecture does not upgrade
research validity. Future production authority requires separately justified
production or empirical evidence appropriate to the intended use.

### F. Canonical domain authority

Existing game systems remain authoritative. A GameBrain or GBI proposal may
be constrained, rejected, or ignored, and mode/subsystem rules override it.
Adaptive Difficulty owns legal difficulty behavior; Question Generator owns
mathematical construction; Master owns stage rules; Operation Quest owns
authored progression; Survival owns phase and boss progression; Weak Skills
owns its canonical scheduling contract; and `GameState` remains mutation
authority. No recommendation bypasses its owning subsystem.

### G. Fail closed

If any applicable evidence, measurement-condition, provenance, validity,
capability, constraint, or authority requirement is unresolved, the result is
`noAdaptation`. This is the default safety behavior. Completing this
documentation gate does not pass the gate for any subsystem.

### Current shadow-only work

This gate does not block shadow-only architecture work whose gameplay remains
unchanged, decisions are discarded, and GameBrain creates neither an evidence
opportunity nor user-facing diagnostic authority. GBI-01 remains valid exactly
as implemented: its Adaptive decision is discarded, it creates no user
diagnostic or measurement opportunity, and it has no execution authority.

### Target semantic architecture

```text
Item / Context
        +
Measurement Conditions
        +
Observable Response / Process
        +
Evidence Availability
        +
Observation Provenance
        ↓
bounded evidence
        ↓
uncertainty-aware reasoning
        ↓
advisory
        ↓
GBI authority guard
        ↓
possible intervention
        ↓
intervention provenance preserved
```

This is a target semantic architecture, not a current class list or authority
grant. It does not authorize `MeasurementConditions.dart`,
`ObservationProvenance.dart`, `InterventionPurpose.dart`, new Core state,
persistence, telemetry, or adapters. Contract growth must come from concrete
implementation pressure, not speculation.

A future authority-capable decision might need the following semantics:

```text
IntegrationDecision
  evidenceStatus
  interpretationReason
  authorityResult
  result
  interventionPurpose
```

This is a target-only pseudo-schema. It is not the existing
`AdaptiveIntegrationDecision`, does not describe any other current type, and
GBI-01 is not required to implement it.

### Future evidence, exposure, and privacy

Latency, timeout behavior, self-correction or answer revision, attempts, and
legitimate hint use remain candidate channels for future authority use only.
Existing shadow observation does not grant them authority. A candidate channel
is not evidence authority; each would need incremental, stable, and relevant
value beyond the existing baseline before use. Nothing here authorizes new
collection or implementation of those channels.

Insufficient context exposure may eventually be a product or measurement issue
rather than a reasoning failure. Any future audit must measure how much
exposure ordinary gameplay naturally provides per context before deciding
whether question distribution should change. No distribution change is
authorized here.

Nothing in this gate authorizes telemetry, cloud learner profiles, research
datasets, persistent raw learner histories, or collection of new process data.
Future real-player empirical work requires separately approved privacy and
validation scope.

## Phase-1 `chooseDifficulty` contract freeze

This is a documentation-only contract for the first future GameBrain decision
context. It authorizes neither a decision pipeline nor gameplay influence.
`mayAffectGameplay` remains `false`.

### Decision locus and owner

A `chooseDifficulty` opportunity exists only when its canonical owner
explicitly opens an eligible opportunity and supplies the activity/context
snapshot, player-agency constraints, and legal candidates. Multiple difficulty
values existing in an enum or elsewhere in the game never creates an
opportunity. The canonical owner owns opportunity definition and legality;
GameBrain evaluates/reasons only; a future Product/Authority layer may decide
whether a preference can influence gameplay; the canonical system alone
executes any choice.

### Supplied immutable context and candidates

The minimum future immutable `DecisionContext` is:

```text
chooseDifficulty {
  currentExecutedDifficulty
  legalDifficultyCandidates
  operation
  numberType
  answerStyle
  decisionLocus
}
```

`legalDifficultyCandidates` is a canonical, explicitly supplied subset of
`{Easy, Medium, Hard}`. GameBrain evaluates only that supplied subset. It must
not discover or reconstruct legality from enum ordering, numeric values,
labels, historical exposure, scenario knowledge, Adaptive, Master, Quest,
Daily, Weak Skills, or generator rules. If no candidate is supplied, the
future result is `ABSTAIN_NO_LEGAL_OPTIONS`; no alternative is invented.

The Phase-1 envelope is limited to the GEI-04B-supported context: normal,
single-player, Standard, Choice4, standard mechanic, supported ordinary
operation/context, and Easy/Medium/Hard. It excludes Master, Quest, Survival,
Blitz, Combo, Death, two-player, True/False, missing-number,
missing-operation, and every other decision type (including mode selection,
distractor intent, timing, practice, question-generator influence,
answer-format personalization, and activity selection).

### Truthful observation, scenarios, and future boundary

GEI-04B is the current prerequisite: canonical gameplay records an accepted
terminal outcome as bounded, run-local `QuestionExperienceObservation` when
enabled. This contract adds no capture fields, persistence, or new collection.

The later Difficulty Scenario Library may interpret truthful evidence for the
supplied candidates; scenarios do not execute actions. For example,
`OverchallengeCandidate` is evidence compatible with an overchallenge
hypothesis, not an instruction to decrease difficulty. Future scenario use
must preserve supporting and contradicting evidence, missing evidence,
alternative explanations, and epistemic state; its scenario-to-evaluation
synthesis remains independently versioned and gated.

Observed `Medium -> actual outcome` does not establish hypothetical outcomes
for unexecuted Easy or Hard candidates: those remain predicted or unknown, not
observed. Reference opportunities may later preserve comparator exposure but
do not create causal counterfactual truth.

A later, still-unimplemented evaluation may return only `NO_PREFERENCE` or
`PreferredCandidate(difficulty)` from supplied candidates. It does not mutate
`GameState` or execute the choice. DecisionEpisode is required later for
intervention/policy-effect audit; descriptive Experience Memory may later use
truthful natural observations; reproducibility must use bounded
`DecisionEvidenceSnapshot`, stability requires K comparable eligible episodes,
and policy monotonicity is dimension-level rather than candidate-global.

Data governance and Scenario Acceptance Gates precede applicable capture and
evaluation. P1-F00 must preregister quantitative P1-F01 rules, retain a
separation between protocol design and outcome adjudication, obtain an
independent/outside-direct-path review before lock, use prospective amendment
rules, preserve evidence validity envelopes, and never self-declare a MET gate
from implementation alone. Product-complexity review remains distinct from
scientific validity.

## Frozen rules

1. Core knows educational evidence, not concrete gameplay systems.
2. Core imports no concrete gameplay feature; gameplay accesses no Core internals.
3. Communication uses immutable public boundaries.
4. GBI owns gameplay-oriented interpretation and intents by default.
5. Core changes require independent educational-domain justification.
6. Capabilities and constraints live outside Core.
7. Mode/domain invariants override GBI proposals.
8. Adapters translate; policies constrain; domains execute.
9. Adapters never call adapters.
10. GameState is not a GameBrain integration switchboard.
11. New modes and subsystems normally require zero Core changes.
12. No direct GameBrain mutation of canonical state.
13. Unsupported or illegal influence fails closed.
14. Each adapter is independently unit-testable.
15. No singleton, service locator, parallel canonical state, or speculative infrastructure.
16. GBI cannot promote synthetic research into production authority.

## GBI-00 result and current authority status

**GBI-00 MET for architecture-contract work.** Core remains unchanged and
limited to evidence/advisory semantics; GBI owns gameplay interpretation;
capabilities and constraints are external; subsystem authority is intact;
illegal influence fails closed; and the design remains testable without
speculative machinery.

GBI-01 is complete and valid only as a shadow integration: the Core observation
retains no gameplay authority, the added post-observation interpretation is
discarded, and no evidence opportunity or user-facing diagnostic is created.
Real gameplay authority remains unauthorized for every subsystem. Any future
request for `mayAffectGameplay = true` requires explicit review against the
GAMEBRAIN REAL GAMEPLAY AUTHORITY GATE.
