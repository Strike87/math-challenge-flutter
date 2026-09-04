# GameBrain / GEI — Master Design, Governance & Progress Reference — R5.2

**Project:** Math Challenge Flutter  
**Revision:** R5.2 — 2026-09-04 — post-`GB-MEASURE-01F-EXEC` closure + EST restoration  
**Reference purpose:** Single authoritative working reference for the GameBrain / GameBrain Experience Intelligence (GEI) vision, architecture, evidence philosophy, governance, phased implementation plan, falsification gates, scenario framework, current progress, and next authorized work.  
**Status:** Living reference — consolidated through the prior Phase-1/P1-F01 foundations, the later `GB-PREVIEW-01 → GB-MEASURE-01` research path, and the completed `GB-MEASURE-01F-EXEC`. The governed execution ran under exact CPython 3.13.5 / NumPy 2.3.5 / `PCG64DXSM`, completed the frozen oracle and 49×9 screening grid, and produced `NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID` with `0/49` screening survivors. Fresh outcome verification independently reproduced the screening exclusions and decisive S09 result. The current bounded reliable-change capability is therefore **not established** and is **parked** rather than extended into a new recovery/redesign track. `ValidatedChangeReceipt` is not frozen. The project returns to the simplified non-authoritative `GB-PREVIEW-01` intelligence path; `mayAffectGameplay=false`.
**Date:** 2026-09-04  
**Latest reference update:** R5.2 preserves the R5.1 post-`GB-MEASURE-01F-EXEC` closure and restores the previously approved **GameBrain Evidence Science Toolkit (EST)** architecture that was unintentionally absent from the 2026-09-04 R5 consolidation. EST remains a future governed analytical layer, distinct from `P1-SE-EVAL-00`, the Scenario Knowledge Library, the Player Experience Model, and Policy/Authority. Existing Level-1 statistical building blocks are retained as established foundation but are not relabeled as a completed reusable EST product module; Levels 2–6 remain future work, while the reliable-change/change-detection sub-capability attempted through `GB-MEASURE-01` is recorded as `NOT ESTABLISHED / PARKED`. The current task remains `GB-PREVIEW-01-SIMPLIFY-01`; this correction opens no new research gate and changes no gameplay authority.
**Latest remotely verified production GEI baseline:** `25e29301c0eca1d58603d63e774d41df0aeccaf5` — `Add run-local GameBrain question experience capture`  
**Latest reported local production-code baseline:** `232b46c57d86d497cef93f9707ccbe334b4a2189` — `Add P1-F01 opportunity outcome linkage`; reported local/clean, not claimed remote-verified here.  
**Latest reported local project baseline:** `e3a2745131901438c6baa36b4e6e6ca4b98db791` — `Authorize local P1-F01 integrity capture`; reported local/clean, nothing pushed or merged, not claimed remote-verified here.  
**Current next authorized task:** `GB-PREVIEW-01-SIMPLIFY-01 — Minimal Interpreter Vertical Slice`. Use the approved observation-side V2 evidence only; treat reliable measured-change as unavailable; remain synthetic/test-only, non-production, non-authoritative, and `mayAffectGameplay=false`.

---

# 0. How this reference should be used

This document exists so the project never has to reconstruct the GameBrain vision from scattered conversations.

At every milestone, review these five questions:

1. **Where are we in the architecture?**
2. **What is already implemented or MET?**
3. **What remains design-only or scientifically unvalidated?**
4. **What remains explicitly unauthorized?**
5. **What is the one next authorized task?**

The final vision must never be used to justify skipping the current gate.

A future update should preserve the distinction between:

```text
VISION
ARCHITECTURE
MEASUREMENT VALIDITY
DECISION VALIDITY
OPERATIONAL AUTHORITY
IMPLEMENTATION STATUS
```

These are not interchangeable.

### 0.1 Supersession rule for this living reference

Later explicitly approved product-policy updates supersede older product-policy wording in earlier revisions. As of 2026-08-21, the current GameBrain eligibility policy is age-derived product eligibility (`under13 → ineligible`, `13–17/18+ → eligible`, unresolved/invalid/stale → fail closed) and **does not use a parental-approval flow as a current GameBrain prerequisite**. The Age Gate is not verified age, consent, or parental authorization. Any future external legal requirement for a separate consent/parental flow must be introduced as a new governed product decision rather than inferred from older text.

---

# 1. Final role of GameBrain

GameBrain is intended to become **Math Challenge’s central player-experience intelligence layer**.

It observes truthful gameplay facts, remembers bounded experience, recognizes evidence-compatible scenarios, builds an evolving Player Experience Model, evaluates legal candidate experiences, preserves uncertainty and attribution limits, produces bounded typed intents/evaluations for game systems, and learns from provenance-preserving outcomes.

Core definition:

> **GameBrain = Central Intelligence, not Central Authority.**

GameBrain may eventually exert real influence, but final legality and execution remain owned by canonical systems.

## 1.1 What GameBrain is

```text
Intelligence
+ Experience Memory
+ Scenario / Pattern Understanding
+ Player Experience Modeling
+ Candidate Outcome Evaluation
+ Prediction
+ Capability Frontier Exploration Proposals
+ Explainability
+ Personalization Inputs
```

## 1.2 What GameBrain is not

```text
GameState
Question Generator
Adaptive Engine
Weak Skills policy
Master / Quest / Daily rules engine
Navigation owner
Persistence owner
Central rules matrix
Psychological profiler
Service locator
Event bus
Second gameplay authority
```

---

# 2. Responsibility model

```text
GameBrain / GEI
=
Truthful evidence consumption
Memory
Scenario interpretation
Player Experience Model
Candidate evaluation
Structured uncertainty
Structured explanation

Decision-Specific Resolution Policy
=
Trade-off resolution
NO_PREFERENCE / PreferredCandidate
Versioned + independently gated

GBI
=
Consumer-specific translation
Typed communication
Integration boundary

Player Agency
=
Explicit player-intent constraints

Authority
=
Permission / safety / product gates

Canonical Systems
=
Rules
Legality
Constraints
RNG
Mathematical validity
Authoritative mutation
Final execution
```

Every consumer receives a bounded contract. There must never be a giant:

```text
GameBrainDecision {
  doEverything...
}
```

---

# 3. Full closed-loop architecture

```text
PLAYER EXPERIENCE
        ↓
CANONICAL GAMEPLAY
        ↓
TRUTHFUL EXECUTION FACTS
        ↓
QUESTION / RUN OBSERVATIONS
        ↓
WORKING MEMORY
        ↓
RUN SUMMARY
        ↓
LONG-TERM EXPERIENCE MEMORY
        ↓
SCENARIO KNOWLEDGE + PATTERN UNDERSTANDING
        ↓
PLAYER EXPERIENCE MODEL
        ↓
DECISION CONTEXT
        ↓
CANONICAL LEGAL OPTIONS
        ↓
CANDIDATE EVALUATION
        ↓
OUTCOME VECTOR
+ COVERAGE
+ UNCERTAINTY
+ COUNTERFACTUAL STATUS
+ ATTRIBUTION STATUS
+ EXPLANATION
        ↓
DECISION-SPECIFIC VERSIONED POLICY
        ↓
NO_PREFERENCE / PREFERRED INTENT
        ↓
STABILITY GATE
        ↓
PLAYER AGENCY
        ↓
AUTHORITY
        ↓
CANONICAL EXECUTION
        ↓
DECISION EPISODE RESULT
        ↓
OUTCOME + PROVENANCE + PURPOSE
        ↓
MEMORY / MODEL UPDATE
        ↺
```

Side requirement:

```text
EVIDENCE OPPORTUNITY PRESERVATION
```

This exists so GameBrain does not progressively starve itself of evidence about alternatives.

---

# 4. Permanent epistemic philosophy

## 4.1 Behavior understanding, not mind reading

GameBrain may understand:

- what the player did;
- when it happened;
- under what conditions;
- whether it repeated;
- whether it changed over time;
- how it compares with comparable history;
- what happened after a configuration or intervention.

GameBrain must not infer psychological state as fact.

Example:

```text
Observed:
player exits more often after repeated-error sequences

Allowed:
repeated-error exit association candidate

Not allowed:
player becomes frustrated after mistakes
```

Example:

```text
Observed:
errors/timeouts increase late in longer runs

Allowed:
late-run degradation candidate

Not allowed:
player loses concentration
```

## 4.2 Memory is evidence, not identity

Never encode:

```text
badAtDivision = true
slowLearner = true
getsBored = true
guessingPlayer = true
```

Prefer:

```text
current evidence is compatible with...
recent evidence contradicts...
historical pattern no longer supported...
```

Player interpretation must be able to change.

---

# 5. Founding principles D1–D14

## D1 — Longitudinal personalization

Longitudinal personalization is an eventual requirement.

Persistence is not automatically authorized by this requirement.

## D2 — Evaluate, do not directly choose

GameBrain evaluates candidate outcomes. It does not directly own the final configuration choice.

## D3 — Engagement is first-class but distinct

Educational performance and engagement/persistence are separate dimensions.

Neither automatically dominates.

## D4 — Knowledge separation

```text
OBSERVED
≠
PREDICTED
≠
PREFERRED
```

## D5 — Decision Context

GameBrain evaluates only candidates relevant to a specific decision.

Examples:

```text
chooseDifficulty
chooseAnswerFormat
chooseRoundLength
chooseNextActivity
choosePracticeConfiguration
chooseTimingCondition
```

## D6 — Unknown is not bad

```text
NO EVIDENCE
≠
BAD FIT
```

## D7 — Conditioned evidence

Timing, assistance, format, mode, and related conditions are context, not learner labels.

## D8 — Execution ownership

```text
GBI / Product Policy proposes
Authority constrains
Canonical subsystem executes
```

## D9 — Legality and candidate-topology ownership

Canonical systems define legal options. When bounded transition/frontier reasoning needs a structural relationship among legal candidates, the **canonical Decision Owner must also supply that candidate topology** inside the Decision Context.

GameBrain never recreates Master, Quest, Daily, Adaptive, Weak Skills, Generator, or mode legality, and it must not infer candidate adjacency from enum order, labels, numeric values, or historical exposure.

Canonical adjacency/topology means only a structural transition relationship. It does **not** itself establish pedagogical suitability, experience fit, player capability, or authorization to explore. Those remain evidence/policy/agency/authority questions.

## D10 — Bounded memory

Long-term memory stores bounded summaries/evidence, not infinite raw event history.

## D11 — No universal magic score

Educational value, engagement, timing, assistance, uncertainty, and development are not collapsed into one universal scalar.

## D12 — Execution trace

Preserve:

```text
OBSERVED
→ PREDICTED
→ PREFERRED
→ AUTHORIZED
→ EXECUTED
```

## D13 — Memory is evidence, not identity

Historical evidence remains historical; current interpretation may change.

## D14 — Closed-loop learning with provenance

Executed interventions may feed outcomes back into memory, but the system must preserve how the exposure arose.

---

# 6. Falsification requirements F1–F11

## F1 — Decision traceability

Can prediction → preference → authorization → execution → outcome → update be traced?

## F2 — Counterfactual safety

Can observed outcomes remain distinct from predicted unexecuted alternatives?

## F3 — Attribution safety

Can combined-condition outcomes remain non-causal when cause is unresolved?

## F4 — Stability

Can personalization avoid reacting to small fluctuations?

## F5 — Minimum sufficient intervention

Can policy request the smallest justified change rather than unnecessary bundles?

## F6 — Player agency

Can explicit player intent constrain personalization independently of technical legality?

## F7 — Outcome horizons

Can immediate experience remain separate from near/long-term development?

## F8 — Explainability

Can evaluations natively retain evidence, missingness, uncertainty, provenance, inferential status, and attribution limits?

## F9 — Fail-safe independence

Can every canonical subsystem operate when GameBrain is absent, unsupported, uncertain, or failing?

## F10 — Self-influence safety

Can the system distinguish natural/player/canonical exposure from exposure GameBrain helped create?

## F11 — Local-Optimum / Capability-Starvation Safety

Can GameBrain become increasingly confident in one currently supported region merely because its own decisions reduce meaningful exposure to a canonical adjacent frontier?

A valid design must not allow:

```text
current region works
→ GameBrain repeatedly keeps the player there
→ canonical adjacent frontier receives little/no exposure
→ uncertainty is mistaken for inferiority
→ confidence in the current region rises mainly because alternatives were starved
```

F11 must preserve the same epistemic lesson as earlier negative-control work: **a policy capable of producing a suspicious starvation pattern in shadow is not proof that GameBrain actually causes starvation in authority-bearing play.** Therefore later validation must distinguish:

```text
SHADOW STARVATION RISK
= policy/self-influence susceptibility before GameBrain has authority

REALIZED STARVATION
= observed self-influence under a bounded authority-bearing pilot
```

F11 is an architecture requirement now, not yet a measurement protocol. Before any runtime authorization of R7, a separately frozen `F11-P00 — Capability-Starvation Measurement Protocol` must preregister eligible/comparable opportunities, candidate-topology availability, reference-track validity, exposure/starvation metrics, missingness/confounding rules, uncertainty, and explicit SAFE / RISK / INCONCLUSIVE outcomes.

If GameBrain cannot preserve a safe path for bounded frontier discovery when authorized, or if F11 cannot be measured without overstating causal attribution, the personalization architecture is incomplete.

---

# 7. Additional mandatory architecture requirements R1–R7

These are requirements, not new D-principles.

## R1 — Evidence Opportunity Preservation

> **GameBrain cannot be the sole author of both the treatment and the evidence used to prove that treatment remains safe.**

Personalization must not consume all future evidence opportunities for comparator alternatives. R1 must preserve two distinct mechanisms:

```text
REFERENCE / CONTROL OPPORTUNITY TRACK
GameBrain authority-bearing influence is withheld so a measurement-valid comparison window can remain available.

EVIDENCE_EXPLORATION BUDGET
GameBrain may later create bounded interventions whose explicit purpose is reducing uncertainty about a comparator.
```

The Reference/Control Track is **not** the Evidence Exploration Budget. A deliberate GameBrain evidence probe cannot serve as the supposedly non-GameBrain reference simply because its purpose is epistemic.

The Reference/Control Track is also **not automatically a causal counterfactual**. Whether it supports causal attribution depends on a separately preregistered design. Without such validity, it supports descriptive comparison/risk detection only.

Permanent direction for later authority-bearing deployment:

```text
Persistent Reference Capacity = REQUIRED
Exact Reference allocation rate/floor = protocol-defined, not frozen now
Permanent Reference capacity ≠ permanent assignment of the same players
Reference presence ≠ Reference validity
```

The Reference mechanism must survive production authority as governed infrastructure for contemporaneous comparison, drift surveillance, starvation/self-influence monitoring, and re-opening previously validated assumptions when they materially change. Its rate may later be reduced, increased, rotated, or redesigned only through the applicable versioned protocol/governance path; reducing effective capacity below a frozen minimum is not ordinary tuning.

## R2 — Counterfactual Discipline

Direct observation, comparable history, generalized inference, and unknown must stay distinct.

## R3 — Attribution Discipline

Multidimensional outcomes may remain unattributed.

## R4 — Resolution Policy Governance

Outcome-vector → preference policies must be versioned, testable, falsifiable, and independently gated.

## R5 — Epistemic Communication Preservation

Human-facing projections must preserve status, coverage, missingness, uncertainty, and attribution limits.

## R6 — Longitudinal Recency / Supersession

Old evidence must be able to lose current authority without destroying historical trajectory.

## R7 — Capability Frontier Exploration

A successful personalization system must not converge permanently on the currently best-supported experience solely because structurally adjacent alternatives remain less observed.

When separately authorized, GameBrain must be capable of proposing **bounded, reversible frontier exploration opportunities** that test whether the player's supported experience envelope can expand.

Exploration must:

```text
preserve OBSERVED vs UNKNOWN
use only legal candidates whose structural adjacency/topology is supplied by the canonical Decision Owner
never infer adjacency from enum order, labels, numeric values, or historical exposure
minimize simultaneous variable changes
preserve player agency
carry explicit CAPABILITY_FRONTIER_EXPLORATION purpose/provenance
operate under an independent Capability Frontier Exploration Budget
remain under a separate Global Exploration Ceiling
keep the frontier budget non-fungible with the Evidence Exploration Budget by default
stop/recover when continuation is not justified
avoid fixed-capability conclusions from one probe
never convert missing evidence into negative evidence
remain subordinate to Product Policy + Authority
leave canonical gameplay functional when rejected/unsupported
```

The frontier budget is a permission ceiling, not a quota: unused capacity never creates an obligation to probe. Any exception to evidence/frontier budget non-fungibility requires a versioned, independently reviewed governance amendment; configuration/tuning alone cannot enable transfer. If such an exception changes the exposure allocation used by a scientific gate, the affected protocol must also be prospectively amended before the changed regime can count as confirmatory evidence.

`F11-P00` and its independent review are mandatory before any R7 runtime authorization. Capability exploration is an intelligence proposal, not autonomous gameplay authority.

---

# 8. Canonical gameplay truth foundation

Before GameBrain can understand a player, the game must first know exactly what happened.

A presented question should follow:

```text
PRESENTED
   ↓
ACTIVE
   ↓
EXACTLY ONE TERMINAL LIFECYCLE DISPOSITION
   ↓
TERMINAL
```

Required semantic distinctions:

```text
Answered Correct
Answered Incorrect
Question Timed Out
Skipped
Replaced
Abandoned by Run Termination
```

Permanent firewalls:

```text
Skip ≠ Timeout
Global Blitz/Combo Expiry ≠ Question Timeout
Replacement ≠ Incorrect
Quit ≠ Incorrect
Presented ≠ necessarily answered
```

---

# 9. GEI-03A frozen race semantics

The event-loop model is:

> **First valid processed canonical claim wins.**

Examples:

```text
Answer processed first
→ answer counts
→ pending Switch becomes stale

Switch accepted first
→ old question becomes replaced
→ later answer/timeout becomes stale

Global expiry processed first
→ active question closes
→ later question work becomes stale

Answer processed first
→ answer counts
→ subsequent global expiry ends run
```

Switch economy remains:

```text
valid Switch activation
→ consume immediately
→ no refund if later stale
```

Stale work must never mutate a later question or newer run.

---

# 10. GEI-03B implemented canonical lifecycle foundation

Implemented commit:

`bb368f93c4066b7d0357fdc10e76198ff5fdcb3f`

Implemented concepts:

```text
runtime RunInstance identity
runtime QuestionInstance identity
first-terminal-claim gate
stale timer rejection
stale Switch rejection
new-run isolation
neutral active-question closure on run exit
```

This implementation is canonical gameplay infrastructure, not GameBrain intelligence.

---

# 11. Clean Experience Observation

GameBrain must not read mutable `GameState` arbitrarily.

Required direction:

```text
Canonical Gameplay Truth
        ↓
Immutable Public Projection
        ↓
GEI / evidence consumer
```

GEI-04 selected:

```text
QuestionPresentedSnapshot
        +
QuestionTerminalObservation
        ↓
QuestionExperienceObservation
```

The exact names may evolve; the semantic phase separation must remain.

---

# 12. Question Experience content

## 12.1 Presented facts

Only effective executed facts should appear.

Candidate minimum:

```text
effective operation
effective number type
effective difficulty
answer format / representation
mode / surface context where required
timer condition
semantic progress/ordinal where required
bounded stage/boss context where required
```

Prefer:

```text
WHAT ACTUALLY EXECUTED
```

over:

```text
WHAT WAS REQUESTED
```

Requested / preferred / proposed values belong later in Decision Context / Decision Episode.

## 12.2 Terminal facts

Use strongly typed valid terminal states.

Conceptually:

```text
AnsweredCorrect
AnsweredIncorrect
QuestionTimedOut
Skipped
Replaced
AbandonedByRunTermination
```

Avoid data models that permit contradictions such as:

```text
replaced + correct
skipped + timeout
```

## 12.3 Explicit exclusions for Phase 1

Do not include:

```text
mastery
player real-world identity
operands
equation text
correct answer
selected wrong answer
distractor list
psychological labels
unsafe responseTime
speculative assistance provenance
GameBrain recommendation
```

