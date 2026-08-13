# BRAIN-07A — Context Evidence Advisory Production Contract

## Status and purpose

BRAIN-06 is CLOSED with terminal result **MET — IRREDUCIBLE OBSERVABLE
OVERLAP**. No further BRAIN-06 synthetic-decoder research is authorized.

The termination result establishes irreducible observable overlap only under
the frozen E3-P synthetic response process and the observable channels modeled
in that program, principally correctness, submitted response, and mathematical
context. It does not establish the magnitude or inevitability of such overlap
in real learners or under additional empirically validated observable
channels.

Historical synthetic measurements remain non-empirical. They do not calibrate
human performance, authorize a decoder, establish learner diagnostic truth, or
authorize real-player data collection. BRAIN-07A is complete as design-only
work. BRAIN-07B remains blocked until the authoritative tracker reconciliation
is committed as a separate governance commit.

BRAIN-07 is a bounded product and architecture effort, not a learner-model
experiment. Its purpose is to let `GameBrain` observe gameplay outcomes and
return explainable, uncertainty-preserving **context evidence**. `GameBrain`
is non-authoritative: it may advise the authoritative game, never control it.

This document is the complete BRAIN-07A contract. It authorizes no production
code, gameplay, UI, persistence, generator, routing, threshold, telemetry, or
real-player research-data change.

## Frozen BRAIN-06 conclusions

The following constraints are normative:

1. A wrong answer cannot diagnose a hidden cognitive mechanism.
2. Executable malrules are useful only for response-compatibility, item design,
   collision analysis, and falsification; they are not learner labels.
3. Observable mathematical-context performance is the defensible abstraction.
4. Insufficient evidence is a first-class outcome.
5. A context graph represents mathematical relationships only.
6. A graph edge must never propagate difficulty, counts, or certainty.
7. `NULL` is profile-level and is not a peer local learner state.
8. OOV/background means open response alternatives, not an OOV diagnosis.
9. E3 thresholds are not calibrated for real learners.
10. No E3 decoder is permitted in production.

## Authority and ownership

`lib/features/game_brain/game_brain.dart` remains the thin public facade.
It consumes immutable observations and returns immutable advisory values. It
does not own, mutate, or replace the generator, RNG, `GameState`, canonical
mastery, persistence, Weak Skills scheduling, quests, coins, achievements,
navigation, UI, ads, or IAP.

`GameState` remains the authority for answer processing, timing, scoring,
mastery, adaptive difficulty, persistence, and every external side effect.
An advisory result is not an instruction: an authoritative caller may ignore
it. In particular, BRAIN-07 must not change question selection, difficulty,
remediation, or the Weak Skills plan without separately approved product work.

## Production observation contract

An observation records one completed, already-authoritatively-scored question.
It contains only observable, local values:

- mathematical operation;
- deterministic context key and representation key;
- number type and the existing question difficulty where available;
- correct answer, submitted answer when present, correctness, and timeout;
- response time only when the existing answer path already supplies it;
- references to the existing canonical mastery/Weak Skills values when a
  comparison is requested.

It must not contain a hidden profile, simulator path or regime, inferred
mechanism, personality label, cloud identifier, or cloud-derived profile.
No new personal data may be persisted.

The existing `BrainObservation` contains a larger legacy shape (including
optional operands and mastery before/after). BRAIN-07B may adapt values that
already exist, but must not parse display text, invent operands, or require
new generator data. Missing optional information is represented as missing,
never guessed.

## Context model

A context is a deterministic mathematical descriptor, not a scalar scope or
learner category:

```text
ContextKey = operation + numberType + representation
```

For the present runtime, `directNumeric` requires both the current `Question`
and the existing non-display `GameRunSnapshot`: `runType` must be `normal`,
`questionMechanic` must be `standard`, and the generated question's type must
be one of the four basic operations. That excludes Master, Daily Boss,
Operation Quest, missing-operation, and missing-number runs without parsing
display text or keys. The question still has no retained structured operands
or transformation metadata. Thus the initial vocabulary is only the supported
basic operation × number-type combinations that meet this discriminator.
All other forms are ambiguous and out of scope until their mathematical
representation is explicitly retained by an approved data contract.

This deliberately does not port E3-P contexts. It also means BRAIN-07B cannot
claim operand-specific, sign-specific, inverse-order, or representation-
specific performance from the current runtime question alone.

## Evidence and uncertainty model

Evidence reports what was observed in a context; it never states what a
learner is. A context summary contains at least its key, observation count,
correct count, incorrect count, timeout count, bounded-session status, and
the canonical comparison source when one was actually used.

