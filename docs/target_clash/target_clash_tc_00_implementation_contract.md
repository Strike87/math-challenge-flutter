# TC-00 — Target Clash implementation contract

## Status and authority

This is a design-and-source-audit contract for the frozen `Expression ? numeric Target` V1 concept in roadmap section 62.3. It authorizes no production implementation. Target Clash product data is not GameBrain evidence and has no learner-model, mastery, recommendation, `chooseDifficulty`, policy, or Canonical Fact Center authority.

## 1. Source audit and integration decision

| Current seam | Source finding | TC decision |
| --- | --- | --- |
| Modes | `GameMode` is the global ordinary-rule/timer enum (`standard`, `blitz`, `death`, `survival`, `combo`) in `lib/models/enums.dart`. | Do **not** add a `GameMode`; Target Clash is not an ordinary timer/mode variant. |
| Run identity | `GameRunSnapshot` in `lib/engine/game_state.dart` carries immutable run configuration and is retained for replay. It already distinguishes `GameRunType.normal` and `operationQuest`. | Add `GameRunType.targetClash` in the later integration slice, with `mode: GameMode.standard` only as the existing orchestration carrier. |
| Owner | `GameState` owns runtime mutation, timers, navigation, persistence, ads, scoring and result preparation. | `GameState` remains the canonical owner of the active Target Clash snapshot and runtime progression; a pure Target Clash domain owns only arithmetic classification/generation requests. |
| Question math | `QuestionGenerator.build` creates legal canonical `Question`s; `Question.ans` is the evaluated numeric result and `Question.fact` preserves fact provenance. | Reuse it. Never parse `Question.text` to calculate correctness. |
| Existing special runs | Operation Quest supplies a dedicated snapshot; Mental Math uses a normal snapshot with dedicated entry/profile fields. | Neither is a template: Target Clash needs an explicit run type because it has finite ladder state, target state, and a different answer semantic. |
| Flow/UI | `MenuScreen → NumTypeScreen → ConfigScreen → PlayerSetupScreen → GameScreen`; `main.dart` routes these screens. | Add one Target Clash menu entry later, then reuse this path. V1 configuration is Easy/Medium/Hard and one player; Player Setup remains in the path. |
| Results/replay | `_prepareResultSummary` and `replayGame` read `_runSnapshot`; replay carries configuration and generates a fresh run. | A Target Clash result branch reads its runtime summary; replay carries the Target Clash snapshot and regenerates Targets/questions. |
| Timing | Per-question, untimed, and time-bank are normalized by snapshot eligibility. | V1 fixes `TimingStyle.perQuestion`; it reuses the canonical question timer and adds no timer engine. |
| Services | End-game logic records ad cadence; Hall of Fame serializes `HighScore` with `GameMode`; cloud progress serializes high scores, achievements, skills and economy. | No Target-Clash-specific economy, ad, cloud, achievement, or score persistence in V1. |

**Chosen architecture: B — a separate challenge identity outside `GameMode`.** `GameRunType.targetClash` is the identity; its snapshot receives a typed `TargetClashRunConfig` in the later integration slice. The config contains difficulty, number type, fixed V1 ladder profile, and no adaptive flag. Normal runs remain unchanged because their snapshots retain `GameRunType.normal`.

### Standard-carrier firewall

`GameRunType.targetClash + GameMode.standard !=` an ordinary Standard run. `GameMode.standard` is only the existing orchestration carrier for Target Clash; it does not grant Target Clash any Standard-only behavior. Default deny every ordinary Standard behavior unless this contract explicitly audits and allowlists it.

V1 allows only canonical per-question timer behavior and the existing completed-game ad cadence at end game. Target Clash does **not** inherit ordinary `AnswerStyle` semantics, Adaptive, existing power-ups, follow-up mechanics, ordinary Standard scoring, Hall of Fame/HighScore, skill/mastery updates, achievements/economy rewards unless separately authorized, or GameBrain evidence/advisory paths.

Old stored `HighScore` JSON uses the current `GameMode.fromString` fallback and has no Target Clash identity; V1 therefore excludes Target Clash from Hall of Fame instead of overloading `GameMode.standard`. Active run snapshots are not persisted. Any future persisted Target Clash payload must be versioned, decode only known values, and fail closed to “discard this inactive Target Clash run and return to menu”; it must never reinterpret it as a normal run.

## 2. Domain and generation contract

TC-01 introduces a pure companion, not an extension or replacement of `Question`:

```text
TargetClashQuestion
  expression: MathFact                 // canonical direct expression and provenance
  expressionValue: num = expression.result
  targetValue: num
  correctAnswer: PresentationAnswer
  zone: TargetZone

PresentationAnswer = lessThan | equalTo | greaterThan
TargetZone = normal | closeCall | danger | bullseye
```

`ExpressionValue`, `TargetValue`, and `PresentationAnswer` are distinct fields. The only correctness rule is `expressionValue < targetValue → lessThan`, equality → `equalTo`, and greater-than → `greaterThan`. The player selects only the presentation answer. No string parsing is permitted.