---

# 13. Timing firewall

Current wall-clock response duration is not valid clean response-process evidence because paused/modal time can contaminate it.

Therefore:

```text
responseTime
= excluded from initial GEI question projection
```

Timing conditions may still be represented:

```text
untimed
per-question timer
global run pressure
time limit where applicable
```

But no cognitive-latency claim is allowed.

---

# 14. Assistance firewall

Current aggregate power-up state is insufficient for complete per-question assistance provenance.

Important distinctions:

```text
inventory
≠ availability

activation
≠ application

availability
≠ usage
```

Current known behavior:

- 50/50 and Time may affect the current question;
- Switch replaces the current question;
- Double and Shield may be armed on one question and applied later.

Full assistance provenance is a future capture problem and must not be invented from aggregate state.

---

# 15. Three memory layers

## 15.1 Working / Short-Term Memory

High-detail, current-run evidence.

Examples:

```text
recent question outcomes
recent timeout sequence
current context
recent assistance transitions
current streak
recent difficulty transitions
```

## 15.2 Run Experience Summary

Bounded summary at run boundary.

Example concept:

```text
difficulty
operation
answer format
question target
correct
incorrect
timeout
completion
assistance summary where valid
```

No permanent raw-event replay.

## 15.3 Long-Term Experience Memory

Cross-run bounded evidence.

Conceptual contents:

```text
exposure
recent evidence
historical evidence
trajectory
conditioned performance
completion patterns
assistance-conditioned evidence
voluntary-selection evidence
```

Critical distinction:

```text
Long-Term Experience Memory
≠
Player Experience Model
```

Memory stores retained evidence.

The Player Experience Model is the current interpretation of that evidence.

---

# 16. Recency, decay, expiry, supersession

Permanent principle:

```text
old evidence
≠
current evidence forever
```

But there is no single universal decay formula.

Different evidence families may require different aging behavior.

Memory must support concepts such as:

```text
historical evidence
recent evidence
evidence age
current relevance
historical relevance
trajectory
```

Possible future policies:

```text
retain
down-weight
supersede
expire
```

Important:

```text
DECAY ≠ DELETE
```

Historical evidence may lose current authority while retaining trajectory value.

---

# 17. Reproducibility without permanent raw retention

Decision reproducibility must not require storing every raw question forever.

For a decision, retain enough versioned aggregate evidence state to audit why the decision was made.

Conceptual:

```text
DecisionEvidenceSnapshot {
  aggregation_version
  decay_policy_version
  exposure_summary
  weighted_success_evidence
  weighted_failure_evidence
  effective_evidence_age
  coverage
  epistemic_status
}
```

Principle:

```text
reproducible decision
≠
permanent raw event retention
```

---

# 18. Scenario Knowledge Library

GameBrain should be supplied with structured scenario definitions that help it test whether observed patterns are compatible with meaningful experience hypotheses.

A scenario is not a hardcoded action rule.

Conceptual scenario definition:

```text
ScenarioDefinition

Name
Question being tested
Required observations
Comparable conditions
Supporting evidence
Contradicting evidence
Alternative explanations
Missing evidence
Epistemic requirements
Attribution limitations
Current scenario state
```

Potential scenario states:

```text
NOT_EVALUABLE
INSUFFICIENT
COMPATIBLE
SUPPORTED_CANDIDATE
MIXED
CONFLICTING
NO_LONGER_SUPPORTED
```

Names are not frozen.

---

## 18.1 GameBrain Evidence Science Toolkit (EST) — retained future governed analytical layer

The project retains the **GameBrain Evidence Science Toolkit (EST)** as a reusable, versioned analytical layer between admissible evidence/memory and scenario interpretation.

Permanent separation:

```text
P1-SE-EVAL-00
= protocol-specific Study evidence validity / feasibility machinery

GAMEBRAIN EVIDENCE SCIENCE TOOLKIT (EST)
= reusable analytical capability for GameBrain evidence

SCENARIO KNOWLEDGE LIBRARY
= preloaded interpretive hypotheses / evidence requirements

PLAYER EXPERIENCE MODEL
= player-specific synthesized interpretation

POLICY / AUTHORITY
= later preference and influence governance
```

EST does not own canonical truth, gameplay legality, data-capture authority, persistence authority, Scenario state, Player Model state, policy preference, or execution.

Preferred role:

```text
Admissible bounded evidence / memory
        ↓
EST
versioned uncertainty-preserving analytical outputs
        ↓
Scenario Matching + Pattern Understanding
        ↓
Player Experience Model
```

EST must not become a generic bag of statistical tests. A method is admissible only when tied to a defined educational/product question, explicit data type, assumptions, minimum evidence, uncertainty semantics, abstention/failure behavior, and a validation contract.

### EST staged capability ladder

```text
LEVEL 1 — ESTABLISHED FOUNDATION BUILDING BLOCKS
sampling / eligibility
common support / comparability
missingness accounting
exposure / imbalance checks
run / temporal segmentation
Wilson uncertainty / precision
confounding awareness
fail-closed abstention

        ↓

LEVEL 2 — ROBUST DESCRIPTIVE EVIDENCE
counts / rates
median / quantiles
dispersion
IQR / MAD or equivalent robust summaries where justified

        ↓

LEVEL 3 — COMPARATIVE INFERENCE
confidence intervals
effect magnitude
practical significance
governed comparable-condition contrasts

        ↓

LEVEL 4 — TREND / CHANGE DETECTION
recent-vs-historical comparison
stability
governed change detection
false-alarm control

        ↓

LEVEL 5 — PROBABILISTIC REASONING + CALIBRATION
validated probability outputs
Brier score / log loss where predictions exist
calibration assessment

        ↓

LEVEL 6 — EDUCATIONAL MODELS
BKT / IRT / alternatives
only if later governed evidence shows a real advantage
over simpler validated baselines
```

### Current R5.2 EST implementation status

The distinction between **available statistical foundation** and **implemented EST toolkit** is mandatory:

```text
EST architecture
= RETAINED / FUTURE GOVERNED CAPABILITY

Level-1 building blocks
= SUBSTANTIALLY ESTABLISHED ACROSS EXISTING P1 SCIENTIFIC FOUNDATION
= NOT YET PACKAGED AS A REUSABLE PRODUCTION EST MODULE

Level-2 robust descriptive toolkit
= NOT YET IMPLEMENTED AS EST

Level-3 comparative-inference toolkit
= NOT YET IMPLEMENTED AS EST

Level-4 reliable-change sub-capability
= ATTEMPTED THROUGH GB-MEASURE-01
= NOT ESTABLISHED
= PARKED

Other Level-4 trend/change capability
= NOT YET IMPLEMENTED AS EST

Level-5 probabilistic reasoning/calibration
= NOT YET IMPLEMENTED AS EST

Level-6 BKT / IRT / educational models
= NOT YET IMPLEMENTED AS EST
```

`GB-MEASURE-01` is therefore recorded as one bounded Level-4 measurement attempt, not as the whole EST and not as a reason to delete or block the broader EST architecture.

### Permanent EST rules

```text
method chosen by question + data + assumptions
not by tool availability

more statistics != more intelligence

statistical significance != educational significance

uncertainty travels with every estimate

trend/change claim != noise discrimination
unless that discrimination is validated

probability output requires calibration validation

multiple hypothesis families require multiplicity discipline where applicable

assumptions unmet / evidence sparse / attribution unresolved
→ ABSTAIN / INSUFFICIENT

EST output
!= Scenario state
!= Player Model state
!= Policy preference
!= Authority
!= Execution
```

EST does not itself authorize new capture, longer retention, cloud/telemetry use, identity persistence, or gameplay influence.


# 19. Example scenario families

## 19.1 Difficulty scenarios — Phase 1 candidate family

```text
StableAtCurrentDifficulty
ProductiveChallengeCandidate
OverchallengeCandidate
UnderchallengeCandidate
SparseHigherDifficultyEvidence
RecentImprovementCandidate
RecentDeclineCandidate
RecoveryCandidate
TimeoutConcentrationAtDifficulty
AssistanceConditionedDifficulty
```

These are hypotheses/evidence constructs, not automatic difficulty rules.

## 19.2 Session-length scenarios — future

```text
ShortRunPreferenceCandidate
LongRunToleranceImproving
LateRunDegradation
StableAcrossLongRuns
LongerRunAbandonmentAssociation
```

## 19.3 Error / persistence scenarios — future

```text
RepeatedErrorExitSensitivity
RecoveryAfterError
PersistentAfterFailure
RepeatedRetryPattern
ErrorSequenceContinuation
```

## 19.4 Answer-format scenarios — future

```text
TrueFalsePreferenceCandidate
Choice4PreferenceCandidate
WrittenExperienceSparse
FormatSpecificPerformanceDifference
```

## 19.5 Timing scenarios — future

```text
ModeratePressureProductiveCandidate
PressureSensitivityCandidate
TimeoutConcentrationUnderPressure
NormalTimingStable
```

## 19.6 Assistance scenarios — future

```text
FrequentAssistanceUse
AssistanceUsageDecreasing
IndependentPerformanceImproving
PerformanceSupportedByAssistance
AssistanceAvailabilityWithoutUsage
```

## 19.7 Challenge-seeking scenarios — future

```text
VoluntaryHardSelection
RepeatedMasterReturn
ChallengeSeekingCandidate
```

---

# 20. Scenario evidence must include contradiction

GameBrain must not search only for supporting evidence.

Example:

```text
Scenario:
RepeatedErrorExitSensitivity

Supporting:
3 comparable runs ended after error streaks

Contradicting:
2 comparable runs continued normally

Alternative:
runs were already near completion

Result:
MIXED
```

This is a permanent anti-confirmation-bias requirement.

---

# 21. Scenario Acceptance Gate — SAG

A plausible scenario definition is not automatically a valid measurable construct.

Every scenario that may reach `SUPPORTED_CANDIDATE` must pass an appropriate Scenario Acceptance Gate.

Potential scenario classes:

## Type A — Descriptive association

Question:

> Does an observable association repeat under appropriate comparator conditions?

## Type B — Predictive pattern

Question:

> Does the pattern predict held-out future observations better than an appropriate baseline?

## Type C — Evaluative / experience construct

Question:

> Are its observable components measurable and coherent without smuggling Product Policy into the scenario?

Gate flow:

```text
Scenario Definition
        ↓
Measurement Specification
        ↓
Comparator / Negative Case
        ↓
Real Observable Data
        ↓
Discrimination / Reproducibility Test
        ↓
Contradiction Analysis
        ↓
Alternative-Explanation Audit
        ↓
SAG
```

Possible results:

```text
SCENARIO_ACCEPTED
SCENARIO_INCONCLUSIVE
SCENARIO_NOT_VALIDATED
```

A non-validated scenario must not drive a supported Player Model state.

---

# 22. Player Experience Model

The Player Experience Model is multidimensional, not a single level.

Conceptual structure:

```text
PLAYER EXPERIENCE MODEL

├── Mathematical Experience
│   ├── Addition
│   ├── Subtraction
│   ├── Multiplication
│   └── Division
│
├── Challenge Experience
│   ├── Easy
│   ├── Medium
│   └── Hard
│
├── Answer-Format Experience
│
├── Timing Experience
│
├── Assistance Experience
│
├── Behavioral Experience
│   ├── Persistence
│   ├── Exit patterns
│   ├── Session-length behavior
│   ├── Replay / return
│   └── Voluntary selection
│
├── Activity / Mode Experience
│
├── Recent State
│
└── Longitudinal Trajectory
```

Intersections are created only when evidence justifies them.

Do not create a full Cartesian product.

---

# 23. Choice preference vs experience fit

Preserve two separate concepts.

## Revealed choice preference

What does the player explicitly choose when alternatives are genuinely available?

## Experience fit

How does the executed experience actually go?

Example:

```text
Choice preference:
Hard

Experience fit:
Mixed / currently weakly supported
```

Player preference must not be erased just because GameBrain predicts another experience may perform better.

---

# 24. Decision Context

GameBrain never asks:

> What should the entire game do now?

A canonical owner opens a bounded decision opportunity.

Phase 1:

```text
DecisionContext = chooseDifficulty
```

Future examples:

```text
chooseRoundLength
chooseAnswerFormat
chooseTimingCondition
choosePracticeConfiguration
chooseNextActivity
```

GameBrain must not manufacture decision opportunities simply because alternatives exist.

---

# 25. Decision Locus Contract

Before any shadow decision context is considered production-valid, the exact decision locus must be frozen.

For `chooseDifficulty`:

```text
A DecisionEpisode exists only when a canonical owner
explicitly opens an eligible difficulty-decision opportunity.
```

The canonical owner supplies:

```text
decision context
legal options
player-agency constraints
activity/context snapshot
```

GEI does not infer legality.

---

# 26. Legal Options Contract

Canonical systems own legality.

Conceptual Phase-1 input:

```text
DecisionContext = chooseDifficulty
LegalOptions = canonical legal subset of {Easy, Medium, Hard}
ActivitySnapshot = relevant comparable context
```

If no legal options exist:

```text
ABSTAIN_NO_LEGAL_OPTIONS
```

GameBrain does not recreate Adaptive, Master, Quest, Daily, Weak Skills, or Generator rules.

---

# 27. Candidate Evaluation

Each candidate receives a multidimensional evaluation, never a universal magic score.

Conceptual:

```text
CandidateEvaluation

candidate

Educational
  success estimate
  challenge estimate

Engagement
  completion estimate
  replay estimate

Timing
  pressure evidence
  timeout evidence

Assistance
  conditioned usage evidence

Evidence
  coverage
  missing evidence
  epistemic status
  counterfactual status
  attribution uncertainty

Development Horizon
  immediate
  near-term
  long-term

Exploration
  information value
  frontier status
  comparator need
  recent exploration history
  exploration uncertainty

Explanation
  structured supporting basis
```

Long-term development and exploration value may legitimately remain UNKNOWN.

A candidate may therefore be evaluated differently for normal play versus bounded exploration without collapsing the two purposes:

```text
PREFERRED FOR NORMAL PLAY:
Medium

PREFERRED FOR BOUNDED FRONTIER EXPLORATION:
Hard
```

Neither statement authorizes execution by itself.

---

# 28. Epistemic status

Every estimate must preserve how it is known.

Conceptual statuses:

```text
DIRECTLY_OBSERVED
SUPPORTED_BY_COMPARABLE_HISTORY
GENERALIZED_INFERRED
UNKNOWN
```

No estimate may silently lose this status before policy or human display.

---

# 29. Counterfactual Firewall

Permanent rule:

```text
Observed:
Medium → 8/10

DOES NOT PROVE:
Easy → would have been 10/10
Hard → would have been 6/10
```

Unexecuted alternatives remain predictions.

---

# 30. Attribution Firewall

Observed association under a combined configuration does not identify which dimension caused the outcome.

Example:

```text
Multiplication
Hard
Written
Blitz
20Q
→ lower performance
```

Allowed:

```text
lower performance observed under this combined configuration
```

Not automatically allowed:

```text
Hard caused it
Written caused it
Blitz caused it
```

---

# 31. Evidence Opportunity Preservation

Provenance alone does not solve the self-confirming loop.

Example:

```text
GameBrain prefers Medium
→ Medium gets more exposure
→ Medium evidence increases
→ Hard becomes sparse/stale
→ Medium looks better supported
→ GameBrain prefers Medium again
```

R1 therefore requires two **separate** evidence-preservation mechanisms:

```text
REFERENCE / CONTROL OPPORTUNITY TRACK
GameBrain preference/influence is withheld for a preregistered comparison window.

EVIDENCE EXPLORATION BUDGET
GameBrain may later create bounded probes whose explicit purpose is reducing uncertainty.
```

Their purposes are not interchangeable:

```text
Reference / Control Track
→ preserve a comparison window outside GameBrain preference
→ detect concentration/starvation patterns
→ support causal attribution only if its allocation/design is independently validated for that claim

Evidence Exploration
→ deliberately alter exposure to learn about an alternative
→ is itself a GameBrain intervention
→ therefore cannot silently serve as the non-GameBrain reference track
```

Permanent counterfactual rule:

```text
Reference-track exposure
≠ automatically unbiased counterfactual evidence
≠ automatically causal identification
```

Any causal comparison requires its own preregistered protocol and valid allocation/comparability design. If that design is absent, comparisons may support descriptive starvation-risk analysis but must not be named or interpreted as GameBrain-attributable causal effects.

No fixed reference percentage or exploration percentage is frozen yet.

## 31.1 Capability Frontier Exploration

Even if natural gameplay is sufficient for valid current-fit evidence, it may still be insufficient for discovering the player's **future capability frontier**.

Permanent distinction:

```text
Natural evidence sufficient for current-fit estimation
≠
Natural evidence optimal for discovering future potential
```

GameBrain should eventually maintain a bounded concept of a **Supported Experience Envelope**, not a fixed player-capability label.

Conceptually:

```text
CURRENT SUPPORTED REGION
        ↓
CANONICAL LEGAL CANDIDATES + CANDIDATE TOPOLOGY
        ↓
STRUCTURALLY ADJACENT FRONTIER CANDIDATE
        ↓
BOUNDED PROBE
        ↓
OBSERVE
        ↓
CONTINUE / RECOVER / KEEP UNKNOWN
```

The **canonical Decision Owner** supplies legal candidates and any structural `CandidateTopology` required for frontier reasoning. GameBrain must not manufacture adjacency from enum order, names, numeric difficulty values, or observed history.

Canonical adjacency means only:

```text
this candidate is a structurally permitted neighboring transition
```

It does not mean:

```text
pedagogically suitable
safe for this player now
likely to succeed
authorized for exploration
```

Those remain evidence + Exploration Policy + Player Agency + Authority questions.

For `chooseDifficulty`, a future canonical topology might permit transitions conceptually such as:

```text
Easy ↔ Medium
Medium ↔ Hard
```

but that topology must come from the canonical owner, not from GameBrain assuming a difficulty ordering. A non-adjacent jump such as `Medium → Insane` is never justified merely by an internal ordinal assumption.

Frontier exploration must prefer a **minimum sufficient experimental change**. When difficulty is the question under study, other relevant conditions should remain as comparable as practical:

```text
Operation      same/comparable
NumberType     same/comparable
AnswerStyle    same/comparable
Timing         same/comparable
Activity       same/comparable
Difficulty     one canonical frontier transition
```

This protects attribution discipline.

Exploration must also be reversible:

```text
Probe
→ Observe
→ evidence supports continuation? continue cautiously
→ evidence does not support continuation? recover to supported/canonical path
```

Never:

```text
Probe
→ force repeated exposure until enough data exists
```

Player Agency remains an independent constraint. A useful probe can still be rejected, deferred, or declined without converting the unexplored candidate into negative evidence.

## 31.2 Exploit vs Evidence Exploration vs Frontier Growth

Do not flatten all purposes into one preference:

```text
EXPLOIT / PERSONALIZE
Use what current evidence supports for normal play.

EVIDENCE_EXPLORATION
Reduce uncertainty about a comparator/alternative.

CAPABILITY_FRONTIER_EXPLORATION
Test whether the supported challenge/experience envelope can safely expand.
```

Evidence exploration and frontier exploration may overlap in which candidate is exposed, but their **decision purpose, risk budget, provenance, and later interpretation must remain separate**.

## 31.3 Exploration Budget Architecture

Exploration uses **two independent typed budgets under one global ceiling**:

```text
GLOBAL EXPLORATION CEILING
        │
        ├── EVIDENCE EXPLORATION BUDGET
        │     purpose: comparator evidence / uncertainty reduction
        │
        └── CAPABILITY FRONTIER EXPLORATION BUDGET
              purpose: bounded supported-envelope expansion
              stricter developmental / engagement / recovery constraints
```

Permanent rules:

```text
Total exploration ≤ Global Exploration Ceiling
Evidence exploration ≤ Evidence-specific cap
Frontier exploration ≤ Frontier-specific cap

Unused Evidence Budget
DOES NOT automatically transfer to Frontier Budget

Unused Frontier Budget
DOES NOT automatically transfer to Evidence Budget

Budget available
≠
must explore
```