The existing bounded `BrainSessionMemory` capacity of 10 is retained. It is a
recent, in-memory session window, not a learner history. A future integration
must create and clear it at an explicit run boundary. Longer-term information
is read through adapters to the canonical `skillMap` / Weak Skills data, never
through a parallel learner-profile store.

Existing product eligibility is the only numerical evidence gate authorized
for BRAIN-07: Weak Skills requires at least 10 total basic-operation attempts,
at least 3 attempts for each eligible operation, and its existing mastery
spread rules. Those are product eligibility constraints, not calibrated
diagnostic thresholds. BRAIN-07 must neither copy E3 rules nor convert an E3
score into a production cutoff.

The semantic evidence states are:

| State | Meaning | Required restraint |
| --- | --- | --- |
| `insufficientEvidence` | The evidence cannot support another semantic state. Its reason must distinguish `insufficientExposure`, `insufficientComparisonBasis`, `unsupportedContext`, or another explicitly justified absence. | Make no difficulty or stability claim. |
| `difficultyEvidence` | Existing canonical product evidence validly identifies the context operation as a weak-practice candidate. | Say only that the existing evidence supports practice; do not identify a cause. |
| `stablePerformanceEvidence` | A future approved product rule finds an established, observable context pattern. | BRAIN-07B must not emit this state because no such production rule exists today. |
| `conflictingEvidence` | Eligible observable sources disagree, or related contexts differ without a justified explanation. | Report the difference and recommend verification only; do not choose a hidden cause. |

`insufficientExposure` means that the local observer has not yet seen enough
of a context to describe its performance; it is not a negative finding.
`conflictingEvidence` is a distinct state, not a subtype of insufficient
evidence. An ineligible canonical comparison, missing context data, or an
ambiguous representation uses an explicitly justified insufficient-evidence
reason. BRAIN-07A sets no new numeric exposure threshold and must not alter
question distribution to obtain more observations. BRAIN-07B may only observe
exposure.

There is no fallback diagnosis, best-guess label, confidence percentage, or
synthetic probability.

## Empirical transfer and candidate channels

Synthetic findings are architecture constraints, not human calibration. Before
claiming real-player false-difficulty or false-non-difficulty validity, a
separately approved empirical validation plan must define a legitimate
reference criterion. BRAIN-07A does not invent that reference truth.

Latency, timeout behavior, attempts, self-correction or answer change, and
hint use (only if legitimately available) are future empirical evidence
candidates. None has production diagnostic authority. Each requires evidence
of incremental value beyond the current observable baseline before it may be
used. Their future consideration does not authorize new collection, storage,
telemetry, question distribution changes, thresholds, or inferences.

## Related-context graph

The graph is optional and mathematical only. For a shared number type and
representation, the initial allowed edges are addition ↔ subtraction and
multiplication ↔ division. A future explicit representation transformation may
add an edge only after its source context is represented in production data.

An edge may support the statement that independently observed contexts differ.
It may not copy a local state, add observations, infer unseen performance,
raise certainty, or route the next question. In BRAIN-07B it is read-only and
may produce a verification suggestion only when both endpoints have their own
eligible evidence; otherwise the result is `insufficientEvidence`.

## Advisory and explanation contract

The production-facing vocabulary is evidence-language. Allowed categories are
`insufficientEvidence`, `practiceContext`, `verifyWithRelatedContext`,
`stablePerformance`, `reviewRecentErrors`, and `keepCurrentDifficulty`.
`BRAIN-07B` may exercise only its internal `insufficientEvidence` exposure
semantics. It must not emit, expose, or act on a user-facing advisory result,
including `practiceContext`, `keepCurrentDifficulty`, `stablePerformance`, or
a difficulty-changing recommendation.

Every non-neutral result must include a structured explanation with:

- `reasonCode`;
- primary context and optional independently observed related context;
- evidence count and correct/incorrect/timeout totals;
- comparison basis, if any;
- a human-readable reason made only from those values.

For example: “Practice division because the existing Weak Skills evidence
qualifies division as a weak-practice candidate.” It must not say that the
learner has a misconception or representation deficit. Fixed heuristic
strengths and the legacy `confidence` field are not probabilities and must not
be exposed as production confidence.

## Communication safety and release boundaries

Internal `insufficientEvidence` must never be interpreted in a future UI as
“no difficulty.” The semantic distinction between insufficient exposure,
conflicting or mixed evidence, stable-performance evidence, and difficulty
evidence is frozen. User-facing wording is deferred, but any future UI must
preserve that distinction.

Implementing local shadow logic is not authorization to ship observation
collection to real learners. Any real-player research or data collection
requires a separately approved empirical-validation and privacy plan.

No parent, teacher, or player advisory presentation is authorized until
empirical validity is separately addressed and UNKNOWN/insufficient-evidence
communication has been validated.

