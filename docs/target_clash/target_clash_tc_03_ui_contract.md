# Target Clash TC-03 — UI / Presentation Contract

Status: **FROZEN / OWNER APPROVED**

Date: **2026-09-25**

Baseline:

```text
main
8be2e844e5349a9dfa83ce808b53f260a99dcc62
```

Implementation branch:

```text
feature/target-clash-tc03-ui-presentation
```

TC-00, TC-01, TC-02A, TC-02B, TC-02C, and TC-02D remain authoritative.
TC-03 must not reinterpret or expand their gameplay semantics.

---

## 1. Slice boundary

TC-03 owns:

```text
production menu entry
Number Type → Config → Player Setup flow
Target Clash configuration presentation
Target Clash gameplay presentation
relation-answer controls
Clash Reveal
Target Clash HUD
Power Shot player-facing activation
Triple / Fever / Boss / Final presentation
safe temporary terminal presentation
```

TC-03 does not own:

```text
full Target Clash results metrics
Replay UI
Target Clash persistence
High Score / Hall of Fame
achievements
coins / economy
cloud progress
GameBrain evidence
GameBrain personalization
P1 evidence
new gameplay tuning
new Target Clash mechanics
```

Full results and Replay remain TC-04.

Final visual/accessibility parity closure remains TC-05.

---

## 2. Identity

Target Clash remains:

```text
GameRunType.targetClash
```

Target Clash does not add:

```text
GameMode
AnswerStyle
PowerUp enum value
persistence schema
cloud schema
```

`GameMode.standard` remains only the existing orchestration carrier and must not grant ordinary Standard behavior.

---

## 3. Production flow

Target Clash preserves the normal Math Challenge product flow:

```text
Menu
→ Number Type
→ Config
→ Player Setup
→ Gameplay
```

No dedicated parallel setup application or alternate navigation stack is added.

---

## 4. Main-menu entry

Add one Target Clash challenge entry under the existing CHALLENGES section.

Player-facing identity:

```text
🎯 Target Clash
Compare • Aim • Strike
```

The card must follow existing Math Challenge cards, colors, typography, spacing, navigation, and animation conventions.

---

## 5. Number Type

Target Clash V1 supports:

```text
Natural
Integers
Rationals
```

Target Clash V1 does not support:

```text
Mixed Number Type
```

Unavailable configuration must fail closed.

Where the existing UI safely permits it:

```text
VISIBLE-BUT-DISABLED > HIDDEN
```

---

## 6. Target Clash configuration

The Target Clash configuration authority remains `TargetClashRunConfig`.

The player selects exactly one operation:

```text
Addition
Subtraction
Multiplication
Division
```

Unsupported:

```text
Mixed Operations
Missing Operation
Master
Daily Boss
Survival
future special operations
```

Players:

```text
1 Player     ENABLED
2 Players    VISIBLE / DISABLED
```

Game Mode:

```text
Standard     ENABLED as carrier only
Blitz        VISIBLE / DISABLED
Death        VISIBLE / DISABLED
Combo        VISIBLE / DISABLED
Survival     VISIBLE / DISABLED
```

Difficulty:

```text
Easy
Medium
Hard
```

Fixed Target Clash answer presentation:

```text
<   =   >
```

The ordinary Answer Style selector must not control Target Clash.

No new `AnswerStyle` value is added.

Question count is runtime-derived and not player-selectable:

```text
Easy       12
Medium     16
Hard       17
```

The Target Clash phase machine remains terminal authority.

The ordinary Standard turn limit remains non-authoritative.

Timing:

```text
Per Question     ENABLED
Deep Thinking    DISABLED
Time Bank        DISABLED
```

Adaptive:

```text
OFF / DISABLED
```

TC-03 adds no Target Clash setup persistence.

---

## 7. GameScreen dispatch

Target Clash receives a dedicated presentation branch before ordinary gameplay widgets are constructed.

Conceptually:

```dart
if (gs.isTargetClash) {
  return TargetClashGameplay(...);
}
```

Preferred presentation location:

```text
lib/features/target_clash/presentation/
```

The UI reads canonical Target Clash truth from `GameState`.

The UI must not duplicate gameplay authority.

---