The two budgets are **non-fungible by default** because their purposes and intervention burdens are different. In particular, unused evidence-exploration capacity must never become silent permission to push the player toward a harder frontier.

Any exception to budget non-fungibility requires:

```text
versioned Budget-Transfer Governance Amendment
        ↓
independent review
        ↓
does the transfer change empirical exposure/data generation?
        │
        ├── NO → governance amendment may govern the exception
        │
        └── YES
              ↓
          prospective amendment to every affected measurement/validation protocol
              ↓
          fresh/untouched confirmatory data rules apply
```

A transfer cannot be enabled by configuration change, tuning, implementation convenience, or runtime policy alone.

Future budget policy may consider:

```text
current evidence coverage
frontier uncertainty
recent stability
previous exploration outcomes
player agency
educational cost
engagement cost
time since last probe
decision importance
legal-option availability
canonical topology availability
recent recovery need
```

No coefficients, caps, cooldowns, or thresholds are frozen yet.

## 31.4 DG-00-S1 — Reference Replay Snapshot Governance Supplement

`Deferred Pure Shadow Replay` introduces a future retained data class that did not exist when DG-00 was frozen. Therefore no real-player pre-decision replay snapshot may be retained merely because R1/F11 architecture is sound. A dedicated governance supplement is required first.

The snapshot is defined as a **bounded immutable research/audit projection of pre-decision state**, not a serialization of `GameState`, not a dump of all GameBrain memory, and not permission for unbounded raw history. Permanent minimization rule:

> **Replay sufficiency, not state completeness.**

`DG-00-S1` must approve, before implementation:

```text
exact replay purpose / supported claim
exact field inventory + prohibited fields
field-by-field minimization justification
consumer(s)
retention class + maximum lifetime
why that lifetime is necessary for replay validity
deletion / expiry / Clear Data / approval-revocation behavior
local access boundary + least privilege
identity/linkability scope
storage/security/corruption/backup behavior
separate research authority from ordinary GEI-04B personalization capture
protected-user eligibility/approval treatment
snapshot schema version
evaluator/scenario/synthesis/evidence-semantics version provenance
replay-completion / protocol-retirement deletion behavior
```

DG-00-S1 does **not** authorize cloud storage, telemetry, developer diagnostics, support exports, or research reuse outside its approved purpose. If the minimized schema cannot faithfully reproduce the intended replay, the result is `REPLAY_NOT_VALID`; the system must not silently retain more state "just in case."

Governance separation remains:

```text
DG-00-S1  → may this snapshot be retained/used at all?
R1-REF-P00 → how are Reference opportunities allocated?
F11-P00    → how is starvation/self-influence measured?
```

## 31.5 Snapshot Replay Sufficiency Precheck

The first real-player Reference window must **not** be the experiment that discovers whether the snapshot schema is reproducible. Before production retention is authorized, the proposed minimized schema must pass a preregistered dry-run using synthetic, non-production, or otherwise already-authorized shadow inputs.

Required pattern:

```text
known full pre-decision state
        ↓
live/frozen evaluator result
        ↕ compare under preregistered equivalence rule
PureEvaluation(minimized frozen snapshot only)
        ↓
PASS → schema may proceed toward DG-00-S1 implementation approval
FAIL → SNAPSHOT_SCHEMA_NOT_SUFFICIENT
       revise prospectively + repeat dry-run
       NO real-player snapshot retention
```

No replay may reconstruct missing inputs from post-outcome state, hidden live state, or later learner history. Exact equality vs bounded numerical tolerance must be frozen by the protocol before the sufficiency test is run.

Historical calibration and retrospective model comparison must also remain distinct:

```text
Historical calibration:
What would evaluator/version V at t0 have predicted from information available at t0?

Retrospective model comparison:
What would a later evaluator/version V+n predict from the same t0 information?
```

If the historical evaluator cannot be faithfully reproduced, report `REPLAY_UNREPRODUCIBLE`; do not substitute today's evaluator and relabel the result as the historical prediction.

## 31.6 R1-REF-P00 — Reference / Control Allocation Protocol Requirement

> **GameBrain cannot be the sole author of both the treatment and the evidence used to prove that treatment remains safe.**

`R1-REF-P00` is a future protocol freeze, not current implementation authority. Its first architectural decision is now frozen:

```text
REFERENCE LIVE EXECUTION = BLACKOUT
```

For a Reference-assigned decision opportunity, GameBrain is **not invoked on the live authority-bearing decision path**. Canonical execution proceeds independently. `COMPUTE-BUT-SUPPRESS` is not the default Reference semantics because invoking GameBrain live would require proving absence of memory, cache, RNG, timing, async, persistence, resource-contention, or other side-effect leakage.

Prediction/calibration value is preserved through a separate future mechanism:

```text
REFERENCE assignment decided
        ↓
freeze minimized EX-ANTE pre-decision snapshot
        ↓
BLACKOUT GameBrain on live decision path
        ↓
canonical execution + outcome
        ↓
later, off critical path and only when separately authorized:
DEFERRED PURE SHADOW REPLAY(snapshot @ t0, frozen versioned evaluator)
```

The replay may use only information that existed before execution. It must not mutate canonical state, GameBrain memory, allocation membership, the completed DecisionEpisode, or future player state.

### Allocation ownership firewall

Reference assignment must occur **upstream of GameBrain invocation and outside GameBrain ownership**. The canonical Decision path exposes the allocation seam; a separately versioned Reference Allocation Policy determines membership. GameBrain must not:

```text
assign the Reference arm
veto a Reference assignment
request reassignment
change the allocation probability
use private GameBrain state to bias allocation
retroactively relabel an episode
```

Allocator inputs are limited by the frozen protocol to predeclared canonical/governance variables needed for eligibility, blocking/stratification, and allocation. A variable being "canonical" does not prove it is historically GameBrain-independent; historical-treatment contamination is a required future isolation-review question.

### Allocation design requirements

`R1-REF-P00` must later freeze, before real allocation:

```text
allocation unit
randomization/allocation mechanism
eligibility universe
blocking / stratification rules
allocation timing
reference behavior / canonical fallback
carryover assumptions
washout rules if applicable
claim/outcome horizon
minimum persistent Reference capacity
maximum burden / opportunity cost
allocation auditability / reproducibility
missing-allocation handling
contamination rules
reference-integrity failure conditions
protocol amendment rules
```

No specific percentage, randomization unit, player-level holdout, switchback design, or persistent floor is frozen now. **Persistent Reference capacity does not require permanently withholding GameBrain from the same children.** Rotating windows, decision/run/session-level assignment, bounded switchbacks, player-level holdouts, or hybrid designs remain protocol questions governed by carryover and claim horizon.

### Reference Integrity + claim horizon

Reference membership is not a global validity boolean. An observation counts as Reference evidence for a claim only when the applicable allocation protocol, BLACKOUT semantics, contamination checks, and `Reference Isolation Envelope` for that claim/horizon remain valid. Conceptually:

```text
Reference for immediate difficulty outcome
may be valid
while
Reference for run-level engagement / long-horizon development
may be invalid
```

Production reference monitoring may detect drift or suspicious divergence without establishing causality:

```text
REFERENCE DRIFT SIGNAL
≠
CAUSAL SELF-INFLUENCE FINDING
```

A material model/policy/synthesis change must trigger a Reference validity-envelope review. If historical Reference evidence is no longer applicable, a new contemporaneous Reference window is required.

## 31.7 Reference Window Usage Ledger + GOV-2 Data-Use Firewall

Reference independence cannot depend on team memory. Any future governed Reference-window program requires a **single authoritative, versioned, append-only Reference Window Usage Ledger** for data-use provenance.

Conceptual status semantics include:

```text
UNTOUCHED_CONFIRMATORY
SEEN_DEVELOPMENT
SECONDARY_ANALYSIS_ONLY
RETIRED
```

These statuses are claim/version scoped, not universal labels declaring a window scientifically useless forever. The ledger must preserve an immutable usage history such as:

```text
reference_window_id
allocation_protocol_version
window boundaries
claim / analysis purpose
model / scenario / synthesis / policy version
use event + date
use-status transition
protocol/review reference
supersession relationship
```

Permanent rule:

```text
UNTOUCHED_CONFIRMATORY
        ↓ replay/calibration result inspected and used for design/tuning
SEEN_DEVELOPMENT

SEEN_DEVELOPMENT
        ↛ UNTOUCHED_CONFIRMATORY
```

Deleting a window later does not make its evidence "unseen" again. Aggregate calibration findings count as seen when they materially informed design, thresholds, scenarios, synthesis, or policy.

`GOV-2` therefore applies directly to Reference shadow replay:

```text
If Reference window W informs version V+1,
W is development data for confirmatory claims about V+1.

Confirming V+1 requires:
- a fresh post-lock Reference window, or
- a preregistered untouched holdout not exposed during V+1 development.
```

The ledger requirement freezes provenance/audit semantics only. It does not authorize a new cloud database, telemetry stream, account identity, or long-term storage architecture; those remain subject to DG-00-S1 and any later data-flow/storage approval.

## 31.8 F11-P00 — Capability-Starvation Measurement Protocol Requirement

F11 must become measurable before R7 can ever receive runtime authority.

Required sequence:

```text
real Phase-1 shadow evaluator / policy / DecisionEpisodes available
        ↓
DG-00-S1 snapshot governance + replay-sufficiency precheck (if retained replay is used)
        ↓
R1-REF-P00 allocation protocol drafted + independently reviewed + locked
        ↓
R1 Reference / Control Track established with auditable integrity
        ↓
F11-P00 protocol drafted
        ↓
independent protocol review
        ↓
protocol lock
        ↓
F11 SHADOW starvation-risk study
        ↓
only later, inside an authority-bearing bounded pilot:
F11 REALIZED starvation / self-influence audit
```

`F11-P00` must preregister at least:

```text
eligible frontier opportunity definition
comparable decision window
canonical legal-candidate availability
canonical CandidateTopology / adjacency availability
reference-track eligibility and integrity
frontier-opportunity count
exposure count by candidate and decision purpose
exposure concentration / diversity metric if used
maximum tolerated starvation pattern
frontier evidence age / staleness
current-region evidence growth
confidence-growth-without-comparator-growth measure
player-decline exclusion rule
canonical-unavailability exclusion rule
policy/safety-block exclusion rule
GameBrain-associated suppression metric
causal-attribution requirements, if any
minimum sample / uncertainty / precision rules
SAFE / RISK / INCONCLUSIVE adjudication rules
```

Entropy or low exposure alone is not evidence of a GameBrain-caused trap. The denominator must be the preregistered set of eligible, legal, topology-valid, comparable opportunities after explicit handling of player choice and safety/product constraints.

The preferred core diagnostic is conceptually:

```text
confidence(Current) increases
while
adjacent-frontier evidence remains sparse/stale
while
eligible frontier opportunities repeatedly existed
while
GameBrain preference is associated with non-exposure
```

This can establish **SHADOW STARVATION RISK** if the preregistered criteria are met. It does not by itself establish causal suppression.

For any claim named `GameBrain-attributable suppression`, `F11-P00` must require a counterfactual design that actually supports causal attribution. The R1 Reference/Control Track is required as the baseline comparison mechanism, but it is **not automatically causal**. If allocation into Reference vs GameBrain-influenced opportunities does not meet the frozen causal/comparability requirements, the attributable-suppression component must return `INCONCLUSIVE` even if descriptive starvation risk is present.

Without an intact, measurement-valid R1 Reference/Control Track:

```text
F11 descriptive risk assessment may be degraded or INCONCLUSIVE
F11 causal / attributable suppression MUST be INCONCLUSIVE
```

Naming must preserve epistemic status:

```text
observational design → GameBrain-ASSOCIATED exposure suppression
causally valid design → GameBrain-ATTRIBUTABLE exposure suppression
```

Never promote the former into the latter by wording alone.

## 31.9 R1 / Reference / F11 package status — intentionally parked

The pre-authority architecture is now considered sufficient for the current project stage, but it is **not implemented, empirically validated, or runtime-authorized**.

```text
R1_F11_DESIGN_STATUS = FROZEN_FOR_FUTURE_PROTOCOLIZATION

IMPLEMENT NOW = NONE OF THIS PACKAGE
```

Deferred mandatory requirements now recorded:

```text
DG-00-S1
Snapshot Replay Sufficiency Precheck
R1-REF-P00
BLACKOUT live Reference semantics
Deferred Pure Shadow Replay
Persistent Reference Capacity
Reference Integrity + Isolation Envelope
Reference Window Usage Ledger
GOV-2 Replay Data-Use Firewall
F11-P00
SHADOW ≠ REALIZED starvation
ASSOCIATED ≠ ATTRIBUTABLE suppression
Cross-Context Reference Isolation Review before Context #2
```

Do **not** freeze yet:

```text
allocation percentage/rate
allocation unit/randomization algorithm
minimum production Reference floor
exact replay snapshot fields
snapshot retention duration
replay numerical tolerance
F11 starvation thresholds
joint vs independent multi-context allocation
```

Re-open this package only when the real Phase-1 stack makes it a concrete dependency: a real DecisionContext exists, Scenario→Evaluation Synthesis has survived validation, a shadow difficulty policy exists, shadow DecisionEpisodes exist, actual evaluator inputs are known, and R1-REF-P00 is genuinely the next research dependency. Until then, further detail should come from evidence and concrete implementation context rather than speculation.

---

# 32. Decision Purpose

Decision Episodes must eventually distinguish why an experience arose.

Conceptual purposes:

```text
NORMAL_CANONICAL
PLAYER_CHOICE
PERSONALIZATION
EVIDENCE_EXPLORATION
CAPABILITY_FRONTIER_EXPLORATION
```

Choosing Hard because it appears best for normal play is different from choosing Hard to gain comparator evidence, and both are different from a bounded probe intended to test whether the supported experience envelope can expand.

This purpose must survive into intervention/policy audit so GameBrain cannot later treat its own exploration intervention as ordinary natural exposure.

---

# 33. Scenario → Evaluation Synthesis

This is a distinct, versioned, gated transformation layer.

It must not be hidden inside candidate evaluation or policy.

Architecture:

```text
Raw Observations
        ↓
Scenario Evaluators
        ↓
Scenario States
        ↓
Versioned Scenario→Evaluation Synthesis
        ↓
CandidateEvaluation
        ↓
Versioned Policy Resolution
        ↓
PreferredCandidate / NO_PREFERENCE
```

The synthesis must declare:

```text
consumed scenarios/evidence
produced outcome dimensions
conflict handling
UNKNOWN handling
MIXED handling
missing-scenario handling
coverage propagation
uncertainty propagation
attribution propagation
```

Negative control example:

```text
ALL scenarios UNKNOWN
→ CandidateEvaluation MUST NOT become confident
```

Scenario synthesis must never secretly choose the candidate.

---

# 34. Reusable Evidence Semantics

To prevent per-context synthesis explosion, evidence semantics should be reusable where valid.

Conceptual:

```text
Scenario Evidence
        ↓
Reusable Semantic Evidence Components
        ↓
Decision-Specific Synthesis
```

Example:

```text
TimeoutConcentration scenario
→ TimingRiskEvidence
```

A new decision context may reuse the evidence semantic without duplicating the entire scenario interpretation.

But reuse has a critical validity boundary, defined below.

---

# 35. Evidence Validity Envelope — reuse does not transfer validity automatically

Every reusable evidence semantic must carry its **validated claim envelope**.

Conceptually:

```text
EvidenceValidityEnvelope {
  validated_claim
  measurement_definition
  population / player scope
  activity/context envelope
  comparator conditions
  answer-format / timing conditions where relevant
  provenance constraints
  scenario_version
  acceptance_protocol_version
  known attribution limits
}
```

Permanent rule:

> **Validity is not automatically portable across Decision Contexts.**

If `TimingRiskEvidence` was validated under `chooseDifficulty`-relevant comparisons, a later `chooseRoundLength` synthesis may not treat it as equally valid by default.

A new consumer must justify:

1. why the original validated claim is relevant;
2. whether the comparator conditions remain compatible;
3. whether the new decision changes the meaning of the evidence;
4. whether epistemic status must be downgraded;
5. whether a new Scenario Acceptance / transfer-validity test is required.

This is an **evidence-transfer firewall**.

Reusable semantics carry their original claim, not universal truth.

---

# 36. Policy Resolution Function

CandidateEvaluation → PreferredCandidate is a decision-science problem, not an implementation detail.

No universal resolver.

Use:

```text
DecisionContext
        ↓
Versioned Resolution Policy
```

For Phase 1:

```text
difficulty_policy_vN
```

Each version declares:

```text
PolicyDimensions
PolicyDirectionality
TradeoffRules
UnknownHandling
TieHandling
StabilityBehavior
```

Do not use undefined global monotonicity such as:

```text
"better candidate evidence must always increase preference"
```

Use dimension-level invariants while holding other dimensions constant.

Policy validation flow:

```text
Hypothesis
↓
Shadow Evaluation
↓
Negative Controls
↓
Falsification
↓
Trade-off Analysis
↓
Policy Gate
↓
Authority
```

Default under insufficient evidence:

```text
NO_PREFERENCE
```

---

# 37. Epistemic Preservation Contract

Structured epistemic state is the source of truth.

Human explanation is a projection from it.

```text
Structured Evaluation
        ↓
Human-Facing Projection
```

Human surfaces must preserve:

```text
evidence status
coverage
uncertainty
missing evidence
attribution limits
```

A natural-language layer must never increase certainty.

Example:

```text
Candidate: Hard
Status: UNCERTAIN
Coverage: SPARSE
Attribution: UNRESOLVED
Basis: limited comparable Hard exposure
```

Do not silently transform this into:

> Hard will help the player improve.

---

# 38. Stability / Minimum Intervention

Personalization should be:

```text
adaptive
but not twitchy
```

Phase-1 preference should persist across:

```text
K COMPARABLE eligible decision episodes
```

not arbitrary episodes.

`K` remains empirically TBD.

Minimum-intervention principle:

```text
minimum sufficient justified change
```

This is not the same as changing exactly one dimension.

---

# 39. Player Agency

Technical legality and player-intent override are different.

```text
LEGAL
≠
APPROPRIATE TO OVERRIDE PLAYER INTENT
```

Player-selected activities should not be silently replaced without a separately authorized product contract.

---

# 40. Authority

Preserve:

```text
PREDICTED
≠
PREFERRED
≠
AUTHORIZED
≠
EXECUTED
```

A policy preference is not an execution command.

Canonical systems retain final execution authority.

---

# 41. Decision Episode

A Decision Episode links prediction to actual execution and outcome.

Conceptual:

```text
DecisionEpisode

episode identity
DecisionContext
legal options
CandidateEvaluations
DecisionEvidenceSnapshot
reference/exploration arm
policy version
preferred candidate / NO_PREFERENCE
authority result
executed candidate
decision purpose
provenance
observed outcome
learning/audit consequence
```

Do not require every raw episode to be retained forever.

---

# 42. Two learning channels

## 42.1 Descriptive Experience Learning

```text
Truthful Observation
        ↓
Experience Memory
```

Question answered:

> What happened to the player?

This may occur during normal gameplay without GameBrain influence.

## 42.2 Decision / Intervention Learning

```text
DecisionEpisode
        ↓
Prediction / Policy Audit
```

Question answered:

> What did we predict, what was executed, and did the observed result support the decision?

No claim about GameBrain intervention effect is allowed without the Decision Episode path.

---

# 43. Fail-safe independence

GameBrain is an enhancement path.

```text
GameBrain healthy + authorized intelligence
→ canonical subsystem may consume it

GameBrain uncertain
→ abstain

GameBrain unsupported
→ abstain

GameBrain fails
→ canonical subsystem continues normally

GameBrain is too slow for the current decision budget
→ abstain / bypass intelligence
→ canonical subsystem continues normally
```

No fallback may silently use stale last-known GameBrain state unless separately designed and authorized.

## 43.1 ARCH-PERF-1 — GameState Growth Firewall

The recent refactor must not be undone by moving GEI intelligence back into `GameState`.