## Compatibility audit: BRAIN-01 through BRAIN-05

The pure facade, immutable values, bounded FIFO memory, deterministic policy
seams, and canonical-mastery-first Weak Skills policy remain valid. The
current facade has no production evaluation call site; the existing Weak Skills
advisory adapter is likewise not connected to production scheduling. This
supports a safe shadow-only integration.

BRAIN-02 detectors remain usable only as **response-compatibility** detectors:
“this submitted answer is compatible with rule pattern X.” Their current
`Misconception*` type names are legacy APIs and must not be presented as a
learner attribute. Their operand-dependent rules cannot be evaluated from the
current runtime `Question` without an independently approved structured-
question-data contract.

BRAIN-03 `repeatedMisconception`, `stableUnderstanding`, and `recovering` are
bounded-session heuristic names that overclaim under BRAIN-06. BRAIN-07B must
not surface, consume, or translate them into production learner conclusions.
`insufficientEvidence` remains compatible in meaning. A later, separately
approved migration may introduce neutral response-match/session-signal APIs,
retain old public types as deprecated compatibility shims, and update callers
and tests. This contract does not rename or deprecate existing APIs.

## Shadow-only definition

For this repository, shadow-only means all of the following:

- evaluate at most once after the authoritative answer, mastery, and adaptive
  updates complete;
- retain only the bounded in-memory window for the active run, then discard it;
- do not persist, upload, display, log learner-identifying data, or change
  generated questions;
- discard or test-observe the advisory result without passing it to Weak Skills
  scheduling, game flow, UI, scoring, mastery, timers, navigation, ads, IAP,
  achievements, or quests;
- preserve answer ordering and every frozen behavior contract exactly.

## BRAIN-07B exact implementation scope

After the tracker gate is released, BRAIN-07B may implement only the local,
in-memory, shadow observer needed to exercise this contract. It may only:

1. add the minimal pure immutable exposure-observation values and adapter
   behind the existing `GameBrain` facade;
2. construct/reset one in-memory brain at an explicit new-run/replay boundary;
3. after the authoritative direct-numeric answer path, map already-known
   values into one observation only when the existing run snapshot proves
   `normal` + `QuestionMechanic.standard` and the generated question has a
   canonical basic operation; use no parsed or invented operands, then
   evaluate once;
4. calculate only internal exposure/unsupported-context outcomes and discard
   them without any gameplay integration; and
5. add characterization tests for single evaluation, bounded reset, no
   persistence, no Weak Skills-plan mutation, and unchanged gameplay results.

It may not alter `GameState` authority, persistence keys, Question/generator
shape, BRAIN-02/03 APIs, any frozen gameplay rule, or add analytics. It may
not transmit new telemetry, collect a research dataset, show advisory results
to users, alter gameplay, route questions, calibrate thresholds, claim
real-player diagnostic validity, use an E3 decoder, or add a new evidence
threshold. Contexts outside the defined direct-numeric set must remain an
internal `insufficientEvidence` outcome with an explicit reason.

## BRAIN-07C closure criteria

BRAIN-07C closes only when a review demonstrates that BRAIN-07B:

1. remains pure, local, bounded, immutable at its public boundary, and
   shadow-only;
2. emits only the contract-authorized BRAIN-07B states and explanations;
3. produces `insufficientEvidence` for absent, ambiguous, ineligible, or
   unrepresented data;
4. keeps graph comparisons non-propagating and independently evidenced;
5. does not expose mechanism labels, heuristic confidence, or probabilities;
6. leaves all gameplay, persistence, Weak Skills scheduling, and UI behavior
   unchanged; and
7. passes focused tests, the required non-golden and visual-parity suites,
   analysis, and diff checks.

Closure is a production-contract validation, not another synthetic research
phase. Any request for learner diagnosis, calibrated probabilities, new
thresholds, structured generator metadata, persistence, UI, automated
routing, or real-player research requires a new separately approved product
decision and, for research, an explicit privacy boundary.

## Explicit non-goals and finite roadmap

Non-goals are cognitive diagnosis, learner profiling, cloud data, E3 decoder
transfer, probability claims, graph propagation, automatic adaptation,
generator/routing changes, remediation insertion, UI, persistence, and any
new research experiment.

The finite roadmap is:

1. **BRAIN-07A:** this production contract.
2. **BRAIN-07B:** the exact shadow-only implementation above.
3. **BRAIN-07C:** production-contract validation and closure.

No BRAIN-07D is created automatically. Empirical human validation is not
silently treated as BRAIN-07D; if later approved, it is a separate validation
workstream with its own explicit purpose and privacy boundary. Any other later
phase requires a concrete implementation defect or separately approved product
requirement.