Generation obtains a legal expression through `QuestionGenerator.build` for one concrete canonical operation (addition, subtraction, multiplication, or division) and its requested `Difficulty` and `NumberType`; it requires the resulting typed `Question.fact` to be a valid direct `MathFact`. The Target Clash display expression is rendered from those typed fields, never parsed from `Question.text`. Target Clash V1 supports only Natural, Integers, and Rationals; `NumberType.mixed` is not eligible. Later configuration integration must hide or disable Mixed for Target Clash. Master, Daily Boss, and Survival are not valid Target Clash expression operations.

For a generated expression result `v`, relation sign `s` (`-1`, `0`, `+1` for `<`, `=`, `>`), and permitted distance `d`, construct `target = v - s × d`. The target must be representable in the selected number domain: Natural is an integer `>= 0`; Integers is an integer; Rationals is quantized to the expression `ratDP` (or one decimal place when absent). `unit = 1` for Natural/Integers and `10^-ratDP` for Rationals.

| Zone | Exact distance in units |
| --- | --- |
| Bullseye | `0` |
| Danger Zone | `1` |
| Close Call | `2` or `3` |
| Normal Zone | `4`, `5`, or `6` |

Zone is numeric closeness only: it is neither correctness, difficulty, nor mastery. The target is never an expression and canonical expression legality is never relaxed to reach a zone.

Fixed-target stage generation is atomic. First generate the stage's Bullseye/anchor direct `MathFact`; `targetValue = anchor.result`. Then generate every remaining scheduled stage question against that fixed target, enforcing its requested zone and relation only by bounded filtering of legal direct `MathFact`s. Never change the target to make a later question fit, parse strings, or accept an illegal `MathFact`. Each candidate selection attempts at most eight newly generated legal source expressions and a finite deterministic ordering of allowed distances/directions; stage preparation itself is finite and bounded. If a complete legal stage cannot be formed, return a typed failure before presenting any question from that stage.

Triple Clash is also atomically prepared before its first question: all requested `<`, `=`, and `>` members must be legal against its fixed target before any member is shown. It must never partially present `<` or `>` and then discover that `=` cannot be generated. No answer is changed, no invalid target is emitted, and there is no retry loop.

## 3. Exact V1 tuning and state machine

| Item | Easy | Medium | Hard |
| --- | ---: | ---: | ---: |
| Target streak | 3 ordinary questions | 3 | 3 |
| Zone order | Normal, Normal, Bullseye | Normal, Close Call, Bullseye | Close Call, Danger, Bullseye |
| Target ladder ordinary stages | 2 | 2 | 2 |
| Triple Clash | none | 3 questions | 3 questions |
| Boss health / question cap | 3 / 3 | 4 / 4 | 5 / 5 |
| Final Target questions | 3 | 3 | 3 |
| Fever | none | none | next 3 questions after a completed Triple Clash |
| Maximum run questions | 12 | 16 | 17 |

The two ordinary Target Streaks are atomically prepared with a fresh fixed numeric Target. Each contains exactly three scheduled questions and changes Target only after its third resolved question. Triple questions use the current stage target. A Power Shot modifies the next eligible scheduled question rather than inserting an extra question: it counts normally toward the ordinary streak, Boss cap, or Final Target count, may override that question's requested zone to Danger then Close Call when Danger cannot be legal, and never changes the fixed target. A Boss and Final Target begin a new atomically prepared target. A wrong answer or timeout resets Combo, not the Target Streak. A Target changes only at these stated boundaries.

State sequence is: `ordinaryStage1 → ordinaryStage2 → (Triple Clash when enabled) → Boss Target → Final Target → results`. Triple Clash contains exactly one requested `<`, `=`, and `>` item in one deterministic shuffled order; it completes only if all three are answered correctly, then shows `TRIPLE CLASH COMPLETE`. A failed/unavailable Triple has no partial completion claim. Hard Fever begins only after such completion, lasts its next three resolved questions, doubles score, and requests Danger before Close Call when legal. It changes neither math nor buttons.

Boss damage is 1 for a correct answer and 2 for a Perfect Hit (a Bullseye answered `=`); this latter event is the Bullseye Critical Hit. Wrong answers and timeouts do zero damage and reset Combo. Boss victory is health `<= 0`; reaching the cap without victory proceeds to Final Target but records no boss defeat. Final Target Completed means all three Final Target questions are resolved. Final Target Cleared means at least two of those three questions are answered correctly; reaching the end does not itself clear it. Thus every V1 run is finite.

Combo starts at 0; each correct answer increments it; wrong/timeout resets it to 0; display cap is 9. The score multiplier after a correct answer is `min(3, 1 + floor((combo - 1) / 3))`. Combo has no correctness effect.

Clash Power starts at 0, adds 1 for each correct and an additional 1 for a Perfect Hit, and is full at 6. A player may activate one available Power Shot between eligible scheduled questions; it consumes all 6, keeps the same target and `< = >` answer interface, and modifies that next question to request Danger Zone (then Close Call if Danger cannot be legal). It is not activatable during Triple Clash; if it becomes charged during Triple Clash, it remains charged until the next eligible scheduled question. It does not increase the run question count. Its only semantic change is the requested challenge and score bonus.