`GameState` MAY own only responsibilities that are genuinely canonical gameplay responsibilities:

```text
canonical runtime truth
authoritative gameplay mutation
run/question lifecycle
small identity/termination guards
small projection/capture seams
```

`GameState` MUST NOT own:

```text
GEI memory
longitudinal aggregation
scenario library
scenario evaluation
Player Experience Model
evidence decay
CandidateEvaluation
Scenario→Evaluation synthesis
Resolution Policy
Decision Episode analysis
research/falsification logic
```

Permanent rule:

> **If a GEI milestone requires substantial intelligence logic inside `GameState`, that is an architecture warning and must be reviewed before implementation.**

The firewall is responsibility-based, not merely line-count based. A small amount of misplaced reasoning is still a violation; a somewhat larger amount of genuinely canonical lifecycle code may be valid.

## 43.2 Narrow GameState integration shape

The intended integration direction is:

```text
GameState / canonical owner
        ↓
truthful immutable facts
        ↓
Question / Run Experience projection
        ↓
GEI evidence / memory / scenarios / model
        ↓
bounded evaluation or intent
        ↓
canonical authority / subsystem
```

Not:

```text
GameState
├── scoring
├── timers
├── navigation
├── persistence
├── GEI memory                ✗
├── scenario matching         ✗
├── Player Experience Model   ✗
├── candidate evaluation      ✗
└── policy resolution         ✗
```

A future `GEI-04B` capture seam should therefore be small: copy canonical presented/terminal truth into immutable values and hand it off best-effort. It must not interpret what the observation means.

## 43.3 ARCH-PERF-2 — Optional Intelligence Performance Rule

No GEI reasoning operation may become a mandatory latency dependency for:

```text
question presentation
answer acceptance
scoring
life/combo updates
canonical progression
navigation
canonical run termination
```

Target behavior:

```text
GEI unavailable
GEI unsupported
GEI uncertain
GEI slow / over budget
        ↓
ABSTAIN / BYPASS
        ↓
canonical gameplay proceeds
```

The player must never wait for GameBrain merely to complete a canonical gameplay action.

## 43.4 Event-driven computation rule

GEI must not run continuously in the rendering/frame loop.

Preferred triggers:

```text
QUESTION TERMINAL
→ small bounded short-term evidence update

RUN END
→ bounded summary / aggregate update

DECISION OPPORTUNITY
→ evaluate only relevant legal candidates

RELEVANT NEW EVIDENCE
→ update only affected scenario families
```

Forbidden design direction:

```text
every frame
→ scan all history
→ evaluate all scenarios
→ rebuild entire Player Experience Model
→ evaluate all possible configurations
```

## 43.5 Bounded-memory and selective-evaluation performance rules

Long-term performance depends more on bounded data shape than on the number of Dart classes.

Required:

```text
bounded short-term observations
bounded run summaries
aggregated longitudinal evidence
no infinite raw question history
no infinite DecisionEpisode retention
no precomputed Cartesian Player Model
no scan of every scenario on every observation
```

Scenario evaluation should be relevance-based:

```text
difficulty evidence
→ difficulty-relevant scenario family

answer-format evidence
→ answer-format-relevant family
```

Do not evaluate unrelated future scenario families merely because they exist.

Player Experience intersections should be instantiated only when evidence justifies them.

## 43.6 Application-size rule

The intended GEI architecture consists primarily of:

```text
typed Dart value objects
bounded aggregates
scenario definitions
small deterministic evaluators
versioned policies
```

It does NOT currently authorize:

```text
embedded LLM
large neural-network weights
large on-device ML runtime
large model asset bundles
```

Therefore a modest code-size increase is expected, but binary-size growth must still be measured rather than assumed negligible.

## 43.7 GEI Performance Budget

Before any real personalization authority, measure the active shadow GEI stack in release/profile conditions on representative real Android hardware, including at least one lower-capability target where practical.

Track at minimum:

```text
APK / AAB size delta
startup impact
steady-state RAM delta
peak allocation behavior
question-terminal processing latency
run-end aggregation latency
decision-evaluation latency
frame/jank impact
storage growth
battery/CPU behavior where materially relevant
```

Compare:

```text
canonical baseline / GEI inactive
vs
GEI shadow active
```

Thresholds must be frozen before the authority-bearing performance gate is adjudicated; do not declare performance acceptable only after observing the measurements.

---


# 43A. Player-Facing GameBrain Enable / Disable, Main-Screen Visibility & Age-Derived Eligibility

GameBrain remains an optional intelligence layer. Math Challenge must remain fully playable through canonical systems when GameBrain is disabled or ineligible.

## GB-USER-1 — Main-Screen GameBrain Master Control

The authoritative player-facing GameBrain preference is exposed on the main screen.

```text
GameBrain preference = ON / OFF
```

`GameBrain OFF` must not silently disable canonical Adaptive Difficulty or any other canonical subsystem.

```text
GameBrain OFF
≠
Adaptive Difficulty OFF
```

When GameBrain is effectively OFF, no new GEI-specific capture or future GameBrain personalization/influence may occur, while canonical gameplay continues normally.

## GB-AGE-1 — Current age-derived product eligibility

The existing neutral `FamilyAgeRange` is the only current product input to GameBrain eligibility:

```text
under13
→ GameBrainEligibility.ineligible

teen13to17
→ GameBrainEligibility.eligible

adult18plus
→ GameBrainEligibility.eligible

missing / invalid / stale / unresolved
→ GameBrainEligibility.unresolved
→ fail closed
```

Current effective enablement is:

```text
effectiveGameBrainEnabled
=
gameBrainPreference
AND
GameBrainEligibility == eligible
```

This is **product eligibility**, not verified age, consent, or parental authorization.

## GB-AGE-2 — Preference and eligibility remain distinct

The saved preference is not destroyed merely because eligibility changes:

```text
preference ON + eligible
→ effective ON

preference ON + ineligible/unresolved
→ effective OFF
→ saved preference remains ON

eligibility later returns to eligible
→ effective state may become ON again from the saved preference
```

`Clear GameBrain Data` currently clears only the GameBrain preference; it does not rewrite the Family Age Gate. Full reset follows the canonical family/reset behavior of the app.

## GB-AGE-3 — No current parental-approval dependency

The earlier design concept of a `GB-PARENT-00` prerequisite is superseded for the current product policy.

```text
Age Gate
≠ verified age
≠ parental approval
≠ consent
```

No current GameBrain path treats an under-13 selection as eligible after a parent-approval flow. Under-13 and unresolved states simply remain ineffective/off. If future law/store/product policy requires a separate consent or parental mechanism for a new data flow, that must be separately designed and governed; it must not be inferred from the Age Gate.

## GB-USER-2 — Persistent effective-enable badge

The gameplay badge represents **effective enablement only**:

```text
effective GameBrain ON
→ persistent non-obstructive badge visible

effective GameBrain OFF
→ badge absent
```

The badge does not mean:

```text
GameBrain influenced this question
GameBrain has a confident recommendation
GameBrain has enough evidence
parent/guardian is present
```

The main-menu status may distinguish saved preference from effective state, for example:

```text
Saved OFF
Saved ON — not active
Active
```

## GB-USER-3 — No hidden last-known-state behavior

When effective GameBrain becomes OFF, canonical behavior is authoritative immediately. No stale recommendation, cached preferred difficulty, or previous policy output may continue as a hidden fallback.

## GB-USER-4 — BRAIN-07 remains independent

The current BRAIN-07 context-evidence observer is intentionally independent of:

```text
FamilyAgeRange
GameBrainEligibility
gameBrainPreference
effectiveGameBrainEnabled
```

BRAIN-07 remains bounded run-local shadow evidence and is not GEI long-term profiling.

## Current implementation status

```text
GB-UX-00
✅ IMPLEMENTED
commit a2deb3e9eccc6ecc14704c78badb877d18afa357
remote push reported complete

GB-ELIG-01
✅ IMPLEMENTED
commit e90f216f51255b4473635155b04a37272ea308ac
remote branch/commit independently verified in the project workflow
```

No GameBrain gameplay authority is implied by these controls:

```text
mayAffectGameplay = false
```

---

# 44. Phase 1 scope — chooseDifficulty only

Phase 1 is intentionally narrow:

```text
DecisionContext = chooseDifficulty
```

Out of scope until Expansion Gate:

```text
Mode selection
Distractor intent
Timing / round length
Weak Skills practice suggestions
Question Generator influence
Answer-format personalization
Activity selection
```

Any horizontal expansion before Phase-1 gates is a contract violation.

---

# 45. Phase-1 objective

Phase 1 must prove the complete loop on one real decision:

```text
Observe
Remember
Scenario
Model
Evaluate
Explain
Abstain
Resolve
Stabilize
Authorize
Execute
Observe outcome
Learn
Audit
```

Only after this is demonstrated may a second Decision Context be considered.

---

# 46. P1-F00 — Difficulty Evidence Feasibility Protocol Freeze

Before running P1-F01, freeze its protocol.

P1-F00 must define in advance:

```text
eligible episode definition
comparable-context definition
primary feasibility metrics
minimum candidate exposure
minimum effective comparable sample
minimum player/sample diversity where required
maximum tolerated missingness
maximum candidate imbalance
minimum legal-option coverage
maximum starvation rate
uncertainty/precision requirements
confounding flags
abstention criteria
FEASIBLE rule
INCONCLUSIVE rule
NOT_FEASIBLE rule
```

Numeric metrics must have numeric thresholds frozen before P1-F01 results are seen.

Prefer decision-relevant precision/uncertainty criteria over arbitrary N where possible.

## 46.1 Current locked P1-F00 protocol snapshot

P1-F00 now has two historical layers with explicit lineage:

```text
P1-F00 v1
LOCKED / HISTORICAL
reported local lock commit 02a36a948ae3626085d93cacedcdcf4ec6aa1d94

P1-F00 v1.1
LOCKED / CURRENT PROSPECTIVE PROTOCOL
lock commit b7a77db760b1b6e0b65409f26c45c2d892139cdf
```

P1-F00 v1.1 is a prospective lifecycle/process-loss amendment. It preserves the v1 scientific claim, common-support dimensions, `Y_correct`, natural-play envelope, terminal precedence, and every quantitative threshold. It adds deterministic requirements needed to make the v1 denominators executable under lifecycle interruption and process loss.

Independent lineage for v1.1:

```text
14b12e8d919abfd44583e6227d7d9cc2b40e13fe
→ initial prospective amendment draft

62732fe37b7b2ab9a2ac16c4db11a73a69646dbc
→ independent review: REQUIRED_CHANGES

c4339b1d5ada59397854bb65f0c2ce0d3205c788
→ required changes applied

1abe8c934b1b4d13e3162a435b5ff21e86bb0f86
→ independent re-review record: APPROVED_FOR_LOCK

b7a77db760b1b6e0b65409f26c45c2d892139cdf
→ v1.1 LOCKED
```

The lifecycle/process-loss rules now freeze these principles:

```text
O_raw enters at the canonical eligible chooseDifficulty opening.
Scientific admission is separate from gameplay authority.
Every admitted measurement window must later be CLEANLY_CLOSED or LEFT_UNCLEAN.
Known lifecycle-interrupted opportunities remain O_raw but are excluded from O_valid.
Known background-interrupted QuestionTimedOut is lifecycle-censored, not difficulty failure evidence.
Explicit unlinked closure remains O_raw/missingness and is never recoded as incorrect or NO_OPPORTUNITY.
Silent process loss is never treated as observed, zero, valid, or incorrect.
Measurement unavailability → INCONCLUSIVE, not NOT_FEASIBLE.
```

Any future confirmatory integrity mechanism must prove all of the following before a P1-F01 window may rely on it:

```text
1. complete detection of admitted unclean measurement windows
2. monotonic admitted O_raw accounting
3. sufficient exact legal-set / candidate-membership accounting
4. crash-consistent durable commit semantics
5. finite validated outstanding-accounting gap
6. idempotent recovery/retry OR a finite validated duplicate bound
7. finite K_under
8. finite K_over
9. defensible divergence direction
10. conservative threshold evaluability
11. gameplay independence from measurement-storage success
```

The proof order is dependency-sensitive:

```text
G — admitted-window loss detection completeness
↓
F — retry / recovery idempotence or finite duplicate bound
↓
E — cross-boundary divergence: K_under / K_over / direction
```

A finite uncertainty interval may be used only conservatively. If any defensible value inside the interval changes a locked threshold result, that criterion is `INCONCLUSIVE`; the favorable edge may never be selected. Candidate-specific uncertainty must be evaluated independently where legal-set membership is uncertain.

Locked common-support semantics remain exact/comparable matching across the predeclared Phase-1 decision conditions, including decision locus/reason, exact legal set, agency/selection route, canonical selection mechanism, operation, number type, answer style, mode/mechanic, and applicable activity/run context. Full Phase-1 comparison requires the `{Easy, Medium, Hard}` envelope; pairwise evidence is diagnostic only.

Locked thresholds remain unchanged:

```text
|O_valid| >= 300

executed exposure per difficulty >= 60

comparable exposure per difficulty >= 30
across >= 3 qualifying common-support strata

per-stratum candidate imbalance <= 3.0

legal coverage >= 40%

global missingness <= 5%
candidate missingness <= 10%

starvation <= 20%

temporal-quintile concentration <= 50%

run segments >= 10
no single run segment > 25% of a candidate's evidence

95% Wilson half-width for candidate Y_correct <= 0.15
```

`Y_correct` remains:

```text
AnsweredCorrect = 1
AnsweredIncorrect / QuestionTimedOut / QuestionSkipped / QuestionReplaced = 0
```

Terminal precedence remains:

```text
measurement unavailable
→ INCONCLUSIVE

else explicit measurable critical failure
→ NOT_FEASIBLE

else every locked threshold passes
→ FEASIBLE

else
→ INCONCLUSIVE
```

Protocol requirements do not create capture authority. The minimum local integrity facts were later separately authorized by Product/Data decision `GD-P1F01-INTEGRITY-001`; confirmatory collection itself remains closed. Any future scientific change to v1.1 must be prospective, versioned, and independently reviewed again.

---

# 47. P1-F00 preregistration governance

Functional role separation is required but not sufficient.

## 47.1 Roles

At minimum distinguish:

```text
Protocol Owner
Independent Protocol Approver
P1-F01 Analyst / Executor
Independent Outcome Reviewer
Gate Adjudicator
```

A small project may combine some operational roles only where independence is not materially compromised, but **the builder/analyst must not self-approve the scientific gate**.

## 47.2 Organizational independence requirement

Before P1-F00 is locked, it must receive review/approval from a person or review role **outside the direct GEI implementation/delivery path** where feasible.

Purpose:

- challenge thresholds before results exist;
- challenge comparability assumptions;
- challenge feasibility definitions;
- reduce unconscious launch-pressure bias;
- document dissent before protocol lock.

For a solo/small project, procedural independence can be approximated through:

- a separate reviewer/agent not involved in protocol construction;
- outcome-blind review;
- frozen written review artifact;
- explicit owner sign-off after independent critique.

This is weaker than true organizational independence and must be labeled as such.

---

# 48. Protocol amendment and data lineage

Permanent rule:

```text
Protocol Amendment MUST be prospective.
```

But prospective versioning requires an explicit data-reuse policy.

## 48.1 If P1-F00 v1 is INCONCLUSIVE and v2 is created

Data seen while designing v2 is considered **development / protocol-derivation data**.

It cannot automatically serve as clean confirmatory evidence for v2.

Preferred order:

```text
v1 data informs v2 design
        ↓
v2 protocol locks
        ↓
NEW independent data window
        ↓
v2 confirmatory adjudication
```

## 48.2 Reuse of earlier data

Previous data may be reused only if one of these is true:

1. it was a predeclared untouched holdout not used to design v2; or
2. reuse is explicitly justified and labeled as secondary/sensitivity analysis rather than independent confirmation.

Any reused dataset must retain lineage:

```text
collected_under_protocol
used_to_design_versions
eligible_for_confirmatory_use?
reason
```

Permanent rule:

> **Data that helped define a new gate cannot silently become independent evidence for passing that same gate.**

---

# 49. P1-F01 — Difficulty Decision Evidence Feasibility

Only after P1-F00 is locked.

Core question:

> Does normal Math Challenge gameplay generate enough truthful, comparable `chooseDifficulty` evidence across the Phase-1 difficulty envelope for Phase 1 to be empirically testable without first changing gameplay distribution?

Inspect:

```text
eligible decision frequency
legal-option availability
natural Easy / Medium / Hard exposure
comparability
coverage starvation
player-selection confounding
canonical-selection/adaptive confounding
expected abstention
```

Terminal result:

```text
FEASIBLE
INCONCLUSIVE
NOT_FEASIBLE
```

If `NOT_FEASIBLE`, do not automatically invent an exploration percentage to rescue the design.

Instead classify the feasibility failure before deciding what happens next. Examples include:

```text
EXPOSURE_STARVATION
COMPARABILITY_FAILURE
PLAYER_SELECTION_CONFOUNDING
ADAPTIVE / CANONICAL_SELECTION_CONFOUNDING
MODE / CONTEXT_CONFOUNDING
INSUFFICIENT_REPEATED_EVIDENCE
LEGAL_OPTION_COVERAGE_FAILURE
TEMPORAL_IMBALANCE
ANSWER-FORMAT / NUMBER-TYPE IMBALANCE
```

A `NOT_FEASIBLE` result may lead to:

```text
DEFER chooseDifficulty personalization
or
SEPARATE evidence-acquisition / exploration study
or
future review of another Decision Context
```

It must not automatically authorize exploration.

Conversely, `FEASIBLE` does **not** eliminate the need for future exploration. It only means natural gameplay is sufficient for the Phase-1 observational claim. A later, separately gated Capability Frontier Exploration study may still be justified to prevent local-optimum lock-in and discover adjacent capability growth.

## 49.1 Current P1-F01 readiness status

P1-F01 has **not** reached `FEASIBLE / INCONCLUSIVE / NOT_FEASIBLE` because no confirmatory window has opened.

The original readiness review reported:

```text
P1_F01_READINESS = BLOCKED_BY_MEASUREMENT_DEPENDENCY
commit 44b6192a99472a2cc735f08fc1a6f3ca493674c5
```

That dependency drove the now-completed truthful measurement foundation:

```text
Canonical difficulty legality
✅ 25f92d9459037f7c603f5a2c64e54fd8df2dcba8

Truthful difficulty measurement seam
✅ 947a9b4199ba0a93c11f4d75f735a9db0d462006

Opportunity identity / ordering / exact QEO linkage
✅ 232b46c57d86d497cef93f9707ccbe334b4a2189
```

A later readiness re-check then reported:

```text
P1_F01_MEASUREMENT_READINESS = BLOCKED_BY_PROTOCOL_EXECUTABILITY
commit 6e06f6284f3a9129e5a55cbf8be1c044cb0616a1
```

The blocker was lifecycle/process-loss denominator integrity, not missing canonical legality/linkage. That blocker led to prospective P1-F00 v1.1, which is now independently reviewed and locked.

The selected minimum integrity design is now:

```text
P1_F01_MINIMUM_INTEGRITY_DESIGN = DESIGN_READY_FOR_GOVERNANCE
commit 8a2952ff92adc438718925419423498ec42d78e4

Recommended primitive:
local SQLite transactional window-summary integrity store

Responsibilities:
- admitted-window OPEN / CLEANLY_CLOSED / LEFT_UNCLEAN state
- monotonic admitted O_raw accounting
- exact Phase-1 legal-set accounting
- recovery / idempotence metadata
- no raw QEO history
- no gameplay authority
```

The minimum local capture/retention facts for that integrity purpose are separately authorized by:

```text
GD-P1F01-INTEGRITY-001
AUTHORIZED
commit e3a2745131901438c6baa36b4e6e6ca4b98db791
```

This authorization is local-device only and does **not** authorize confirmatory collection, a study evidence database, personalization, cloud, telemetry, analytics, or long-term Player Experience Memory.