## 8. Unanswered mathematical prompt

The unanswered layout is:

```text
TARGET 15

8 + 9

[ < ]   [ = ]   [ > ]
```

The global answer order is fixed:

```text
lessThan
equalTo
greaterThan
```

The unanswered prompt must never expose `ExpressionValue`.

Forbidden unanswered example:

```text
8 + 9 = 17
```

The expression must be rendered from typed `MathFact` fields.

Display strings must never be parsed to derive:

```text
correctness
expression value
operation
target
relation
zone
```

---

## 9. Relation controls

The only gameplay answers are:

```text
<     =     >
```

They dispatch typed:

```text
PresentationAnswer.lessThan
PresentationAnswer.equalTo
PresentationAnswer.greaterThan
```

through:

```text
GameState.onTargetClashAnswer(...)
```

Semantic labels should include:

```text
Less than target
Equal to target
Greater than target
```

Existing minimum tap-target conventions must be retained.

Correctness must never be implemented in the widget layer.

---

## 10. Clash Reveal

After every resolved Target Clash question, including:

```text
correct answer
wrong answer
timeout
```

the active question is terminal and input/timer are frozen.

Clash Reveal duration is exactly:

```text
1300 ms
```

Example:

```text
8 + 9 = 17
17 > 15
```

Perfect Hit example:

```text
7 × 5 = 35
35 = 35
PERFECT HIT
```

Wrong answers still reveal the mathematically correct relation.

The unanswered mathematical card must remain uncluttered.

Perfect / Triple / Boss / Fever feedback appears around the prompt, not inside the unanswered prompt.

During reveal:

```text
relation input disabled
previous question cannot resolve twice
next question timer not started
stale callbacks remain rejected
```

After reveal:

```text
open next scheduled Target Clash question
start its canonical per-question timer
```

The existing question-token/cancellation lifecycle remains authoritative.

---

## 11. HUD

The Target Clash HUD may display only canonical runtime truth already owned by the Target Clash runtime.

Core HUD:

```text
Score
Combo
Combo multiplier
Clash Power
current ladder phase
stage/question progress
```

Clash Power presentation:

```text
0 / 6
...
6 / 6 READY
```

No HUD field creates gameplay truth.

---

## 12. Ladder / phase presentation

Presentation may identify the current phase as:

```text
TARGET STREAK
TRIPLE CLASH
BOSS TARGET
FINAL TARGET
```

Canonical phase authority remains:

```text
TargetClashRuntimeState.phase
```

---

## 13. Triple Clash

Triple Clash uses the existing prepared runtime sequence.

UI may show bounded progress:

```text
TRIPLE CLASH
1 / 3
2 / 3
3 / 3
```

`TRIPLE CLASH COMPLETE` may appear only when the runtime's frozen completion condition is actually satisfied.

Reaching the final Triple slot alone must not create a completion claim.

Triple feedback must not use scientific, ability, intelligence, or mastery language.

---

## 14. Fever Mode

Fever is Hard-only under the frozen V1 runtime rules.

During active Fever the UI may display:

```text
FEVER
×2
remaining slots
```

Fever presentation must not alter:

```text
relation meaning
relation button order
mathematical correctness
target
question count
```

The runtime remains sole authority for Fever duration and score multiplier.

---

## 15. Boss Target

Boss presentation uses the same Expression-vs-Target mechanic and the same relation buttons.

Boss UI may display:

```text
BOSS TARGET
Boss Health
questions resolved / cap
```

Correct answers damage the Boss according to frozen runtime rules.

A Perfect Hit during Boss may receive enhanced Bullseye Critical Hit feedback.

The UI must not compute Boss damage independently.

---

## 16. Final Target

Final Target uses:

```text
Expression vs numeric Target
< = >
```

with no new answer mechanic.

UI may display:

```text
FINAL TARGET
question progress
```

Completion and clear semantics remain runtime-owned:

```text
Final Target Completed
= all three Final questions resolved

Final Target Cleared
= at least two correct
```

TC-03 does not create the full results screen for these metrics.

---

## 17. Clash Power / Power Shot UI

Clash Power is visible runtime state.

Full charge:

```text
clashPower == 6
```

means:

```text
POWER SHOT READY
```

Readiness and application are distinct states.

Power Shot is:

```text
manual
between open questions
outside Triple Clash
applied to one eligible scheduled next slot
same fixed Target
same < = > interface
Danger requested first
Close Call fallback
no inserted question
no run-count increase
```

A narrow `GameState` owner seam may be added for UI activation, conceptually:

```dart
activateTargetClashPowerShot()
```

That seam must delegate to the existing canonical:

```dart
TargetClashRuntimeState.activatePowerShot(...)
```

The widget layer must not reimplement:

```text
eligibility
charge consumption
zone replacement
fallback generation
Power Shot scoring
```

If application is denied or unavailable, the runtime result remains canonical.

No ordinary `PowerUp` value is reused.

---

## 18. Existing ordinary Power Ups

All existing ordinary power-ups remain blocked for Target Clash:

```text
Time
50/50
Double
Shield
Freeze
Swap operation
```

The ordinary gameplay Power-Up HUD must not be shown for Target Clash.

Power Shot is a Target Clash mechanic, not an ordinary PowerUp.

---

## 19. Feedback and accessibility

Target Clash feedback must preserve the existing Math Challenge visual language.

Feedback must use more than color alone where meaning is important.

The reveal must remain readable with reduced motion enabled.

Existing audio/haptic feedback conventions may be reused.

TC-03 adds no new audio contract.

Final visual/accessibility parity adjudication remains TC-05.

---

## 20. Successful terminal bridge

Full Target Clash results belong to TC-04.

Until TC-04, a successfully finished TC-03 run may use a bounded temporary terminal presentation:

```text
TARGET CLASH COMPLETE

[ BACK TO MENU ]
```

It must not create or display unsupported persistent result semantics.

TC-03 must not add:

```text
Hall of Fame
High Score
coins
achievement progress
cloud progress
persistent Target Clash statistics
Replay UI
```

The completed-game ad cadence remains allowed only after a genuinely finished Target Clash run, as frozen in TC-02.

---

## 21. Technical failure bridge

For:

```text
TargetClashPhase.technicalFailure
```

show a neutral safe terminal presentation such as:

```text
Target Clash couldn't continue safely.

[ BACK TO MENU ]
```

Technical failure:

```text
is not successful completion
does not show a completion claim
does not increment completed-game ad cadence
does not grant rewards
does not persist Target Clash progress
```

No fallback ordinary Question is shown.

---

## 22. GameBrain / service firewall

Target Clash remains outside GameBrain evidence and authority.

TC-03 must preserve:

```text
GameBrain instance observation     NONE
QuestionExperienceObservation     NONE
ContextEvidenceObservation        NONE
P1 study admission                NONE
P1 record                         NONE
Adaptive shadow call              NONE
skill/mastery update              NONE
learner-model update              NONE
recommendation                    NONE
chooseDifficulty authority        NONE
achievement mutation              NONE
coin/economy mutation             NONE
shop mutation                     NONE
cloud mutation                    NONE
High Score                        NONE
Hall of Fame                      NONE
```

Allowed only:

```text
canonical Target Clash per-question timer
completed-game ad cadence after finished only
```

All firewalls must gate before calls occur.

---

## 23. Backward compatibility

TC-03 must preserve existing behavior for:

```text
Normal Standard
Blitz
Death
Combo
Survival
Master
Daily Boss
Operation Quest
IQ Spark / Mental Math
Training Arena / Weak Skills internal flow
2-player ordinary gameplay
Deep Thinking
Time Bank
existing saves
existing cloud state
existing achievements/economy
existing GameBrain behavior
```

No existing mode may acquire Target Clash relation semantics.

---

## 24. TC-03 required proof

Before TC-03 may be committed, prove production flow:

```text
Menu
→ Number Type
→ Config
→ Player Setup
→ Target Clash gameplay
```

Across:

```text
Addition
Subtraction
Multiplication
Division

Natural
Integers
Rationals

Easy
Medium
Hard
```

Configuration proof:

```text
one player only
ordinary modes unavailable
Adaptive OFF
Per Question only
derived 12 / 16 / 17 counts
ordinary AnswerStyle does not control Target Clash
Mixed Number Type rejected
unsupported operations rejected
```

