# GBI-00 — GameBrain Integration Architecture Contract

## Status and scope

GBI-00 is documentation and architecture only. It is based on the closed,
frozen GameBrain v1 Core baseline (`04a90b3`, `feat: complete GameBrain v1
shadow core`). It authorizes no gameplay integration, production Flutter
change, GameBrain Core change, telemetry, persistence, UI, research, commit,
or push.

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
become a GBI switchboard. A future call site is one thin boundary returning an
authorized request or no-op. Core never mutates `GameState` or canonical
subsystem state directly. The current shadow-only post-authoritative
observation remains unchanged.

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

## Future structure and GBI-01 philosophy

No structure is created now. A concrete approved need may add the smallest
necessary code beneath `lib/features/game_brain/integration/`, using only the
existing public Core contract plus the owning subsystem's public contract. This
is a placement convention, not an adapter framework.

Do not pre-commit to a long GBI-02…GBI-08 roadmap. GBI-01 may be created only
around one concrete use case selected for product value, coupling risk, safety,
and architectural learning value. It implements only the minimum foundation
that use case proves necessary, followed by architecture review before any
incremental expansion.

## Synthetic research firewall

Integration does not increase evidence validity. It must not transfer Y2, AA1,
AA2, E3-P probabilities, synthetic truth labels, simulator regimes, synthetic
decoder thresholds, or other synthetic research assumptions into production
authority. Core evidence remains bounded by the BRAIN-07 production contract.

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

## GBI-00 gate result

**MET for architecture-contract work.** Core remains unchanged and limited to
evidence/advisory semantics; GBI owns gameplay interpretation; capabilities
and constraints are external; subsystem authority is intact; illegal influence
fails closed; and the design remains testable without speculative machinery.

Gameplay integration, including GBI-01, remains unauthorized.