Current readiness is therefore **pending implementation proof**, not scientifically adjudicated. The next implementation must build the minimum integrity mechanism, validate G→F→E and the 11 locked properties, then run a new measurement-readiness re-check. Cross-run study evidence/common-support storage remains a later separately governed dependency if the post-integrity re-check confirms it is still required.

No P1-F01 confirmatory outcome data has been opened/inspected under this reference state.

---

# 50. P1-F01 independent adjudication

P1-F01 results must be judged against the frozen protocol.

If threshold is 30 and result is 28, the reviewer may not redefine "close enough."

If the protocol says INCONCLUSIVE, result remains INCONCLUSIVE.

A changed threshold requires:

```text
P1-F00 v2
→ prospective protocol
→ new confirmatory window / justified untouched holdout
```

No retroactive reinterpretation.

---

# 51. Data Governance — PRE-CAPTURE, not pre-pilot

The original DG-00 contract was later aligned to the bounded GEI-04B run-local capture scope.

```text
DG-00 original governance baseline
57ee9a1b8e599a4acb280339304069798b83ae3f

GEI-04A2 governance alignment
816f6318d2f696aba7430c2915e33a2dfc89486d
reported local project milestone
```

The bounded GEI-04B capture authority is intentionally narrow:

```text
allowed current QEO facts:
- Operation
- NumberType
- Difficulty
- AnswerStyle
- Terminal result

retention:
- current run only
- in-memory collector

execution gate:
- effectiveGameBrainEnabled at terminal completion

prohibited in this slice:
- persistence
- cloud
- telemetry / analytics
- logging of QEO content
- advertising use
- identifiers
- Player Experience Model
- CandidateEvaluation
- DecisionEpisode
- gameplay personalization / influence
```

The public privacy disclosure for this exact local-only feature must be truthful before release; this reference does not claim that external publication has already occurred.

BRAIN-07 remains independent and ungated by GameBrain eligibility/preference.

## 51.1 Capture authority and adjudication authority are separate

A fact being canonical does not automatically authorize its capture, and capture authorization does not automatically authorize its use in a locked scientific protocol.

```text
CANONICAL TRUTH
≠
CAPTURE AUTHORITY
≠
PROTOCOL / ADJUDICATION AUTHORITY
≠
MEASUREMENT VALIDITY
```

Capture authority has conceptually separate states:

```text
NOT_AUTHORIZED
DIAGNOSTIC_ONLY
STUDY_AUTHORIZED
```

Protocol coverage is independently tri-state:

```text
EXPLICITLY_ALLOWED
EXPLICITLY_PROHIBITED
SILENT
```

Permanent rule:

```text
PROTOCOL_SILENT
≠ ALLOWED
```

If a material adjudication rule is absent from the locked protocol, it may not be inferred from adjacent clauses. If required for valid confirmatory execution, use a **prospective protocol amendment/version before the confirmatory data window**.

A new fact may be captured only after its named purpose, retention, deletion/reset behavior, and allowed/prohibited uses are explicitly authorized. "Capture it now in case it is useful later" is not an allowed default.

For a solo/small project, lightweight product/data-governance authorization may be recorded in a future append-only `docs/game_brain_governance_decisions.md` when the first new capture/retention decision actually requires it. Scientific `MET`/feasibility gates still require the independent/procedural review rules defined elsewhere in this reference.

---

# 52. Identity and privacy boundary

Question-level observation should not require real-world identity.

Do not use:

```text
name
email
school/student ID
device ID
advertising ID
Google Play identity
```

for the Question Experience boundary.

If future longitudinal identity is required, it must be separately governed and separable from real-world identity wherever possible.

---

# 53. Expansion governance — scientific gates vs product review

Expansion is not a flat checklist.

It consists of:

1. a **Product / Complexity Review**;
2. three **independent evidence/safety gate groups**.

These must be documented separately because they answer different kinds of questions.

---

# 54. Product / Complexity & Reuse Review

This is explicitly **not a scientific validity gate**.

It is a product/architecture prioritization review.

Question:

> Does the incremental value of the new Decision Context justify its engineering, research, governance, maintenance, and validation cost?

Review:

```text
what can be reused?
what must be new?
how many new scenarios?
new capture dimensions?
new synthesis logic?
new policy logic?
new persistence/governance burden?
new validation workload?
incremental product value?
```

Possible product outcomes:

```text
PRIORITIZE
DEFER
REJECT_FOR_NOW
```

Do not label this review `MET` scientifically.

---

# 55. Synthesis Reuse Review

Every proposed new Decision Context must explicitly assess:

```text
1. Which scenario/evidence semantics are reusable unchanged?
2. Which synthesis components are reusable?
3. Which mappings are truly decision-context-specific?
4. Does the new context require a new synthesis function?
5. Why can existing synthesis not be safely reused?
6. Does new synthesis duplicate semantic logic?
7. What new validation burden is introduced?
8. Does reused evidence remain inside its validated claim envelope?
9. Is a transfer-validity gate required?
```

Preferred architecture:

```text
Reusable evidence semantics
+
small decision-specific synthesis
```

Avoid both:

```text
copy-paste synthesis per context
```

and:

```text
one UniversalSynthesisEngine for everything
```

## 55.1 Cross-Context Reference Isolation Review

Before authorizing a **second influence-bearing Decision Context**, the Expansion process must review whether Reference tracks contaminate one another. This is a future expansion requirement, not a new current gate for Phase 1.

Required questions:

```text
Can the new context affect outcomes used by an existing Reference Track?
Can the existing context affect outcomes used by the new track?
Are independent allocations still valid?
Is joint / clustered / stratified allocation required?
What is the Reference Isolation Envelope for each claim horizon?
Can one episode be Reference for Context A but GameBrain-influenced for Context B?
If yes, for which outcomes is that still valid?
How is cross-context contamination detected and represented?
Do new interventions invalidate historical Reference evidence?
Is a new contemporaneous Reference window required?
Can allocator inputs/legal-option/stratification state have been causally shaped by prior GameBrain influence?
Does the relevant isolation envelope need to extend backward through prior causal history?
```

A variable being canonical does not make it historically treatment-independent. The review must preserve the distinction between **isolated now** and **isolated over the causal history relevant to the claim**.

---

# 56. Expansion Gate Group A — Evidence Integrity

Question:

> Is the knowledge GameBrain will use defensible?

Requires appropriate evidence for:

```text
truthful observation foundation
data governance operational
P1-F00 protocol preregistration
P1-F01 feasibility
Scenario Acceptance
invalid/inconclusive scenarios remaining inactive
counterfactual discipline
attribution discipline
recency/evidence-age handling
evidence opportunity preservation
epistemic preservation
evidence-transfer validity where reused
```

Result:

```text
EVIDENCE_INTEGRITY = MET | NOT_MET
```

No averaging.

---

# 57. Expansion Gate Group B — Decision Validity

Question:

> Is the conversion from evidence to a recommendation justified and testable?

Includes:

```text
Scenario→Evaluation Synthesis validated
Synthesis reuse/debt reviewed
CandidateEvaluation contract validated
Decision-specific Policy independently gated
UNKNOWN/SPARSE negative controls passed
trade-off behavior documented
stability verified
NO_PREFERENCE works
Player Agency preserved
Decision Episode trace auditable
```

Result:

```text
DECISION_VALIDITY = MET | NOT_MET
```

---

# 58. Expansion Gate Group C — Operational Safety

Question:

> Can the system operate without unsafe authority, privacy, or failure behavior?

Includes:

```text
canonical fallback verified
GameBrain failure isolation verified
slow/over-budget GEI bypass verified
GameState Growth Firewall preserved
GameBrain main-screen master disable verified
OFF → no hidden GEI capture/personalization verified
ON → persistent enablement badge verified
badge semantics do not imply active influence
Age Gate → GameBrain eligibility routing verified
under13 or unresolved eligibility → effective GameBrain OFF
teen13to17 / adult18plus → eligible subject to saved GameBrain preference
Age Gate is not interpreted as consent or parental authorization
no GEI reasoning in frame-critical/gameplay-critical path
GEI Performance Budget measured against frozen criteria
representative real-device performance reviewed
APK/AAB and storage-growth impact reviewed
authority boundary approved
reference/exploration policy approved
retention/deletion/reset operational
privacy obligations operational
no stale last-known recommendation fallback
bounded intervention scope
closed-loop provenance preserved
rollback/disable path
at least one bounded intervention audited
```

Result:

```text
OPERATIONAL_SAFETY = MET | NOT_MET
```

---

# 59. Gate Adjudication Authority

A builder or GEI implementation agent may produce evidence, but must not unilaterally declare a scientific/safety gate `MET`.

Every `MET` requires an explicit adjudication record.

Conceptual roles:

```text
Implementation Owner
        ↓ produces evidence package

Independent Reviewer
        ↓ verifies evidence against frozen criteria

Gate Adjudicator
        ↓ records final MET / NOT_MET
```

For critical gates, the adjudicator should be outside the direct implementation path where feasible.

Minimum gate record:

```text
gate_name
protocol/version
evidence_artifacts
reviewer
review_date
review_findings
unresolved_dissent
adjudicator
final_status
scope_of_MET
```

Important:

> `MET` applies only to the scope actually reviewed. It must never be treated as a universal approval.

If independent review is not available, status remains:

```text
PENDING_INDEPENDENT_REVIEW
```

rather than self-declared `MET`.

---

# 60. Expansion decision

Scientific/safety expansion is allowed only when:

```text
Evidence Integrity = MET
AND
Decision Validity = MET
AND
Operational Safety = MET
```

Separately, the Product / Complexity Review must say the context is worth prioritizing.

Therefore:

```text
Scientifically/operationally eligible
≠
Product-priority approved
```

Both are needed to proceed.

---

# 61. Current Phase-1 production-contract corrections

The Phase-1 `chooseDifficulty` production contract is now **frozen** in the project history (reported local commit `4814b78acdc95936e26ef6d4942f72e53251f2ad`, not claimed remote-verified here).

Frozen requirements:

1. `DecisionContext = chooseDifficulty` only.
2. A Decision Locus exists only when a canonical owner explicitly opens an eligible difficulty-decision opportunity.
3. Canonical owner supplies the decision context, player-agency constraints, and legal candidates.
4. Legal candidates are canonical truth; GameBrain/GEI never reconstruct legality from enum values/order or observed history.
5. The Phase-1 research envelope is a canonical supplied subset of `{Easy, Medium, Hard}`; canonical systems may still have other legal difficulties such as Expert/Insane outside that envelope.
6. No legal options → future `ABSTAIN_NO_LEGAL_OPTIONS`.
7. Observation depends on truthful lifecycle/capture and the bounded GEI-04B QEO foundation.
8. Scenario Knowledge is future evidence interpretation, never action execution.
9. Future result is `NO_PREFERENCE` or `PreferredCandidate(difficulty)` only after the later scenario/model/evaluation/policy gates.
10. Unexecuted candidates remain predicted/unknown, never observed.
11. Player agency remains supplied/constrained outside GameBrain.
12. Canonical systems execute final gameplay; `mayAffectGameplay = false` now.
13. Reference/control mechanisms preserve evidence opportunity but do not automatically establish causality.
14. DecisionEpisode remains a later policy/intervention audit unit, not a current measurement primitive.
15. Reproducibility uses bounded evidence snapshots rather than permanent raw-history retention.
16. Stability requires comparable evidence rather than reaction to small fluctuations.
17. Data Governance is pre-capture.
18. Scenario Acceptance Gates and versioned Scenario→Evaluation Synthesis remain mandatory later.
19. P1-F00 preregisters quantitative P1-F01 rules; protocol design and outcome adjudication remain role-separated.
20. Protocol amendments are prospective; no retroactive "close enough" reinterpretation.
21. Reused evidence keeps an explicit validity envelope.
22. Scientific/safety `MET` requires independent/procedural review/adjudication.
23. Product/complexity priority remains separate from scientific/safety validity.
24. Main-screen GameBrain control + persistent effective-enable badge are implemented product requirements.
25. Current age-derived GameBrain eligibility is `under13 → ineligible`, `13–17/18+ → eligible`, unresolved/invalid/stale → fail closed.
26. Age Gate is product eligibility input, not verified age/consent/parental authorization; any future consent flow is a separate governed product decision.
27. Timing / round length, answer format, mode selection, Weak Skills suggestions, Question Generator influence, and activity selection remain outside Phase 1 until the Expansion Gate.

---

# 62. Current roadmap — R4 approved sequence

The scientific path and the player-facing product path are intentionally separated. Product features may ship without becoming Phase-1 GameBrain evidence or authority.

```text
GEI-03B / GEI-04A / DG-00 / GEI-04B
Truthful bounded observation foundation
✅ COMPLETE FOR CURRENT FIRST SLICE
        ↓
GB-UX-00 + GB-ELIG-01
Visible GameBrain control + age-derived product eligibility
✅ IMPLEMENTED
        ↓
PHASE-1 chooseDifficulty contract
✅ FROZEN — 4814b78acdc95936e26ef6d4942f72e53251f2ad
        ↓
P1-F00 v1
✅ LOCKED / HISTORICAL — 02a36a948ae3626085d93cacedcdcf4ec6aa1d94
        ↓
P1-F01 truthful measurement foundation
├─ Canonical Difficulty Legality
│  ✅ 25f92d9459037f7c603f5a2c64e54fd8df2dcba8
├─ Truthful Measurement Seam
│  ✅ 947a9b4199ba0a93c11f4d75f735a9db0d462006
└─ Opportunity Identity / Ordering / Exact QEO Linkage
   ✅ 232b46c57d86d497cef93f9707ccbe334b4a2189
        ↓
Canonical Timer / App-Lifecycle Audit
✅ READ-ONLY COMPLETE
CANONICAL_TIMER_LIFECYCLE = AMBIGUOUS
P1_F01_TIMER_EVIDENCE = POTENTIALLY_CONTAMINATED
        ↓
P1-F01 Measurement Readiness Re-check
✅ 6e06f6284f3a9129e5a55cbf8be1c044cb0616a1
BLOCKED_BY_PROTOCOL_EXECUTABILITY
        ↓
P1-F00 v1.1 Lifecycle / Process-Loss Amendment
├─ Draft — 14b12e8d919abfd44583e6227d7d9cc2b40e13fe
├─ Independent review → REQUIRED_CHANGES — 62732fe37b7b2ab9a2ac16c4db11a73a69646dbc
├─ Revision — c4339b1d5ada59397854bb65f0c2ce0d3205c788
├─ Independent re-review → APPROVED_FOR_LOCK — 1abe8c934b1b4d13e3162a435b5ff21e86bb0f86
└─ ✅ LOCKED / CURRENT PROSPECTIVE PROTOCOL — b7a77db760b1b6e0b65409f26c45c2d892139cdf
        ↓
P1-F01 Minimum Integrity Mechanism Design
✅ DESIGN_READY_FOR_GOVERNANCE — 8a2952ff92adc438718925419423498ec42d78e4
selected design: minimized local SQLite transactional integrity state
        ↓
GD-P1F01-INTEGRITY-001
✅ PRODUCT/DATA AUTHORIZED — e3a2745131901438c6baa36b4e6e6ca4b98db791
local integrity facts only; confirmatory collection still closed
        ↓
P1-F01 MINIMUM LOCAL INTEGRITY IMPLEMENTATION
← CURRENT NEXT IMPLEMENTATION TASK
        ↓
G → F → E + 11-property implementation proof
        ↓
P1-F01 MEASUREMENT READINESS RE-CHECK
        ↓
──────────────── PRODUCT TRACK CHECKPOINT ────────────────
        ↓
TIMINGSTYLE FOUNDATION
perQuestion | untimed | timeBank
        ↓
DEEP THINKING / UNTIMED
player-facing gameplay feature
        ↓
TIME_BANK_BUDGET_CONTRACT v1
freeze initial bank / question-count / difficulty / Adaptive / exhaustion / replay rules
        ↓
TIME BANK
player-facing gameplay feature
        ↓
MENTAL MATH PRACTICE v1
├─ Free Practice
├─ Daily Mental Math
├─ Weak Skills Practice
└─ Targeted Repetition
        ↓
──────────────── RETURN TO P1-F01 STUDY TRACK ────────────────
        ↓
BOUNDED STUDY EVIDENCE / CROSS-RUN MEASUREMENT
only the minimum separately governed evidence needed for:
common support + run segments + temporal checks + exposure + Wilson precision
        ↓
FINAL PRE-WINDOW READINESS / INTEGRITY CHECK
        ↓
P1-F01 CONFIRMATORY WINDOW
        ↓
FEASIBLE / INCONCLUSIVE / NOT_FEASIBLE
        ↓
if NOT_FEASIBLE
→ root-cause classification
→ defer chooseDifficulty OR separately gate evidence-acquisition/exploration study
→ never auto-authorize exploration
        ↓
only if FEASIBLE
        ↓
DIFFICULTY SCENARIO LIBRARY
        ↓
SCENARIO ACCEPTANCE PROTOCOLS / GATES
        ↓
VALIDATED SCENARIO EVIDENCE ONLY
        ↓
BOUNDED DIFFICULTY EXPERIENCE MEMORY
        ↓
PLAYER × DIFFICULTY MODEL
        ↓
REUSABLE EVIDENCE SEMANTICS
        ↓
VERSIONED SCENARIO→EVALUATION SYNTHESIS
        ↓
SYNTHESIS VALIDATION
        ↓
CandidateEvaluation[]
        ↓
EPISTEMIC PRESERVATION
        ↓
VERSIONED DIFFICULTY POLICY
        ↓
POLICY RESEARCH / VALIDATION
        ↓
SHADOW DECISION EPISODES
        ↓
DG-00-S1 / R1-REF-P00 / REFERENCE-CONTROL TRACK
        ↓
F11 STARVATION / CAPABILITY FRONTIER PROTOCOLS
        ↓
PERF-00 SHADOW PERFORMANCE / SIZE BUDGET
        ↓
STABILITY + PLAYER AGENCY + AUTHORITY
        ↓
BOUNDED chooseDifficulty PILOT
        ↓
REALIZED STARVATION / SELF-INFLUENCE AUDIT
        ↓
CLOSED-LOOP LEARNING
        ↓
PHASE-1 AUDIT + EXPANSION GATE
```

### 62.1 Approved near-term product package

The approved near-term gameplay sequence is:

```text
TimingStyle foundation
→ Deep Thinking / Untimed
→ Time Bank budget contract
→ Time Bank
→ Mental Math Practice v1
```

These features are **not** a Phase-1 GameBrain Decision Context and do not enter the current P1-F01 `chooseDifficulty` confirmatory evidence envelope. The current Phase-1 timing firewall remains:

```text
perQuestion → may be eligible for current P1-F01 if every other frozen criterion passes
untimed     → OUTSIDE_PHASE1_ENVELOPE
timeBank    → OUTSIDE_PHASE1_ENVELOPE
Mental Math → OUTSIDE_PHASE1_ENVELOPE
```

### 62.2 Mental Math Practice v1 — approved scope

Mental Math v1 is a player-facing practice package that must work independently of GameBrain intelligence. Approved v1 scope:

```text
Modes / entry points:
- Free Practice
- Daily Mental Math
- Weak Skills Practice

Shared in-session engine:
- Targeted Repetition

Operations:
- Addition
- Subtraction
- Multiplication
- Division
- Mixed

Difficulty:
- Easy
- Medium
- Hard

Length:
- 10
- 20
- 30 questions

Initial answer path:
- reuse existing canonical answer mechanics; Choice4 is acceptable for v1

Results:
- correct / incorrect
- accuracy
- best streak
```

Weak Skills Practice must reuse the existing Weak Skills eligibility/ranking/focus-lock rules and existing mastery data; it must not create a second mastery/progression system. Targeted Repetition is a deterministic practice mechanic, not ML: an error may enqueue a related item/skill for reappearance after intervening questions; a successful repeat may reduce repetition priority. It must avoid immediate rote repetition loops.

Daily Mental Math v1 is a short ready-to-play daily session. Persistent daily-streak history is **not automatically included** in v1; if later added, its persistence semantics must be explicitly designed rather than implied by the word “Daily.”