Gameplay proof:

```text
< = > global order
typed PresentationAnswer dispatch
ExpressionValue hidden before answer
typed MathFact rendering
1300 ms Clash Reveal
correct reveal
wrong-answer correct-relation reveal
timeout reveal
input locked during reveal
no duplicate resolution
next timer begins after reveal only
stale timer callbacks rejected
```

Power Shot proof:

```text
visible Clash Power
READY at 6
manual activation
application
denied state
unavailable state
blocked during Triple
ordinary Power-Up HUD absent
```

Phase proof:

```text
Target Streak presentation
Triple presentation
Triple completion claim only when canonical
Hard Fever presentation
Boss presentation
Final Target presentation
successful temporary terminal bridge
technical-failure safe terminal bridge
```

Firewall proof:

```text
no ordinary answer path
no ordinary power-up path
no ordinary score path
no GameBrain/P1 path
no skill/mastery path
no persistence/economy/cloud path
finished-only completed-game ad cadence retained
```

Regression proof:

```text
focused TC-03 tests PASS
retained Target Clash tests PASS
full non-golden tests PASS
flutter analyze PASS
git diff --check PASS
```

No broad golden refresh is authorized in TC-03.

Final visual/accessibility parity closure remains TC-05.

---

## 25. Scope-creep firewall

Any new Target Clash mechanic not already frozen by TC-00/01/02 or this owner-approved TC-03 contract goes to the future backlog.

TC-03 must not silently introduce:

```text
new scoring rules
new target zones
new difficulty
new Boss rules
new Fever trigger
new Triple rule
new Power Shot rule
new persistence
new rewards
new GameBrain semantics
```

---

## 26. Exit condition

TC-03 closes only when:

```text
production entry works
configuration is fail-closed
relation gameplay UI works
Clash Reveal is correct
Power Shot is safely player-facing
phase presentation is correct
technical failure is safely represented
all TC-02 firewalls remain intact
focused + regression + analyzer gates pass
independent source review passes
```

Then:

```text
TC-04
= Results metrics + Replay integration + service/persistence compatibility
```

Later:

```text
TC-05
= final visual/accessibility parity + full regression closure
```
---

## 27. Independent-review lifecycle clarifications

These clarifications resolve TC-03 implementation ambiguity without changing TC-00/TC-02 gameplay semantics.

### Fixed carrier controls are not player choices

For Target Clash V1, `players == 1`, `mode == GameMode.standard`, `timingStyle == TimingStyle.perQuestion`, and Adaptive OFF are fixed carrier/profile facts. The shared Config UI may render corresponding controls as locked/disabled when necessary, but must not present them as Target Clash gameplay choices or allow them to mutate Target Clash configuration. The actual player-selected Target Clash configuration remains concrete operation, Easy/Medium/Hard difficulty, and Natural/Integers/Rationals number type.

### Clash Reveal owns an inter-question hold

Every resolved Target Clash question is resolved exactly once in `GameState`, then receives the full 1300 ms Clash Reveal before the next question becomes accepting or its timer starts. `GameState` must retain immutable presentation data for the just-resolved question so the reveal never reads expression/value/relation data from an already-advanced `runtime.currentQuestion`.

If a resolution transitions the runtime to `finished` or to a later-stage `technicalFailure`, the just-resolved question still receives its full reveal before the success/failure terminal bridge. An initial generation failure before any question is presented has no reveal requirement. A genuine finished run remains the only Target Clash path eligible for completed-game ad cadence.

### Power Shot activation seam is mandatory and inter-question only

TC-03 must add a narrow `GameState`-owned player-facing Power Shot activation seam. UI code must not call `TargetClashRuntimeState.activatePowerShot(...)` directly. Activation is valid only after the prior question is terminal and before the next eligible scheduled slot becomes accepting/timed; it is invalid during an open accepting relation question and remains denied throughout Triple Clash.

### TC-04 Results boundary remains intact

The complete product flow remains `Menu → Number Type → Config → Player Setup → Gameplay → Results`. TC-03 implements production entry through gameplay only; the bounded TC-03 terminal bridge is temporary until TC-04 supplies Results/replay integration.