## 4. Scoring, reveal, UI, and accessibility

For a correct answer, score is `(10 + perfectHitBonus + powerShotBonus) × comboMultiplier × feverMultiplier`; `perfectHitBonus = 10`, `powerShotBonus = 20` only for a correct Power Shot, and `feverMultiplier = 2` only during Fever. Wrong and timeout score 0. Example: first ordinary correct scores 10; fourth consecutive correct scores 20; a first-answer Perfect Hit scores 20; a Combo-4 Fever Power Shot scores `(10 + 20) × 2 × 2 = 120`. Boss damage is separate from score.

The unanswered layout is exactly `TARGET <value>`, expression, then globally ordered `[ < ] [ = ] [ > ]`. It never displays ExpressionValue. After every resolved answer, a 1300 ms Clash Reveal shows `Expression = ExpressionValue` and `ExpressionValue relation TargetValue`, including the correct relation after errors. Perfect/Triple/Boss/Fever feedback appears around—not inside—the prompt card.

Later UI work uses semantic labels such as “Less than target”, preserves existing tap-target conventions, gives text/icon feedback in addition to color, and permits the reveal to remain readable when reduced motion is enabled. Existing audio/haptic feedback patterns may be reused; no new audio contract is required.

## 5. Results, replay, services, and power-ups

Results show Score, Correct, Accuracy, Best Combo, Perfect Hits, Bosses Defeated, Final Target Completed, Final Target Cleared, and Triple Clashes Completed where useful. They must not use mastery, intelligence, ability, or cognitive-level language. Target Clash is excluded from Hall of Fame because `HighScore` cannot identify it independently of `GameMode`; it also receives no new achievement, coin, shop, or cloud-progress field in V1. It still increments the existing completed-game ad cadence at end game; no mid-question ad is allowed.

Replay reuses the same immutable Target Clash configuration and identity but generates a fresh random Target/question sequence, matching existing snapshot replay behavior. It does not persist a seed or question sequence.

| Existing power-up | V1 Target Clash | Reason |
| --- | --- | --- |
| Time | blocked | Target Clash owns no new timing exception; keep its fixed timer contract. |
| 50/50 | blocked | It assumes numeric answer choices, not relation answers. |
| Double | blocked | Clash scoring/Power Shot already define multipliers. |
| Shield | blocked | No compatible ordinary-loss semantics. |
| Freeze | blocked | No compatible timer exception. |
| Swap operation | blocked | It could violate the fixed requested relation/zone. |

## 6. Backward compatibility and tests

TC-01 adds no persistence. Before integration, audit every exhaustive `GameRunType` switch, run snapshot construction/copy, timing-eligibility predicate, result branch, `GameState` lifecycle branch, menu/config eligibility test, and any `GameMode.values` assumption. Do not add a `GameMode` or persist enum indexes. Future persisted Target Clash data requires an explicit schema version, unknown-value rejection, and cloud/document decoder coverage.

| Test area | Required later proof |
| --- | --- |
| Relation and Bullseye | All three comparisons, equality, typed answer only. |
| Zones and generation | Exact unit bands; each operation/number type; canonical legality; bounded failure. |
| Streak/combo/power | Boundaries, reset, cap, charge, manual Power Shot consumption. |
| Triple/Fever/Boss/ladder | Relation set, no partial success, trigger/duration, damage, caps, finite finish. |
| Reveal/score/results | Hidden unanswered value, correct reveal, formula examples, metrics vocabulary. |
| Replay/navigation | Snapshot identity/config retention and fresh sequence; full screen path. |
| Persistence/services | Old saves/cloud/Hall behavior, ads cadence, all power-ups blocked. |
| Difficulty/regression | Easy/Medium/Hard table, all supported V1 number types, existing modes unchanged. |
| GameBrain | No observation, recommendation, policy, mastery, or persistence path. |

## 7. Planned slices

| Slice | Boundary |
| --- | --- |
| TC-01 | Pure relation, zone, companion question, and bounded canonical-generation seam only. |
| TC-02 | `GameRunType.targetClash`, immutable configuration/runtime owner, finite progression and scoring in `GameState`. |
| TC-03 | Menu/config/player-flow entry and gameplay relation-answer/reveal UI. |
| TC-04 | Results metrics, replay integration, service eligibility, persistence compatibility tests. |
| TC-05 | Visual/accessibility parity, full regression closure, and explicit GameBrain-firewall audit. |

### TC-01 exact proposed file scope

Production:

- `lib/features/target_clash/domain/presentation_answer.dart`
- `lib/features/target_clash/domain/target_clash_question.dart`
- `lib/features/target_clash/domain/target_clash_question_generator.dart`

Tests:

- `test/target_clash_question_test.dart`
- `test/target_clash_question_generator_test.dart`

TC-01 may import the existing `Question`, enums, and `QuestionGenerator`, but changes none of them. It does not implement gameplay UI, navigation, boss runtime, Fever runtime, scoring screen, persistence, or GameBrain.