Mental Math v1 does not authorize GameBrain personalization, Player Model inference, cognitive/psychological profiling, or use of Mental Math outcomes inside P1-F01. Future GameBrain practice recommendations require a later bounded Decision Context / evidence contract.

---

# 63. Future Decision Contexts

Only after the Phase-1 expansion gate.

Possible future contexts:

```text
chooseRoundLength
chooseAnswerFormat
chooseTimingCondition
choosePracticeConfiguration
chooseNextActivity
question-experience intent
distractor intent
```

Each new context reuses the same architecture but must separately justify evidence validity, synthesis applicability, policy validity, authority, and product complexity.

---

# 64. Future consumer systems

Potential consumers:

```text
Skill Dashboard
Weak Skills Practice
Question Generator
Distractor Generator
Time Management
Adaptive Difficulty
Mode / Activity Selection
```

Each receives a bounded typed contract.

---

# 65. Skill Dashboard future role

Canonical mastery remains canonical.

Example coexistence:

```text
Canonical Mastery:
Multiplication = 78

GEI Experience:
Medium Choice4 → established
Hard → sparse
Trajectory → improving
Time pressure → mixed
Assistance usage → decreasing
```

GEI must never manufacture or overwrite mastery.

---

# 66. Weak Skills future role

GEI may eventually provide bounded practice-intent evidence such as:

```text
operation = Division
format = Written
timing = Normal
objective = buildExperience
evidence = sparse Written exposure
```

Weak Skills remains owner of eligibility, ranking, and focus-lock policy.

---

# 67. Question Generator future role

GameBrain answers:

> What kind of experience appears useful?

Generator answers:

> How do I construct a legal mathematical question?

GameBrain does not choose operands, correct answer, legal form, or RNG.

---

# 68. Distractor Generator future role

GEI may use observable response-history compatibility to request informative legal distractors.

Permanent rule:

```text
response compatibility
≠
hidden misconception
```

BRAIN-06’s anti-overclaim lesson remains permanent.

---

# 69. Behavioral Experience future role

Future behavioral evidence may cover:

```text
exit/abandonment associations
session-length behavior
late-run degradation
voluntary format selection
mode return/replay
challenge-seeking
persistence after error
assistance behavior
timing-pressure behavior
```

Never store emotional/psychological labels as facts.

---

# 70. Current progress status — R4

```text
GameBrain v1 Core
STABLE

BRAIN-07
Context-evidence observer exists
always-on relative to GameBrain preference/eligibility
bounded run-local shadow evidence

GBI-01
Adaptive shadow integration exists
shadow-only; no gameplay authority

GB-UX-00
✅ IMPLEMENTED
a2deb3e9eccc6ecc14704c78badb877d18afa357

GB-ELIG-01
✅ IMPLEMENTED
e90f216f51255b4473635155b04a37272ea308ac

GEI-04B
✅ RUN_LOCAL_CAPTURE_IMPLEMENTED
25e29301c0eca1d58603d63e774d41df0aeccaf5
five-field in-memory QEO only

PHASE-1 chooseDifficulty contract
✅ FROZEN
4814b78acdc95936e26ef6d4942f72e53251f2ad

P1-F00 v1
✅ LOCKED / HISTORICAL
02a36a948ae3626085d93cacedcdcf4ec6aa1d94

P1-F01 canonical difficulty legality
✅ IMPLEMENTED
25f92d9459037f7c603f5a2c64e54fd8df2dcba8

P1-F01 truthful difficulty measurement seam
✅ IMPLEMENTED
947a9b4199ba0a93c11f4d75f735a9db0d462006

P1-F01 opportunity identity / ordering / exact QEO linkage
✅ IMPLEMENTED
232b46c57d86d497cef93f9707ccbe334b4a2189

Canonical timer / app-lifecycle audit
✅ COMPLETED READ-ONLY
CANONICAL_TIMER_LIFECYCLE = AMBIGUOUS
P1_F01_TIMER_EVIDENCE = POTENTIALLY_CONTAMINATED

P1-F01 measurement readiness re-check
✅ COMPLETED
6e06f6284f3a9129e5a55cbf8be1c044cb0616a1
BLOCKED_BY_PROTOCOL_EXECUTABILITY

P1-F00 v1.1 lifecycle/process-loss amendment
✅ LOCKED / CURRENT PROSPECTIVE PROTOCOL
b7a77db760b1b6e0b65409f26c45c2d892139cdf
independent review + required changes + independent re-review complete

P1-F01 minimum integrity mechanism design
✅ DESIGN_READY_FOR_GOVERNANCE
8a2952ff92adc438718925419423498ec42d78e4
recommended: minimized local SQLite transactional integrity state

GD-P1F01-INTEGRITY-001
✅ AUTHORIZED
e3a2745131901438c6baa36b4e6e6ca4b98db791
local integrity facts only
no cloud / telemetry / personalization / confirmatory collection

Current implementation task
P1-F01 MINIMUM LOCAL INTEGRITY IMPLEMENTATION
then G→F→E + locked-property proof + readiness re-check

Near-term product roadmap
✅ APPROVED PLAN / NOT IMPLEMENTED
TimingStyle foundation
→ Deep Thinking / Untimed
→ Time Bank budget contract
→ Time Bank
→ Mental Math Practice v1
   ├─ Free Practice
   ├─ Daily Mental Math
   ├─ Weak Skills Practice
   └─ Targeted Repetition

P1-F01 bounded cross-run study evidence
NOT IMPLEMENTED / NOT YET AUTHORIZED AS A STUDY STORE

P1-F01 confirmatory data window
NOT OPENED

Scenario Library
NOT STARTED

Bounded Difficulty Experience Memory
NOT STARTED

Player × Difficulty Model
NOT STARTED

CandidateEvaluation
NOT STARTED

DecisionEpisode runtime
NOT AUTHORIZED / NOT IMPLEMENTED

Premature GEI-05 DecisionEpisode implementation
SAFELY PARKED IN GIT STASH
must remain parked unless explicitly reframed later
```

---

# 71. Current authority status — R4

```text
GameBrain gameplay authority
DEFERRED

mayAffectGameplay
false

GameBrain main-screen preference + effective badge
IMPLEMENTED

GameBrain age-derived eligibility
IMPLEMENTED
under13/unresolved → effective OFF
teen/adult → eligible subject to saved preference

GEI-04B five-field run-local QEO capture
AUTHORIZED + IMPLEMENTED FOR THE BOUNDED CURRENT SLICE
current-run in-memory only
no cloud/telemetry

BRAIN-07 observation
ACTIVE IN ALL AGE/PREFERENCE STATES
independent of GameBrain effective enablement

P1-F01 minimum local integrity capture
AUTHORIZED FOR THE NAMED INTEGRITY PURPOSE ONLY
GD-P1F01-INTEGRITY-001
local device only
future SQLite permitted
confirmatory collection NOT authorized by this decision

General long-term GEI persistence
NOT AUTHORIZED

P1-F01 bounded study evidence store / cross-run confirmatory evidence retention
NOT AUTHORIZED YET
requires a separate minimal-purpose design/governance decision after integrity readiness

Personalization
NOT AUTHORIZED

DecisionEpisode capture/runtime
NOT AUTHORIZED

Scenario / Player Experience Model
NOT AUTHORIZED

CandidateEvaluation gameplay influence
NOT AUTHORIZED

GEI cloud persistence
NOT AUTHORIZED

GEI telemetry / analytics
PROHIBITED FOR CURRENT SLICE

TimingStyle canonical product foundation
APPROVED ROADMAP / NOT IMPLEMENTED

Deep Thinking / Untimed
APPROVED NEAR-TERM PRODUCT FEATURE / NOT IMPLEMENTED
may be implemented without making timing a GameBrain Decision Context

Time Bank
APPROVED NEAR-TERM PRODUCT FEATURE / NOT IMPLEMENTED
requires explicit TIME_BANK_BUDGET_CONTRACT v1 before implementation

Mental Math Practice v1
APPROVED NEAR-TERM PRODUCT PACKAGE / NOT IMPLEMENTED
Free Practice + Daily Mental Math + Weak Skills Practice + Targeted Repetition
outside current P1-F01 evidence envelope

GameBrain timing intelligence / chooseTimingCondition
OUTSIDE PHASE 1
NOT AUTHORIZED

GameBrain practice-selection intelligence / choosePracticeConfiguration
FUTURE DECISION CONTEXT
NOT AUTHORIZED

P1-F01 confirmatory collection
CLOSED / NOT AUTHORIZED TO OPEN YET

R1 / Reference / F11 package
FROZEN_FOR_FUTURE_PROTOCOLIZATION
PARKED; NOT CURRENT TASK
```

---

# 72. Next authorized task

Current path:

```text
P1-F01 MINIMUM LOCAL INTEGRITY IMPLEMENTATION
← NEXT AUTHORIZED IMPLEMENTATION TASK
```

Baseline for the next task is the latest reported local project baseline:

```text
e3a2745131901438c6baa36b4e6e6ca4b98db791
Authorize local P1-F01 integrity capture
```

The implementation must follow the locked P1-F00 v1.1 protocol, the selected minimum-integrity design, and `GD-P1F01-INTEGRITY-001`. The intended mechanism is a minimized local transactional SQLite integrity store; the implementation task must still select/verify an appropriate Flutter SQLite primitive rather than assume one.

Required scope:

```text
- scientific measurement-window admission only after durable OPEN commit
- gameplay always continues if integrity storage fails
- OPEN / CLEANLY_CLOSED / LEFT_UNCLEAN integrity semantics
- monotonic admitted O_raw accounting
- exact Phase-1 legal-set accounting, no legality inference
- deterministic ordinal/idempotence handling
- crash-consistent transaction boundaries
- full reset + Clear GameBrain Data deletion wiring
- no raw QEO history / identity / timestamps / mastery / predictions
- no cloud / telemetry / analytics
- mayAffectGameplay = false
```

After implementation, validate the locked properties in G→F→E order and report actual implementation evidence for `K_under`, `K_over`, divergence direction, recovery/idempotence, and gameplay noninterference. Design targets such as `K_under=0` / `K_over=0` are not implementation facts until proven.

Then perform a new P1-F01 measurement-readiness re-check.

After that readiness checkpoint, the approved near-term player-facing product sequence is:

```text
TimingStyle foundation
→ Deep Thinking / Untimed
→ Time Bank budget contract
→ Time Bank
→ Mental Math Practice v1
```

Only after that product checkpoint does the current roadmap return to the remaining bounded cross-run P1-F01 study-evidence work and eventual fresh confirmatory window. Product work must not silently enter the Phase-1 evidence envelope.

Do not start Scenario Library, Player Model, CandidateEvaluation, DecisionEpisode, long-term memory, confirmatory collection, or a generalized evidence database in the current task.

---

# 73. Governance additions from latest review

These are now mandatory.

## GOV-1 — Protocol Authoring Independence

P1-F00 must be reviewed before lock by a role outside the direct GEI implementation path where feasible.

## GOV-2 — Prospective Amendment + Independent Data Window

A protocol version informed by prior results must use new confirmatory data or an untouched holdout; prior seen data is development data unless reuse is explicitly labeled and justified.

## GOV-3 — Evidence Transfer Validity

Reusable evidence retains its original validated claim envelope. New Decision Contexts must justify applicability; validity does not transfer automatically.

## GOV-4 — Product Review Separation

Complexity/Reuse is a product/architecture prioritization review, not a scientific `MET` gate.

## GOV-5 — Gate Adjudication Authority

Builders cannot self-declare critical gates `MET`. Independent review and explicit adjudication are required.

## GOV-6 — Reviewer Eligibility Is Role-Based, Not Vendor/Model-Based

A critical gate requires an eligible independent reviewer, but must not depend on one named model/provider.

Reviewer eligibility is defined by:

```text
separation from implementation role
frozen criteria before adjudication
read-only behavior where the gate requires it
active falsification duty
explicit uncertainty/blocking disclosure
explicit gate outcome
no authority to rewrite criteria during review
clean-worktree preservation
```

An eligible reviewer may be an independent qualified human, an approved independent AI model/provider, or a procedurally separate review agent/session that satisfies the same role constraints.

Reviewer substitution due to availability must trigger a fresh review from frozen inputs. An incomplete/blocked prior review cannot be promoted to PASS. Tool/model unavailability is never itself evidence for PASS.

## ARCH-PERF-1 — GameState Growth Firewall

GEI intelligence remains outside `GameState`; only canonical truth and narrow capture/integration seams may live there.

## ARCH-PERF-2 — Optional Intelligence Performance Rule

Slow, failed, unsupported, or uncertain GEI must never block canonical gameplay. It must abstain or be bypassed.

## ARCH-PERF-3 — Bounded / Event-Driven Intelligence

No frame-loop intelligence, unbounded history scans, Cartesian Player Model, or unconditional all-scenario evaluation.

## ARCH-PERF-4 — Measured Performance, Not Assumed Performance

Before real authority, GEI must pass a frozen performance/size budget using representative release/profile measurements on real hardware.

## GB-USER-GOV-1 — Visible Optionality

GameBrain optionality must be visible and testable from the main screen and during gameplay:

```text
Main screen → authoritative GameBrain ON/OFF control
ON          → persistent gameplay badge
OFF         → badge absent + canonical-only behavior
```

The indicator represents enablement, not confidence or per-decision influence.

## GB-USER-GOV-2 — Age-Gated Eligibility

The neutral Age Gate is resolved before GameBrain effective enablement using the current product policy:

```text
under13 → ineligible
teen13to17 → eligible
adult18plus → eligible
missing / invalid / stale → unresolved → fail closed
```

(Spelling note: the canonical enum name remains `teen13to17`; the line above is semantic shorthand.)

The Age Gate is not verified age, consent, or parental authorization. Any future requirement for a separate consent/parental mechanism must be introduced as a new governed product decision and may not be inferred from this eligibility mapping.

---

# 73A. Architecture/performance update log

Latest accepted performance conclusions:

```text
GameState growth risk
→ controlled by responsibility firewall, not arbitrary line cap

Binary size
→ expected to increase modestly
→ must still be measured

CPU/RAM
→ expected to remain small if bounded + event-driven
→ must not rely on assumption

Scenario growth
→ use relevant-family evaluation, not global scanning

Long-term memory
→ aggregated/bounded, never raw-history scan

Low-end hardware
→ representative real-device profiling required

GEI latency failure
→ abstain/bypass
→ canonical game continues
```

These rules protect the recently completed refactor from being reversed by a new intelligence god-object.

---


# 73B. Main-Screen / Age-Gate Product-Control Update

Current implemented product-control semantics:

```text
Neutral Age Gate
        ↓
GameBrainEligibility
        ├─ under13        → INELIGIBLE
        ├─ teen13to17     → ELIGIBLE
        ├─ adult18plus    → ELIGIBLE
        └─ unresolved     → UNRESOLVED / fail closed
        ↓
Saved GameBrain preference
        ↓
effectiveGameBrainEnabled
=
preference ON + eligibility ELIGIBLE
```

During gameplay:

```text
effective ON  → persistent GameBrain badge visible
effective OFF → badge absent
```

The saved preference may remain ON while eligibility is temporarily ineligible/unresolved; effective state recomputes immediately from the current age-derived eligibility.

Three concepts remain separate:

```text
Age-range selection
≠
GameBrain product eligibility
≠
GameBrain saved preference / effective enablement
```

The Age Gate is not verified age or consent. There is no current `GB-PARENT-00` dependency in the implemented GameBrain eligibility policy.


# 73C. TimingStyle, Lifecycle & P1-F01 Measurement-Integrity Update — 2026-08-21

This update records product ideas that improve future evidence quality **without expanding the current Phase-1 GameBrain Decision Context**.

## 73C.1 Permanent measurement distinctions

```text
GAME SCORE
≠ MATH ABILITY
≠ PROCESSING SPEED
≠ INTELLIGENCE
```

Observable gameplay evidence may support bounded experience claims; it must not silently become a fixed cognitive/psychological trait claim.

Written/open numeric answers may become stronger evidence for some claims than Choice4 because guessing/elimination pathways differ, but evidence from different answer modalities must remain explicitly conditioned and must not be pooled as interchangeable evidence without a validated comparison contract.

## 73C.2 Planned canonical TimingStyle product foundation

Conceptual product API:

```text
TimingStyle
- perQuestion
- untimed
- timeBank
```

This is a **canonical gameplay/run configuration fact**, not a GameBrain decision output.

### Immutable run snapshot

At run start:

```text
canonicalTimingStyleSnapshot = selected TimingStyle
```

During an active run, that snapshot must be technically immutable. Any external/menu setting change applies to the **next run**, not the active run. Implementation review must explicitly check whether any mutable path can alter timing style after run start.

## 73C.3 Deep Thinking / Untimed

Planned behavior:

```text
same canonical question generation
same difficulty rules
same answer mechanics
no per-question countdown timeout
```

Deep Thinking may be implemented as a product feature before timing becomes a GameBrain Decision Context. Its future evidence value is that comparable timed vs untimed conditions may help distinguish observed time-pressure association from difficulty association, subject to preregistered sample/precision/confounding requirements.

No cognitive-latency or intelligence claim is authorized.

## 73C.4 Time Bank

Planned behavior:

```text
one bounded time budget for the run
questions consume the shared bank
bank does not reset per question
```

Before implementation, freeze an explicit product contract for:

```text
initialBank formula/value
question-count treatment
difficulty treatment
Adaptive treatment
bank-exhaustion behavior
replay behavior
```

The bank budget is a gameplay-difficulty decision, not an implementation detail. Do not pre-generate questions merely to calculate the bank if that would alter RNG/canonical behavior.

## 73C.5 Phase-1 timing firewall — filter before capture

Phase 1 remains:

```text
DecisionContext = chooseDifficulty
```

Timing/round length remains outside the Phase-1 expansion envelope.

The current five-field QEO schema is **not** expanded with `timingStyle` merely to support P1-F01 filtering. Instead, filtering occurs at the canonical opportunity boundary before a P1-F01 measurement record is created:

```text
canonical run TimingStyle snapshot
        ↓
canonical difficulty opportunity
        ↓
P1-F01 eligibility projection
        ├─ perQuestion
        │   → may create P1-F01 raw opportunity if all other frozen criteria pass
        │
        └─ untimed / timeBank
            → OUTSIDE_PHASE1_ENVELOPE
            → no P1-F01 raw opportunity record
```

This avoids adding a new QEO field solely to repair downstream filtering.

## 73C.6 Selection provenance is not Decision Purpose

A future P1-F01 measurement seam should preserve the canonical route by which executed difficulty arose, but must not confuse that provenance with the later policy/intervention `DecisionPurpose` concept.

Potential route labels are valid only if the canonical audit proves the corresponding route exists, for example:

```text
systemDefault
playerConfigured
adaptiveEngine
replayRetained
modeForced
```

Permanent separation:

```text
selectionRoute
≠
decisionPurpose
```

An Adaptive-selected success is observed evidence under an Adaptive-conditioned selection mechanism; it is not automatically independent confirmation. A manual selection is not automatically an exploration probe.

## 73C.7 Opportunity ordering and truncation semantics

If used later:

```text
opportunityOrdinalWithinRun
= 1-based ordinal of actual eligible canonical opportunities in that run
```

It resets per run and counts only opportunities that actually existed. If a Time Bank run ends after opportunity 6, opportunities 7–10 do not become synthetic UNKNOWN/failure records.

```text
NO_OPPORTUNITY
≠ UNKNOWN
≠ NEGATIVE EVIDENCE
```

Run summaries, when eventually implemented, should preserve factual counts. Low exposure such as `1/1 correct` remains a factual count; the interpretation layer may still classify the evidence as `SPARSE / UNKNOWN / INSUFFICIENT` until a preregistered evidence-sufficiency/precision rule passes.

No universal magic `N` is frozen. Material experience claims require predeclared comparable-sample/precision/missingness/confounding requirements appropriate to the claim.

## 73C.8 Opportunity-level linkage semantics

```text
NO_OPPORTUNITY
= canonical opportunity never opened

LINKED
= opportunity opened + accepted canonical terminal QEO linked exactly once

MISSING / UNLINKED
= opportunity definitely opened + explicit observable canonical closure occurred + no valid terminal linkage exists

UNKNOWN / INSUFFICIENT
= valid linked evidence exists but quantity/precision is insufficient for interpretation
```

A normal canonical `QuestionTimedOut` is a **LINKED terminal outcome**, not MISSING.

Do not fabricate `incorrect`, `timeout`, or `abandoned` merely because a terminal/link is absent.

## 73C.9 Backgrounding is not closure

```text
background / inactive / pause
≠ explicit run closure
≠ timeout by definition
≠ process loss by definition
```

Backgrounding leaves an in-memory opportunity logically open unless canonical gameplay explicitly closes it. If the player resumes and the process survived, the same opportunity may continue according to canonical timer rules.

If the OS later kills the process silently, a pure non-persistent study cannot retrospectively know that an unfinished window existed. Therefore process loss is **not** an opportunity status that can always be recorded.

No new GEI/P1 field such as `wasBackgroundedDuringOpportunity` is currently authorized merely because it would be diagnostically useful. The read-only lifecycle audit may inspect canonical behavior without adding capture. Any future durable or run-local capture of an interruption/background fact must pass the capture-authority gate first.

Study/window integrity concepts are separate:

```text
CLEAN_WINDOW
OBSERVED_UNCLEAN_CLOSURE
POTENTIAL_PROCESS_LOSS_CENSORING
INTEGRITY_NOT_ESTIMABLE_UNDER_NON_PERSISTENT_CAPTURE
```

Silent process loss can remove numerator/denominator evidence and create survivor-selection risk. Pure non-persistence cannot empirically prove its own silent-loss rate.

## 73C.10 Early canonical timer/app-lifecycle audit

A read-only audit is an immediate parallel task, not something to postpone until the confirmatory window.

Inspect:

```text
background
inactive
pause
resume
OS suspension/process death assumptions
countdown implementation
timeout callback behavior
explicit End Run / navigation closure
```

Produce two independent findings:

```text
A. GAMEPLAY CORRECTNESS FINDING
B. P1-F01 MEASUREMENT-INTEGRITY FINDING
```

If background time can create an unintended player timeout in the live canonical game, treat that as a **canonical gameplay defect** and fix it there. GEI must never repair a bad canonical timeout by merely ignoring it downstream.

## 73C.11 P1-F01 bootstrapping gate for process-loss/censoring

Before a real confirmatory window, answer in this order:

```text
1. CANONICAL TRUTH
   What lifecycle/integrity fact actually exists?

2. PROTOCOL COVERAGE
   Does locked P1-F00 explicitly address its use?
   → ALLOWED / PROHIBITED / SILENT
   SILENT is not permission.

3. CAPTURE AUTHORITY
   Are the minimum required facts authorized for the named purpose?

4. REQUIRED ESTIMAND
   What exactly must be known?
   - unclean-window frequency?
   - lost-run risk?
   - potentially lost O_raw proportion?
   - another predeclared quantity?

5. MINIMUM SUFFICIENT DURABILITY
   What is the smallest durable state capable of supporting that estimand truthfully?
```

Possible durability levels:

```text
A — PURE NON-PERSISTENT
- no durable study state
- process death silently removes in-memory evidence
- cannot estimate its own silent-loss/censoring rate

B1 — MINIMAL INTEGRITY / DIAGNOSTIC RETENTION
- bounded diagnostic state only
- e.g. started/cleanly-closed counts or a dirty-window marker
- no opportunity reconstruction by default
- still requires explicit capture/retention authorization
- smaller scope does not make governance permission automatic
- diagnostic use does not imply P1-F01 adjudication authority

B2 — STUDY-GRADE RECOVERY RETENTION
- enough bounded/versioned state to preserve/reconstruct the locked P1-F01 measurement semantics
- may include opportunity existence/linkage/order/legal/provenance facts only if separately authorized
```

Do not choose B1/B2 merely because they are technically convenient. Choose the minimum sufficient durability **after** the estimand is defined and capture authority is granted.

## 73C.12 Capture-authority × protocol-coverage cross-product

The two dimensions are independent. The authoritative interpretation is the full cross-product, not a flattened one-dimensional checklist.

```text
Capture Authority:
NOT_AUTHORIZED | DIAGNOSTIC_ONLY | STUDY_AUTHORIZED

Protocol Coverage:
ALLOWED | PROHIBITED | SILENT
```

P1-F01 adjudication may use a fact only when capture/study authority permits that use **and** the locked protocol explicitly permits the adjudication rule.

Authoritative cross-product:

| Capture authority ↓ / Protocol coverage → | `ALLOWED` | `PROHIBITED` | `SILENT` |
|---|---|---|---|
| `NOT_AUTHORIZED` | no capture; no P1-F01 use | no capture; no P1-F01 use | no capture; no P1-F01 use |
| `DIAGNOSTIC_ONLY` | diagnostic capture only; no confirmatory P1-F01 use | diagnostic capture may exist for its named purpose; P1-F01 use prohibited | diagnostic capture may exist for its named purpose; P1-F01 use prohibited |
| `STUDY_AUTHORIZED` | capture + P1-F01 use only as the locked rule explicitly defines | capture may exist for another authorized purpose; P1-F01 use prohibited | capture may exist, but P1-F01 use prohibited until prospective protocol amendment |

Examples:

```text
STUDY_AUTHORIZED + PROHIBITED
→ capture may still be authorized for another named purpose
→ P1-F01 use prohibited

STUDY_AUTHORIZED + SILENT
→ capture may exist
→ P1-F01 use still prohibited until prospective amendment

NOT_AUTHORIZED + ALLOWED
→ protocol permission does not create collection authority
```

## 73C.13 Lightweight solo-project authorization artifact

Do not create bureaucracy for ordinary implementation details. When a **new capture/retention/purpose** decision is genuinely needed, the Product/Data Owner may record a small append-only decision block in:

```text
docs/game_brain_governance_decisions.md
```

A decision block should minimally state:

```text
decision id + date
owner role
authorized / not authorized
named purpose
facts allowed
retention
deletion/reset semantics
allowed use
prohibited use
protocol relationship
effective commit
```

The commit SHA provides provenance. This lightweight owner authorization is separate from formal scientific/safety `MET` adjudication, where the builder/analyst must not self-approve the gate.

## 73C.14 Current scope status

```text
TimingStyle foundation
APPROVED ROADMAP / NOT IMPLEMENTED

Deep Thinking / Untimed
APPROVED NEAR-TERM PRODUCT FEATURE / NOT IMPLEMENTED

Time Bank
APPROVED NEAR-TERM PRODUCT FEATURE / NOT IMPLEMENTED
requires TIME_BANK_BUDGET_CONTRACT v1 first

Mental Math Practice v1
APPROVED NEAR-TERM PRODUCT PACKAGE / NOT IMPLEMENTED
Free Practice + Daily Mental Math + Weak Skills Practice + Targeted Repetition

GameBrain timing DecisionContext
NOT AUTHORIZED

GameBrain practice-selection DecisionContext
NOT AUTHORIZED

QEO timingStyle field
NOT AUTHORIZED / NOT REQUIRED FOR CURRENT P1-F01 FILTERING DESIGN

P1-F00 v1.1 lifecycle/process-loss protocol
LOCKED / CURRENT PROSPECTIVE PROTOCOL

P1-F01 minimum integrity design
DESIGN_READY_FOR_GOVERNANCE → governance completed

GD-P1F01-INTEGRITY-001
AUTHORIZED for minimal local integrity facts only

P1-F01 integrity implementation
NEXT IMPLEMENTATION TASK

P1-F01 confirmatory window
NOT OPENED
```

## 73C.15 Completed canonical timer/app-lifecycle audit result

Read-only audit baseline:

```text
232b46c57d86d497cef93f9707ccbe334b4a2189
branch: codex/canonical-timer-lifecycle-audit
worktree: clean
files changed: none
commit: none
```

Implemented timer truth found by repository inspection:

```text
Primary production timer owner: lib/engine/game_state.dart
Timer mechanism: 100 ms Timer.periodic + DateTime.now() wall-clock deltas
Ordinary timed modes: per-question timers
Blitz / Combo: run-global timers
Gameplay app-lifecycle handling: none for inactive/paused/hidden/detached
lib/main.dart lifecycle action: resumed → banner resync only
```

Canonical background behavior is therefore currently a gameplay no-op: the game does not pause, cancel, close, or reconstruct question/run timers merely because the app becomes inactive/backgrounded. On a later callback, wall-clock elapsed may include the background interval.

Repository inspection proved that `_onTimeout` can reach `_onAnswer`, and the existing `_claimQuestionTerminal((runId, questionId), claim)` may accept that timeout when the token remains current/unclaimed/accepting. An accepted timeout can therefore flow through normal canonical effects, including relevant score/history/time/turn/adaptive/lives/feedback/end behavior, BRAIN-07, eligible QEO `QuestionTimedOut`, and P1-F01 linkage.

Repository inspection could **not** establish whether Dart timer callbacks execute while the process is OS-backgrounded versus being delivered only after resume; that is platform/runtime-dependent. Permanent search rule applies:

```text
SEARCH INCOMPLETE != NOT FOUND
```

A runtime observation would be required only to establish lifecycle transition timing relative to timer callback delivery. This audit authorizes no such capture.

Gameplay correctness result:

```text
CANONICAL_TIMER_LIFECYCLE = AMBIGUOUS
```

Reason: no inspected behavior contract/test defines whether backgrounding is intended to pause, continue, or close timed gameplay. Therefore the audit did not label current behavior a proven live gameplay defect.

Measurement-integrity result:

```text
P1_F01_TIMER_EVIDENCE = POTENTIALLY_CONTAMINATED
```

Reason: a canonical `QuestionTimedOut` may include background wall-clock time, while the current QEO/opportunity linkage contains no authorized lifecycle/interruption fact. The timeout remains a truthful canonical terminal event, but its interpretation as comparable difficulty evidence may be confounded by unobserved background interruption.

This finding does **not** itself authorize:

```text
background/interruption capture
P1-F01 exclusion rules
P1-F00 reinterpretation/amendment
B1/B2 retention
runtime instrumentation
Time Bank / Untimed implementation
GameBrain timing intelligence
```

Process death remains current in-memory loss: active run/question/timer/measurement state disappears, and no active-run restoration path was found. Cross-restart recovery remains outside the current authorized slice.

---

# 73D. P1-F00 v1.1 Integrity Protocol & P1-F01 Local Integrity Update — 2026-08-22

This section records the post-R3 integrity work and supersedes earlier statements that B1/B2 retention was wholly unresolved. The project no longer uses `B1`, `B1+`, or `B2` labels as proof of sufficiency; sufficiency is defined by required observable properties.

## 73D.1 Readiness blocker and protocol correction

The post-linkage readiness re-check found:

```text
P1_F01_MEASUREMENT_READINESS = BLOCKED_BY_PROTOCOL_EXECUTABILITY
6e06f6284f3a9129e5a55cbf8be1c044cb0616a1
```

Key reasons were incomplete `O_raw` / `O_valid` denominators, lifecycle/background protocol silence, non-persistent process-loss censoring, unavailable cross-run integrity, and inability of a pure non-persistent design to estimate its own silent-loss rate.

P1-F00 v1.1 prospectively resolves the protocol semantics without authorizing capture. It defines lifecycle-censored opportunities, explicit unlinked closure, silent process loss, window integrity, conservative uncertainty, and the G→F→E proof dependency.

## 73D.2 Dual-write / cross-boundary integrity rule

The project explicitly rejects making measurement storage the authority that decides whether canonical gameplay may occur. Therefore scientific admission and gameplay execution remain separate.

A compliant future mechanism must make the **scientific population** depend on crash-consistent measurement admission while keeping gameplay fail-open:

```text
measurement admission succeeds
→ window/opportunity may enter the confirmatory measurement population

measurement admission fails
→ gameplay continues normally
→ measurement remains inadmissible / fails closed scientifically
```

The protocol does not require impossible zero-race semantics merely because gameplay and measurement are separate. Instead, future implementation must prove complete admitted-window detection, idempotence or finite duplicate divergence, finite `K_under`, finite `K_over`, and conservative threshold treatment. A finite per-event bound is insufficient if admitted unclean-window detection itself is incomplete.

## 73D.3 Minimum integrity design

The selected design at commit `8a2952ff92adc438718925419423498ec42d78e4` is a **minimal local transactional SQLite window-summary integrity store**, not an event-sourced gameplay authority and not a study evidence database.

Design target:

```text
one eligible Phase-1 run → at most one scientific integrity window

durable OPEN admission
→ measurement window admitted

per admitted O_raw opening:
transactionally update
- monotonic O_raw total
- exact legal-set counter
- ordinal/idempotence metadata

clean close
→ durable CLEANLY_CLOSED

restart with prior OPEN
→ deterministic LEFT_UNCLEAN reconciliation
```

The design intentionally separates:

```text
INTEGRITY STATE
from
STUDY EVIDENCE STATE
```

The integrity store must not become the future common-support / Wilson / cross-run evidence database merely because SQLite exists.

## 73D.4 Authorized local facts

`GD-P1F01-INTEGRITY-001`, commit `e3a2745131901438c6baa36b4e6e6ca4b98db791`, authorizes only local integrity facts for the named Phase-1 measurement-integrity purpose:

```text
integrity version
local window sequence / generation
OPEN / CLEANLY_CLOSED / LEFT_UNCLEAN
monotonic admitted O_raw count
ordinal / legal-set idempotence metadata
exact legal-set counters
minimum closure / recovery metadata
```

Explicitly not authorized for this store:

```text
raw QEO history
question / answer payloads
identities
age
mastery
predictions
Scenario state
DecisionEpisode
CandidateEvaluation
timestamps unless separately proven necessary and authorized
device/ad identifiers
analytics / telemetry / cloud / remote backups
generic future fields
```

Full reset must delete the future integrity store. `Clear GameBrain Data` must also be wired/tested before release if this store is present. Deletion may never fabricate clean closure or gameplay outcomes.

## 73D.5 Current proof status

The design targets:

```text
G → COMPLETE_BY_DESIGN
F → EXACT IDEMPOTENCE
K_under → 0 design target
K_over → 0 design target
Divergence → NONE design target
```

These are **not yet implementation facts**. Production implementation and failure-injection/reopen validation must prove or revise them truthfully. If actual implementation yields a finite non-zero bound, the project must preserve that truth and apply the locked conservative-uncertainty rule rather than forcing zero.

---

# 73E. Approved Near-Term Gameplay Roadmap — 2026-08-22

The following player-facing sequence is approved as the near-term product roadmap after the current integrity implementation/readiness checkpoint. It is deliberately separate from the scientific Phase-1 `chooseDifficulty` path.

## 73E.1 TimingStyle foundation

Canonical run-level configuration:

```text
TimingStyle
- perQuestion
- untimed
- timeBank
```

The selected value is snapshotted at run start and immutable for the active run. Menu/config changes during a run apply to the next run.

## 73E.2 Deep Thinking / Untimed

Approved v1 behavior:

```text
same canonical question generation
same difficulty rules
same answer mechanics
no per-question countdown timeout
no speed-based scoring bonus where such a bonus depends on timed response
```

Deep Thinking is a gameplay feature, not a cognitive test and not a current GameBrain Decision Context.

## 73E.3 Time Bank

Before implementation, freeze `TIME_BANK_BUDGET_CONTRACT v1` covering:

```text
initial bank formula/value
question-count treatment
difficulty treatment
Adaptive treatment
bank exhaustion behavior
replay behavior
```

Time Bank then uses one shared run budget; it does not reset per question. Do not pre-generate questions merely to calculate the bank if that changes canonical RNG/question behavior.

## 73E.4 Mental Math Practice v1

Mental Math v1 is approved as one cohesive practice package, not four unrelated projects.

```text
MENTAL MATH PRACTICE v1

Entry points:
1. Free Practice
2. Daily Mental Math
3. Weak Skills Practice

Shared mechanic:
4. Targeted Repetition
```

Free Practice lets the player choose operation, difficulty, and length from the approved v1 sets. Daily Mental Math is a short ready-to-play daily session. Weak Skills Practice reuses the existing Weak Skills eligibility/ranking/focus-lock and canonical mastery data rather than creating duplicate progression. Targeted Repetition is deterministic within-session practice: missed or related material can reappear after intervening questions, with priority reduced after successful repetition; avoid immediate rote loops.

Approved content/configuration:

```text
Operations:
Addition / Subtraction / Multiplication / Division / Mixed

Difficulty:
Easy / Medium / Hard

Length:
10 / 20 / 30 questions

Results:
Correct / Incorrect
Accuracy
Best streak
```

The first Mental Math version should reuse existing canonical question generation/answer validation where practical. Written Answer, persistent Daily streak history, AI-generated practice, GameBrain-selected practice plans, and new long-term practice profiling are not automatically part of this v1 package. They require later bounded design decisions.

## 73E.5 Evidence firewall for new gameplay features

Until a future protocol explicitly expands Phase 1:

```text
Standard + perQuestion
→ only path potentially eligible for current P1-F01

Deep Thinking / untimed
→ OUTSIDE_PHASE1_ENVELOPE

Time Bank
→ OUTSIDE_PHASE1_ENVELOPE

Mental Math Practice
→ OUTSIDE_PHASE1_ENVELOPE
```

No new QEO timing field is introduced merely to accommodate these features. P1-F01 filtering occurs at the canonical opportunity boundary. Mental Math outcomes may later support a separate practice evidence/Decision Context, but they do not silently become current difficulty evidence.

## 73E.6 Product/science sequencing rule

The approved near-term sequence is:

```text
CURRENT:
P1-F01 minimum local integrity implementation
→ G/F/E + readiness re-check

THEN PRODUCT CHECKPOINT:
TimingStyle foundation
→ Deep Thinking / Untimed
→ Time Bank budget contract
→ Time Bank
→ Mental Math Practice v1

THEN RETURN TO SCIENCE TRACK:
bounded cross-run study evidence
→ final pre-window readiness
→ fresh P1-F01 confirmatory window
```

This sequence may be changed later by an explicit product decision, but until then it is the authoritative near-term roadmap.

---

# 74. Final target behavior

The mature GameBrain should eventually be able to reason like this:

```text
Player history:

Multiplication Medium
→ established

Hard
→ improving evidence

True/False
→ voluntarily selected frequently

20Q
→ late-run degradation candidate

Blitz
→ repeated timeout association

After isolated errors
→ usually continues

After repeated errors
→ exit association candidate

Assistance
→ decreasing over time
```

A canonical system opens:

```text
DecisionContext:
chooseDifficulty

Legal:
Easy
Medium
Hard
```

GEI evaluates:

```text
Easy:
well observed
likely lower challenge

Medium:
established
productive candidate

Hard:
adjacent frontier candidate
sparse / improving evidence
attribution limited
```

A versioned policy may separately produce:

```text
Preferred for normal play = Medium

Frontier exploration candidate = Hard
purpose = CAPABILITY_FRONTIER_EXPLORATION
status = still uncertain / not yet capability proof
```

Either output may still be rejected by Player Agency / Authority. Exploration never converts UNKNOWN into BAD and never forces continued exposure simply to obtain data.

Then:

```text
Stability gate
→ passed

Player Agency
→ no conflict

Authority
→ allowed

Canonical system
→ executes Medium
```

The result returns through truthful observations and a Decision Episode, updating evidence and future interpretation.

This is the intended loop:

```text
UNDERSTAND
↓
REMEMBER
↓
RECOGNIZE SCENARIOS
↓
MODEL
↓
EVALUATE
↓
DISTINGUISH PURPOSE
├─ normal personalization / exploit supported fit
├─ preserve UNKNOWN / abstain
├─ evidence exploration
└─ bounded capability-frontier exploration
↓
EXPLAIN
↓
PROPOSE
↓
PLAYER AGENCY + AUTHORITY
↓
CANONICAL EXECUTION
↓
OBSERVE RESULT + PURPOSE/PROVENANCE
↓
LEARN
↓
IMPROVE
↺
```

---

# 74A. Exploration-governance hardening — frozen amendments

The following refinements are now part of the Master Reference and must be preserved in future implementation/research design:

```text
AMENDMENT A — Typed exploration accounting
Global Exploration Ceiling
+ independent Evidence Exploration Budget
+ independent Capability Frontier Exploration Budget
+ non-fungible by default
+ any transfer requires versioned independent governance review
+ affected empirical protocols must be prospectively amended if exposure allocation changes

AMENDMENT B — Canonical candidate topology ownership
Canonical Decision Owner supplies LegalCandidates + CandidateTopology.
GameBrain never infers adjacency.
Canonical adjacency is structural only; it is not pedagogical fit or authorization.

AMENDMENT C — F11 measurement discipline
F11-P00 is required before R7 runtime authority.
R1 Reference/Control Track is the required comparison mechanism but is not automatically causal.
SHADOW starvation risk ≠ REALIZED starvation.
ASSOCIATED suppression ≠ ATTRIBUTABLE suppression.
Without a valid reference/counterfactual design, causal attribution is INCONCLUSIVE.

AMENDMENT D — Reference execution + allocation integrity
Reference live execution defaults to BLACKOUT.
Deferred Pure Shadow Replay may later recover calibration value only from a frozen EX-ANTE minimized snapshot under separate authority.
Reference allocation occurs upstream of GameBrain and outside GameBrain ownership.
Reference validity is claim-horizon / isolation-envelope specific, not a global boolean.

AMENDMENT E — Snapshot governance + replay sufficiency
DG-00-S1 is required before any real-player retained replay snapshot.
The snapshot follows replay sufficiency, not state completeness.
A synthetic/authorized shadow replay-equivalence precheck must pass before real-player retention begins.

AMENDMENT F — Reference evidence independence over time
Reference replay/calibration data that informs a later version becomes SEEN/DEVELOPMENT data for confirmatory claims about that version under GOV-2.
A versioned append-only Reference Window Usage Ledger is required; seen data cannot be relabeled untouched.
A fresh/untouched Reference window is required for later confirmatory adjudication where independence is claimed.
```

Governance complexity itself must remain operationally tractable. The Progress Review Template now checks whether one qualified reviewer can reconstruct active gates, owners, prerequisites, dependencies, status, blockers, and the next authorized task from the reference alone, and whether responsibilities have silently duplicated or conflicted.

Current priority decision:

```text
R1_F11_DESIGN_STATUS = FROZEN_FOR_FUTURE_PROTOCOLIZATION
P1-F00 v1.1 = LOCKED / HISTORICAL GOVERNED FOUNDATION
P1-F01 historical integrity/study foundation = RETAINED / NOT SILENTLY REWRITTEN

GB-PREVIEW-01 CROSS-SOURCE-SYNTHESIS-01 = PASS
PreviewObservationEvidenceV2 = APPROVED FOR OBSERVATION-SIDE FREEZE

EST ARCHITECTURE = RETAINED / FUTURE GOVERNED CAPABILITY
EST LEVEL-1 BUILDING BLOCKS = SUBSTANTIALLY ESTABLISHED / NOT PACKAGED AS REUSABLE EST MODULE
EST LEVELS 2–3 = NOT YET IMPLEMENTED AS EST
EST LEVEL-4 RELIABLE-CHANGE SUB-CAPABILITY = ATTEMPTED / NOT ESTABLISHED / PARKED
EST OTHER LEVEL-4 + LEVELS 5–6 = NOT YET IMPLEMENTED AS EST

GB-MEASURE-01F INPUT PACKAGE = v1.2 / FROZEN BY PROTOCOL OWNER
GB-MEASURE-01F PRE-EXEC REVIEW = PASS / APPROVED_FOR_01F_EXEC
GB-MEASURE-01F-EXEC = COMPLETE
01F ORACLE = COMPLETE / S01-S09
01F SCREENING = COMPLETE / 49 designs × 9 scenarios
01F SCREENING SURVIVORS = 0 / 49
01F OUTCOME = NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID
01F INDEPENDENT OUTCOME VERIFICATION = PASS
01F CONFIRMATORY = NOT ENTERED BY FROZEN PROTOCOL
01F SENSITIVITY/FNR = NOT ENTERED BY FROZEN PROTOCOL

RELIABLE MEASURED-CHANGE CAPABILITY = NOT ESTABLISHED IN CURRENT VERSION
ValidatedChangeReceipt = NOT FROZEN / UNAVAILABLE
GB-MEASURE-01 CURRENT BOUNDED ATTEMPT = CLOSED / PARKED
01G / S09 RECOVERY / LARGER GRID / THRESHOLD RETUNING = NOT OPENED

POST-01F OWNER DISPOSITION = RETURN_TO_SIMPLIFY
CURRENT AUTHORIZED TASK = GB-PREVIEW-01-SIMPLIFY-01 — Minimal Interpreter Vertical Slice

Time Bank = IMPLEMENTED / VALIDATED PRODUCT FEATURE
Mental Math user-facing direction = IQ Spark / Training Arena, with governed legacy internals retained
mayAffectGameplay = false for GB-PREVIEW / GB-MEASURE work
```

Do not deepen R1/F11 merely because unanswered future parameters exist. Do not expand GameBrain into timing/round-length/practice decisioning before the Phase-1 expansion gates. The approved product features may be implemented as canonical gameplay without becoming GameBrain Decision Contexts or P1-F01 evidence. Re-open the R1/F11 package only when the actual Phase-1 shadow evaluator/policy/DecisionEpisode stack makes those parameters empirically specifiable.

---


# 74B. GB-PREVIEW-01 → GB-MEASURE-01 scientific interpretation/measurement track — R5

This section records the governed scientific path developed after R4. It does not supersede earlier Phase-1/P1-F01 evidence governance; it adds a separate bounded measurement foundation required before GameBrain can legitimately distinguish a raw recent increase from a reliable measured-performance increase.

## 74B.1 GB-PREVIEW-01 research disposition

`GB-PREVIEW-01` remains deterministic, synthetic, shadow-only, non-production, and non-authoritative:

```text
mayAffectGameplay = false
real player data = prohibited for preview
production capture = OFF / NOT AUTHORIZED
ruleset = NOT DEFINED
implementation authorization = NOT AUTHORIZED
```

The frozen scenario vocabulary remains:

```text
ProductiveChallengeCandidate
OverchallengeCandidate
UnderchallengeCandidate
RecentImprovementCandidate

Cross-cutting:
SparseEvidence
ConflictingEvidence
```

The research synthesis concluded:

```text
Productive Challenge      = NOT SUPPORTED UNDER CURRENT PreviewEvidence CONTRACT
Overchallenge             = NOT IDENTIFIABLE under current contract
Underchallenge            = NOT IDENTIFIABLE under current contract
Observed recent change    = REPRESENTABLE
Reliable learning change  = NOT REPRESENTABLE under current raw evidence alone
Sparse-evidence abstention = SUPPORTED structurally; no universal minimum-N threshold
Qualitative uncertainty   = SUPPORTED
Scenario precedence       = NOT SUPPORTED / must not be invented

PRIMARY DISPOSITION = REFINE_CONTRACT
ALTERNATIVE = SIMPLIFY
MORE_OF_THE_SAME_DATA_ONLY = INSUFFICIENT
```

Permanent construct firewall:

```text
accuracy                      != productive struggle
timeout count                 != cognitive load
categorical synthetic latency != frustration
segment difference            != durable learning
```

## 74B.2 Observation-side contract refinement

The observation-side refinement is approved for freeze as a successor design, while GB-PREVIEW-01 v1.0 remains historical/frozen and is not silently mutated.

Conceptual direction:

```text
PreviewObservationEvidenceV2
├─ bounded aggregate observables
├─ explicit EvidenceSlot semantics: PRESENT / ABSENT / MISSING
├─ factual SemanticContextEvidence
├─ explicit TemporalComparisonObservation
├─ bounded comparator observations
├─ bounded process observations
├─ bounded follow-on outcome observations
└─ opaque integrity-binding tokens
```

Core epistemic rules:

```text
canonical difficulty relation != learner-relative task demand
historical match               != validated comparability
continued after error          != motivation / trait persistence
later same-fact outcome        != learning / transfer
raw observation                != measurement-validation receipt
```

The final interpreter-boundary envelope remains intentionally incomplete until the measurement-side receipt semantics are scientifically defined.

## 74B.3 GB-MEASURE-01 target claim

`GB-MEASURE-01 — Bounded Reliable-Change Measurement Foundation` has one bounded target claim:

> **Reliable improvement in bounded measured performance under one frozen MeasurementSpec.**

It does **not** authorize claims of:

```text
durable learning
mastery
mathematical ability
motivation
cognitive load
productive struggle
diagnosis
gameplay recommendation
```

The first measurement cell is:

```text
GBM01-CELL-01
Operation             = Multiplication
NumberType            = Natural
ExecutedDifficulty    = Medium
DifficultyProvenance  = playerConfigured
Mode                   = Standard / 1P
Timing                 = Per Question
AnswerStyle            = Choice4
Assistance             = None
ExposureOrigin         = Natural
Adaptive               = OFF
Targeted Repetition    = EXCLUDED
Replay-derived         = EXCLUDED
```

The methodological direction selected for the first foundation is a bounded alternate-form calibration framework with Generalizability-Theory / variance-component-based error modeling. Classical RCI is treated as a methodological reference/downstream structural candidate, not copied directly as a project rule; KR-20/alpha and simple alternate-form correlation are supporting diagnostics only; IRT/Rasch remains a possible later scale-up path.

## 74B.4 GB-MEASURE-01F recovery and execution-input freeze

The original `GB-MEASURE-01F-EXEC` attempt correctly stopped when no repository-governed 01A–01F inputs were available. A prospective input-freeze recovery package was then created before any simulation output was seen.

### v1.0

The first independent review returned `REQUIRED_CHANGES / MISSING_FROZEN_INPUT`. The package already contained the measurement cell, candidate form structure, 49-design grid, binary DGM, S01–S09 scenarios, calibration estimators, reliable-change criterion, Monte Carlo replication counts, acceptance tolerances, minimum-design ordering, output inventory, and fail-closed governance; however, execution-critical semantics remained incomplete.

### R1 / v1.1

R1 prospectively fixed:

```text
RC-1 = independent decision-pair population + D_observed semantics
RC-2 = calibration-estimation uncertainty in V_adj,
       including Cov(F_hat, P_hat)
```

The independent R1 re-review accepted those two corrections and identified two remaining gaps rather than allowing execution.

### R2 / v1.2

R2 prospectively fixed:

```text
RC-3 = complete-data-only simulation scope
       missingness/censoring excluded from v1.2
       malformed/incomplete replicate fails closed and remains in denominators

RC-4 = exact executable reproducibility contract
       CPython 3.13.5
       NumPy 2.3.5
       PCG64DXSM
       Generator.normal
       Generator.binomial
       canonical tokens / component labels / sub-seed hashing / draw ordering
       exact-version fail closed
       component streams independent of scheduling order
```

Authoritative R2 pair:

```text
gb_measure_01f_input_freeze_recovery_r2.md
gb_measure_01f_exec_manifest_v1_2.json
SHA-256(manifest)
= 918ba80bccadea4f45807c6c3329c54389a769e1f15c0d39d3e6672a5af5d79e
```

The fresh independent R2 pre-execution review returned:

```text
PASS / APPROVED_FOR_01F_EXEC
```

and the protocol owner then explicitly approved:

```text
START GB-MEASURE-01F-EXEC
```

No Monte Carlo output is incorporated in this R5 reference yet.

## 74B.5 Frozen 01F-EXEC design essentials

```text
Candidate forms:
GBM01-FORM-A-v1
GBM01-FORM-B-v1
18 items/form = 6 direct + 6 missing-left + 6 missing-right
exact A/B canonical item overlap = 0
parallel-form claim = NOT AUTHORIZED before empirical validation

Stage 1:
randomized form-equivalence
A:B = 1:1
n/form grid = 50,75,100,150,200,300,400

Stage 2:
counterbalanced alternate-form retest
AB:BA = 1:1
n/order grid = 25,40,50,75,100,150,200

candidate designs = 49

R_oracle  = 1,000,000
R_screen  = 3,000
R_confirm = 20,000

core scenarios = S01–S08
misspecification sentinel = S09
sensitivity shifts = -0.50, -0.25, +0.25, +0.50 logit
```

The binary simulation model is a project-local sensitivity DGM, not an empirical claim that real Math Challenge responses are iid Bernoulli observations.

Frozen acceptance/adjudication principles include:

```text
false-positive tolerance = .060
indeterminate / numerical-failure tolerance = .050
signed SE_change bias band = ±.050
mean absolute SE_change error tolerance = .100
normalized form/practice bias tolerances = .100
S09 calibration-pass ceiling = .200
worst-case = every gating metric must pass; no averaging
no pass = NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID
```

These numeric values are project-local preregistered simulation choices, not universal psychometric constants.

## 74B.6 R5.1 execution outcome, closure, and current task

The previously authorized `GB-MEASURE-01F-EXEC` has now been executed and independently outcome-verified.

```text
GB-PREVIEW-01 synthesis                     = PASS
REFINE_CONTRACT observation-side work       = CLOSED / APPROVED FOR FREEZE
GB-MEASURE-01F input package                = v1.2 FROZEN BY PROTOCOL OWNER
fresh independent pre-exec review           = PASS / APPROVED_FOR_01F_EXEC
protocol-owner execution approval           = YES

runtime                                     = CPython 3.13.5
NumPy                                       = 2.3.5
PRNG                                        = PCG64DXSM
manifest SHA-256                            = 918ba80bccadea4f45807c6c3329c54389a769e1f15c0d39d3e6672a5af5d79e

oracle                                      = COMPLETE / S01-S09
screening                                   = COMPLETE / 49 × 9 cells
screening survivors                         = 0 / 49
confirmatory                                = NOT ENTERED BY FROZEN PROTOCOL
sensitivity / FNR                           = NOT ENTERED BY FROZEN PROTOCOL

scientific adjudication
= NO_ADMISSIBLE_DESIGN_IN_FROZEN_GRID

fresh independent outcome verification
= PASS
```

The no-survivor outcome is not a runtime failure. It is the exact preregistered no-pass result for the frozen grid. Independent recomputation confirmed all 441 screening cells and all 49 design exclusions. The decisive S09 calibration-pass sentinel failed for every design by a wide margin; therefore the zero-survivor conclusion does not depend on a borderline threshold or rounding decision.

The current bounded reliable-change attempt is closed at this result:

```text
Reliable measured-change capability
= NOT ESTABLISHED IN CURRENT VERSION

ValidatedChangeReceipt
= NOT FROZEN / UNAVAILABLE

GB-MEASURE-01 current bounded attempt
= CLOSED / PARKED
```

The project will **not** open a new `01G`, S09 recovery program, larger post-result N grid, threshold relaxation, seed change, or automatic calibration redesign merely to obtain a passing result. Any future return to reliable-change measurement requires a new explicit product/scientific dependency and a prospective new protocol.

This result does not block all GameBrain progress. It blocks only claims that require a validated reliable-change receipt. Raw factual observations, explicit missingness, context-conditioned evidence, contradiction, uncertainty, and abstention remain usable inside the non-authoritative preview contract.

Current task:

```text
GB-PREVIEW-01-SIMPLIFY-01
= Minimal Interpreter Vertical Slice
```

Bounded task scope:

```text
Input:
PreviewObservationEvidenceV2 observation-side facts only

Reliable-change receipt:
UNAVAILABLE / must not be fabricated

Required behaviors:
- preserve PRESENT / ABSENT / MISSING semantics
- preserve factual context
- preserve factual temporal comparison as observation only
- SparseEvidence handling
- ConflictingEvidence handling
- contradiction preservation
- explicit abstention / NOT_EVALUABLE / INSUFFICIENT where required
- structured explanation
- compare behavior with a simple accuracy-threshold heuristic baseline

Not authorized:
- claim reliable improvement from raw segment difference
- claim durable learning / mastery / ability
- silently promote ProductiveChallenge / Overchallenge / Underchallenge
  when their measurement requirements are unmet
- real-player preview data
- production capture
- Player Experience Model persistence
- policy activation
- gameplay influence
```

This is a deliberate return to the previously available `SIMPLIFY` disposition, not a new measurement-recovery branch.

## 74B.7 Permanent measurement/authority firewall

```text
OBSERVED RECENT INCREASE
!= RELIABLE MEASURED-PERFORMANCE INCREASE

RELIABLE MEASURED-PERFORMANCE INCREASE
!= DURABLE LEARNING
!= MASTERY
!= ABILITY

SCIENTIFIC CALIBRATION
!= GAMEBRAIN INTERPRETATION AUTHORITY

VALIDATED CHANGE RECEIPT
!= GAMEPLAY AUTHORITY

GAMEBRAIN
!= MEASUREMENT AUTHORITY
!= CANONICAL EXECUTION AUTHORITY
```

`mayAffectGameplay = false` remains binding throughout this scientific track unless a later separate authority gate explicitly changes it.

---

## 74B.8 Current-path supersession and anti-drift rule

To prevent the project from drifting between historical checkpoints:

```text
R5.19 (2026-09-01)
= historical P1-SE-EVAL / R1D-R2 checkpoint
= retained for lineage
= NOT the current next-task authority

R5 (2026-09-04 pre-exec)
= historical pre-01F checkpoint
= retained for 01F frozen-input lineage

R5.1 (2026-09-04 post-exec)
= historical post-01F checkpoint before EST restoration

R5.2 (2026-09-04 post-exec + EST restoration)
= CURRENT task/status authority
```

Do not return to `R1D-R2` merely because an older roadmap named it as next. Do not continue `GB-MEASURE-01` merely because the pre-execution R5 named `01F-EXEC` as current. The current single next task is `GB-PREVIEW-01-SIMPLIFY-01`.

EST remains on the architecture map but is **not** the current task. Do not mistake restoration of the EST architecture for authorization to implement Levels 2–6 now. Re-open a specific EST capability only when a concrete interpreter/scenario/product question requires it.

Permanent anti-drift rule:

```text
a closed failed bounded research attempt
→ preserve the limitation
→ do not automatically create another research program

a missing capability becomes a blocker
only when a concrete downstream product/intelligence claim actually requires it
```

---

# 75. Highest-level permanent rule

> **GameBrain is not built to classify the child or trap the player inside a profile it created. It is built to understand the player’s changing gameplay experience, improve the next experience, and—when separately justified and authorized—create bounded opportunities for the player to exceed the model’s current expectations. Evidence must remain auditable, uncertainty-aware, counterfactual-disciplined, attribution-limited, privacy-governed, player-agency constrained, and subordinate to canonical game authority.**

---

# 76. Progress review template

Use this at every milestone:

```text
Milestone:
Baseline:
Outcome:

Architecture status:
Measurement validity status:
Decision validity status:
Operational safety status:
Privacy/data-governance status:
Governance tractability status:

Can one qualified milestone reviewer reconstruct from this reference alone:
- every currently active gate and protocol version?
- each owner / reviewer / adjudicator role where applicable?
- prerequisites and downstream dependencies?
- current status and what each gate blocks?
- the single next authorized task?

Do any active gates duplicate responsibility or create contradictory authority?
If tractability is insufficient, record GOVERNANCE_TRACTABILITY_DEBT and consolidate/document before adding hidden assumptions. This is a progress-control warning, not a new scientific gate.

If Reference/Control research is active:
- is the allocation protocol/version explicit and upstream of GameBrain?
- is live Reference execution BLACKOUT unless a separately reviewed variant says otherwise?
- is snapshot retention covered by DG-00-S1 and replay-sufficiency validation?
- is Reference Integrity valid for the specific claim horizon?
- has any Reference window become SEEN/DEVELOPMENT data?
- does the append-only usage ledger preserve that status?
- is a fresh/untouched window required before confirmatory adjudication?

What became MET/implemented:
What remains design-only:
What remains unvalidated:
What remains unauthorized:

New debt/blockers:
Protocol/version changes:
Independent review/adjudication:
Product-priority review:

NEXT_AUTHORIZED_GEI_TASK:
```
