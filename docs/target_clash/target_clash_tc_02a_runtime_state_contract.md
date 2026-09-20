# TC-02A — Target Clash runtime / state implementation contract

## 1. Status / authority / baseline

**Contract-only.** This document authorizes no Dart, test, UI, persistence, or service change. TC-02A decision freeze is complete. `OPEN OWNER DECISIONS: 0`. The document is ready for independent final validation, then commit-only, then merge approval; it authorizes no TC-02B production implementation until the contract itself is committed and merged. It was audited at `feature/target-clash-tc02a-runtime-state-contract`, `140471725a417658a721333da2ed83ef01a50733`.

TC-00 and TC-01 remain authoritative. `GameState` is the sole owner of an active Target Clash run, its timer lifecycle, transitions, and eventual side effects. The TC-01 domain remains the sole owner of canonical fact validation and target-zone classification. Target Clash is not GameBrain evidence.

## 2. Current-source audit

| Concern | Current seam | TC-02 consequence |
| --- | --- | --- |
| Run identity | `lib/models/enums.dart` — `GameRunType { normal, operationQuest }` | Add `targetClash`; do not add `GameMode`. |
| Snapshot | `lib/engine/game_state.dart` — `GameRunSnapshot`, `withTimingStyle`, `withP1AgencyRoute` | Add an immutable nullable Target Clash config and copy it through both methods. No equality implementation currently exists. |
| Starts/replay | `lib/engine/game_state.dart` — `startGame`, `_startGame`, `_operationQuestSnapshot`, `debugStartGameFromSnapshot`, `replayGame` | Add a dedicated Target Clash snapshot factory/start seam; replay must retain config but regenerate stages. |
| Current question | `lib/engine/game_state.dart` — `RuntimeState.q`, `_generateQ`, `_nextTurn` | Do not force a `TargetClashQuestion` into numeric `Question.ans` semantics. A Target Clash branch owns its current TC question and converts typed facts only for display later. |
| Answer/timeout | `lib/engine/game_state.dart` — `onAnswer`, `_onAnswer`, `_onTimeout`, `_claimQuestionTerminal`, `_scheduleNextTurn` | Add one typed `onTargetClashAnswer(PresentationAnswer)` and one Target Clash timeout branch before numeric comparison, ordinary score, skill, follow-up, and observation paths. |
| Timer | `lib/engine/game_state.dart` — `_startQuestionTimer`, `_freezeQuestionTimer`, `_onTimeout`, `_closeActiveQuestionNeutrally`, `_invalidateActiveRun` | Reuse this timer/token/cancellation mechanism only. `TimingStyle.perQuestion` is fixed. |
| Existing scoring | `lib/engine/game_state.dart` — `_onCorrect`, `_onWrong`, `_checkProgressMilestones`, `_checkStandardTurnLimit` | Target Clash must bypass all of them; its fixed formula is not compatible with ordinary score, coins, streaks, boss, or turn limit. |
| Results/end | `lib/engine/game_state.dart` — `_endGameAfterFeedback`, `_endGame`, `_prepareResultSummary` | Add a target-clash end/result branch before cloud, high-score, achievement, and normal result work; completed-game ad cadence is the only allowed service. |
| TC-01 generation | `lib/features/target_clash/domain/target_clash_question_generator.dart` — `prepareStage`; `target_clash_question.dart` — `tryCreate` | Use atomic stage results and typed failures. Existing `prepareStage` always creates an anchor, so it cannot produce a replacement against a supplied existing target. |
| Existing special runs | `lib/engine/game_state.dart` — `_operationQuestSnapshot`, `_isMentalMathRun`, `_isValidMentalMathFreePracticeSetup` | Target Clash is neither pattern: it gets its own `runType`, config, and runtime state. |
| GameBrain/study | `lib/engine/game_state.dart` — `_captureQuestionExperienceIfSupported`, `_contextEvidenceKey`, `_supportsP1F01IntegrityRun`, `_observeContextEvidence` | All must explicitly require `GameRunType.normal`; TC has no observation, study admission, advisory, or policy call. |
| Persisted study decoding | `lib/features/game_brain/study/p1_f01_study_store.dart` — `P1StudyScientificSnapshot` projection | It already accepts names from `GameRunType.values`; this must remain descriptive decoder validation, not authorization to emit TC data. |

No persistence serializes a `GameRunType` index. Active `GameRunSnapshot` is in-memory only. `HighScore` identifies only `GameMode`, which is insufficient to identify Target Clash.

## 3. Exact TC-02 integration seams

TC-02 must add a narrow `GameState` dispatch: if `activeRunSnapshot.runType == GameRunType.targetClash`, question opening, `PresentationAnswer` resolution, timeout resolution, progression, and result preparation use the Target Clash state; otherwise current code remains byte-for-byte behaviorally unchanged. It must not widen ordinary `onAnswer(num)`.

The TC runtime may be an immutable `TargetClashRuntimeState` replaced by `GameState`, or a controlled value private to `GameState`; it is not an autonomous engine, singleton, UI state, or persisted active run. TC-01 generation remains pure.

## 4. GameRunType / GameRunSnapshot contract

`GameRunType.targetClash` is the identity. Its snapshot has `mode: GameMode.standard`, `players: 1`, `timingStyle: TimingStyle.perQuestion`, `questionMechanic: QuestionMechanic.standard`, `answerStyle: AnswerStyle.choice4` only as a compile-safe ordinary carrier value, and `targetClashConfig != null`. For every other run, `targetClashConfig == null`. Mixed is rejected before the snapshot is constructed.

For every Target Clash snapshot, `snapshot.operation == targetClashConfig.operation`, `snapshot.difficulty == targetClashConfig.difficulty`, and `snapshot.numberType == targetClashConfig.numberType`; its carrier mirrors remain `mode == GameMode.standard`, `players == 1`, `timingStyle == TimingStyle.perQuestion`, and `questionMechanic == QuestionMechanic.standard`. `TargetClashRunConfig` is the typed Target Clash configuration authority; the matching scalar snapshot fields are compatibility/carrier mirrors required by the existing engine. A dedicated Target Clash snapshot factory constructs config and mirrors atomically. Any debug, replay, or imported in-memory Target Clash snapshot with a missing config or divergent mirrors fails closed before gameplay begins. `withTimingStyle(...)` and `withP1AgencyRoute(...)` preserve the exact same config identity and mirror equality.

`GameRunSnapshot.questionTarget` for Target Clash is the carrier V1 run count: Easy `12`, Medium `16`, Hard `17`. Under the frozen V1 profiles, a successfully finished Easy run resolves exactly `12` questions, Medium exactly `16`, and Hard exactly `17`. A technical generation failure may terminate earlier, but is not a successfully finished run. `rt.maxTurns` may receive this carrier value only for compatibility; it has no Target Clash terminal authority. The Target Clash phase state machine is terminal authority, and Target Clash must never use ordinary `_checkStandardTurnLimit` as terminal authority.

`GameRunSnapshot` owns immutable replay identity: `runType`, carrier `mode`, selected operation, difficulty, number type, timing style, player count, and `TargetClashRunConfig`. It does not own mutable target, sequence, power, Fever, score, or outcome counters. TC configuration is copied by `withTimingStyle` and `withP1AgencyRoute`; replay calls `_startGame(replaySnapshot: snapshot)` and creates a fresh runtime/stages, never a seed or serialized sequence.

Every existing `GameRunType` site to audit in TC-02B is: `lib/engine/game_state.dart` — `isOperationQuest`, timing eligibility, `_startGame`, `_generateQ`, GameBrain/P1 predicates, and `replayGame`; `lib/features/game_brain/study/p1_f01_study_store.dart` — enum-name validation; and the snapshot fixtures in `test/timing_style_foundation_test.dart`, `test/visual_parity_test.dart`, `test/mental_math_v2_test.dart`, `test/mental_math_entry_context_test.dart`, and GameBrain study tests.

## 5. TargetClashRunConfig contract

Create one immutable value with exactly: concrete `Operation` (addition/subtraction/multiplication/division), `Difficulty` (easy/medium/hard), `NumberType` (natural/integers/rationals), and fixed internal `TargetClashProfile.v1` identity. The player selects the concrete Target Clash operation from addition, subtraction, multiplication, or division; mixed, master, dailyBoss, survival, and every future special operation are ineligible unless explicitly added later. The profile identity is not user-selectable. It derives one player, per-question timing, no Adaptive, fixed stage ladder, and relation presentation; it must not duplicate snapshot-owned mode, players, timing style, or run type. It is the typed authority for operation, difficulty, number type, and profile identity; its operation, difficulty, and number type are mirrored by the required existing snapshot carrier fields under the section 4 invariants. TC-02 may construct/start Target Clash only through controlled, internal, or test seams until TC-03 provides configuration UI.

## 6. Runtime state model

Canonical stored fields are: `phase`, `preparedStage`, `stageQuestionIndex`, `score`, `correctCount`, `resolvedCount`, uncapped `combo`, `bestCombo`, `perfectHits`, `clashPower`, `powerShotAppliedQuestionIndex`, `feverRemaining`, `tripleCorrectCount`, `tripleClashesCompleted`, `bossHealth`, `bossQuestionsResolved`, `bossesDefeated`, `finalCorrect`, `finalResolved`, and typed `generationFailure` only in technical failure. `clashPower == 6` means Power Shot is READY; readiness and application are not represented by the same boolean.

Derived fields are current question/target from `preparedStage.questions[stageQuestionIndex]`, `displayCombo = min(combo, 9)`, combo multiplier, `isTriple`, `isFeverActive = feverRemaining > 0`, `finalTargetCompleted = finalResolved == 3`, `finalTargetCleared = finalCorrect >= 2`, and `bool get finished => phase == TargetClashPhase.finished`. There is no independent finished boolean or contradictory dual terminal truth. `TargetClashPhase.technicalFailure` is the other terminal condition: it requires `generationFailure != null`, exposes no open question or active prepared stage, has no finished-success claim, and has no completed-game ad eligibility. An open state has one fully prepared stage and an in-range `stageQuestionIndex`; terminal states have no open question. Boss health and Boss counters have meaning only in Boss; Final counters have meaning only in Final. A Power Shot marker identifies exactly one scheduled index in its current immutable stage. Reset is construction of a fresh state only.

## 7. Phase state machine

`ordinaryStage1 → ordinaryStage2 → [triple] → boss → finalTarget → finished`; any atomic stage-generation failure transitions to terminal `technicalFailure`.

Easy skips Triple; Medium and Hard do not. Each ordinary stage is newly atomically prepared. Triple reuses the completed second ordinary stage's target. Boss and Final each create a new atomically prepared target. A phase transition occurs only after the current resolved slot or immediate Boss defeat; stale callbacks are rejected by the existing question token.

## 8. Ordinary stage contract

There are exactly two three-slot stages. Their deterministic typed request lists are: Easy Stage 1 `[< Normal, > Normal, = Bullseye]` and Stage 2 `[> Normal, < Normal, = Bullseye]`; Medium Stage 1 `[< Normal, > CloseCall, = Bullseye]` and Stage 2 `[> Normal, < CloseCall, = Bullseye]`; Hard Stage 1 `[< CloseCall, > Danger, = Bullseye]` and Stage 2 `[> CloseCall, < Danger, = Bullseye]`. Bullseye always requests `PresentationAnswer.equalTo`. Ordinary stages never shuffle. Wrong and timeout resolve a slot and retain its target. The target changes only after the third slot; `TargetClashQuestionGenerator.prepareStage` supplies a complete stage or a typed failure before it is visible.

## 9. Triple Clash contract

Prepare all three against the current second-stage target before showing one. Triple contains exactly `lessThan`, `equalTo`, and `greaterThan`. Before atomic Triple preparation, use the GameState-owned run RNG to select exactly one `permutationIndex = runRng.nextInt(6)` and map it as follows: `0 [lessThan, equalTo, greaterThan]`; `1 [lessThan, greaterThan, equalTo]`; `2 [equalTo, lessThan, greaterThan]`; `3 [equalTo, greaterThan, lessThan]`; `4 [greaterThan, lessThan, equalTo]`; `5 [greaterThan, equalTo, lessThan]`. Build the complete ordered request list from that permutation, prepare the full stage before question 1, and never reshuffle after exposure. Replay starts a fresh run and may receive a fresh permutation through normal fresh-run RNG; no Triple seed, permutation index, or sequence is persisted. Deterministic domain tests may inject or supply the selection explicitly, but production uses the current GameState run RNG. Current TC-01 `prepareStage` cannot accept that existing target, so TC-02C requires a bounded TC-01 extension that takes a supplied target and ordered requests; it must not regenerate or move the target. Only three correct answers increment `tripleClashesCompleted`; any miss prevents completion. Power Shot activation is denied throughout Triple.

## 10. Fever contract

Hard only: after a completed Triple, set `feverRemaining = 3`. It lasts exactly the next three resolved questions. Capture `feverActiveForResolution` before mutations, apply x2 to every such resolution regardless of whether hardening can materialize, then decrement once on correct, wrong, or timeout. It spans Boss if needed, never changes answer semantics/legality, and coexists with a Power Shot.

For a Fever-active scheduled question, retain an existing Danger without redundant replacement and retain a Bullseye without degrading it. For Normal or Close Call, request Danger first, then Close Call through the fixed-target replacement seam. If neither is available, retain the original scheduled question. This is bounded best-effort hardening, never a run-terminal generation failure; it never moves the target or inserts a question.

Power Shot and Fever materialize only one effective question for a scheduled slot. Fever-only retains an existing Danger or Bullseye, and otherwise follows its Danger-then-Close-Call best-effort request. A manual Power Shot takes precedence over Fever's retain-original rule: an already-Danger slot is retained and marked without regeneration; otherwise it makes one Danger-then-Close-Call replacement attempt, including for an original Bullseye. If both requests are unavailable, retain the original question without a marker, retain Clash Power at 6, report Power Shot unavailable, and do not terminate the run. No second regeneration occurs. Fever multiplier and Power Shot bonus-marker remain independent, Fever still consumes one of its three resolved-question windows, and both may apply to the same resolution. Neither changes the target or inserts a question.

## 11. Combo / Best Combo contract

Start `combo = 0`. Correct increments it and updates `bestCombo`; wrong/timeout set it to zero. Internal combo never caps; presentation alone caps at 9. For a correct resolution, after increment, multiplier is `min(3, 1 + ((combo - 1) ~/ 3))`: combos 1–3 x1, 4–6 x2, 7+ x3.

## 12. Perfect Hit contract

Perfect Hit is exactly `question.zone == TargetZone.bullseye && question.correctAnswer == PresentationAnswer.equalTo && playerAnswer == PresentationAnswer.equalTo`. It adds one `perfectHits`, one extra power charge, score bonus 10, and Boss damage 2. No other correct equality-like event qualifies.

## 13. Clash Power / Power Shot contract

Correct adds one charge; Perfect Hit adds one further charge; clamp at 6. Wrong/timeout add none. A manual activation is valid only between open questions, at charge 6, outside Triple, and when an eligible scheduled next slot exists. It does not insert a question, replace a target, or alter count.

`preparedStage` remains immutable. TC-02C adds a pure supplied-target question materialization seam. Materialize a replacement completely before exposing it: request Danger against the same target, then Close Call only when Danger has a typed no-candidate failure. A successful replacement creates a new immutable stage with the same target, length, order, and every original slot except the exactly one replaced scheduled slot. `GameState` atomically replaces `runtime.preparedStage` and sets `powerShotAppliedQuestionIndex` only after the complete replacement is legal. A failed replacement leaves the old stage untouched. The replacement API returns a complete `TargetClashQuestion` or typed failure; no partial stage/state is exposed.

On successful activation, the replacement/effective-slot state and marker become visible atomically, and Clash Power is consumed from 6 to 0. For an already-Danger scheduled slot, successful activation retains that exact question, sets its marker without regeneration, and also consumes Clash Power from 6 to 0. On resolution of exactly the marked slot, correct receives the `+20` Power Shot bonus and wrong/timeout receives zero score; clear the marker exactly once. The modifier never survives onto a later slot.

When both Danger and Close Call materialization fail, the unavailable activation leaves the original scheduled question unchanged, sets no marker, retains Clash Power at 6, reports Power Shot unavailable, applies no score bonus, inserts no question, moves no target, and causes no runtime-terminal generation failure.

## 14. Boss contract

Prepare a new target atomically from the deterministic Boss request list: Easy cap 3 `[< Normal, > Danger, = Bullseye]`; Medium cap 4 `[< Normal, > CloseCall, < Danger, = Bullseye]`; Hard cap 5 `[< Normal, > CloseCall, < Danger, > Danger, = Bullseye]`. Boss never shuffles. Store starting `bossHealth` (Easy 3, Medium 4, Hard 5) and `bossQuestionsResolved`; correct damage is 1 or 2 for Perfect Hit; wrong/timeout damage zero. After each resolution increment `bossQuestionsResolved`. If `bossHealth <= 0`, increment `bossesDefeated` once, discard any remaining scheduled Boss slots immediately, and transition to Final. If the cap is reached first, transition to Final without a defeat. Under the frozen V1 profiles, this condition cannot become true before the final scheduled Boss slot: maximum pre-final damage is Easy `2 < 3`, Medium `3 < 4`, Hard `4 < 5`. The branch remains a defensive runtime invariant for future profile changes and isolated state-machine testing; it is not reachable V1 product flow before the cap.

## 15. Final Target contract

Prepare a new three-slot target atomically from the deterministic Final Target request list: Easy `[< Normal, > CloseCall, = Bullseye]`; Medium `[< CloseCall, > Danger, = Bullseye]`; Hard `[< Danger, > Danger, = Bullseye]`. Final never shuffles. Increment `finalResolved` for every terminal answer and `finalCorrect` only for correct. At three resolved, derive `finalTargetCompleted == true`, `finalTargetCleared == finalCorrect >= 2`, and finish. These are independent facts: 0/3 and 1/3 complete but do not clear.

## 16. Scoring and resolution ordering

The sole TC resolution order is: validate typed answer / determine correctness; determine Perfect Hit; update combo and derive its multiplier; capture Fever active; score `(10 + perfectHitBonus + powerShotBonus) * comboMultiplier * feverMultiplier` or zero; add/cap Clash Power; decrement Fever if active; apply Boss damage; update phase counters; transition or open the next slot. A correct armed Power Shot gets +20; a wrong one gets zero score and no bonus. This yields 10 for first ordinary correct, 20 for first Perfect Hit, 20 at combo 4 ordinary, and 120 for combo-4 Fever correct Power Shot.

Timeout follows the same path with no `PresentationAnswer`: incorrect, combo reset, zero score/damage/charge, Fever decrement, counters, and transition. Neither path compares `Question.ans`, parses `Question.text`, calls ordinary `onAnswer(num)`, or invokes standard `_onCorrect`/`_onWrong`.

## 17. Timer integration

TC-02D opens each staged question through `_startQuestionTimer`; `_onTimeout` must route to the typed Target Clash timeout when `runType == targetClash`. Resolution cancels/freezes the timer through the same token-safe `_freezeQuestionTimer`, and opening the next slot resets it. `_closeActiveQuestionNeutrally`, `_invalidateActiveRun`, `_endGame`, replay, and quit retain their cancellation responsibilities. `_normalizeSnapshotTimingStyle` must make per-question the only TC outcome. No new timer, pause policy, or Standard behavior is inherited.

## 18. Generation-failure behavior

Any atomic stage-generation failure for initial ordinaryStage1, ordinaryStage2, Triple, Boss, or Final is a typed technical termination. Store it in `TargetClashRuntimeState.generationFailure`, enter terminal `TargetClashPhase.technicalFailure`, stop Target Clash progression, and expose no partial stage or fallback ordinary `Question`. Never move the target to recover, retry without a fixed finite contract, or convert to a normal run. Technical termination makes no Final Target Completed/Cleared, Boss defeat, or Triple completion claim; it grants no Target Clash reward/progress persistence, HighScore, achievement, economy, cloud mutation, GameBrain observation/advisory, or completed-game ad cadence. It is not a successfully completed game; later UI may show a neutral technical-failure message and route safely, but TC-02 implements no production UI. Power Shot and Fever best-effort replacement failure is not a run-terminal stage failure and follows their frozen rules.

## 19. Standard-carrier firewall

| Existing path | Current seam | TC-02 rule |
| --- | --- | --- |
| Answer style | `GameState.effectiveAnswerStyle`; `GameScreen._AnswersGrid` | Deny ordinary numeric/true-false semantics; later UI uses only relation buttons. |
| Start | `_startGame`, `rt.isWarmUp`, `_applyPowerUpBonusIfEligible`, `_generateQ`, ordinary follow-up setup | Set `rt.isWarmUp = false`; skip `_applyPowerUpBonusIfEligible`; `activeAdaptive = false`; do not route through ordinary `_generateQ` or begin ordinary follow-up logic. |
| Adaptive | `_generateQ`, `activeAdaptive`, `_updateAdapt` | Deny. |
| Existing power-ups | `_applyPowerUpBonusIfEligible`, `_onCorrect`, `usePowerUp`, `_isPowerUpBlocked` | Deny all `PowerUp` values; only Clash Power exists. |
| Follow-up | `_onWrong`, `_resolveP1FollowUpAfterCanonicalContinuation` | Deny. |
| Ordinary score | `_onCorrect`, `_onWrong` | Deny; use section 16 only. |
| Hall/High Score | `_endGame`, `HighScore` | Deny. |
| Skills/mastery | `_updateSkillMap`, `_updateMastery`, `_updateAdapt` | Deny. |
| Achievement/economy/cloud | `_onCorrect`, `_endGame`, `addCoins`, `unlockAch`, `_markCloudDirty`, `save` | Deny all Target-Clash mutation. |
| GameBrain | `_gameBrain`, `_captureQuestionExperienceIfSupported`, `_contextEvidenceKey`, `_observeContextEvidence`, P1 helpers | Do not instantiate or use a Target Clash GameBrain runtime; keep `_gameBrain` null, do not open P1/GameBrain admission, and leave all observation/advisory calls unreachable. |
| Per-question timer | `_startQuestionTimer`, `_onTimeout` | Allow only. |
| Completed-game ads | `_recordCompletedGameForAds` | Allow only at a finished run. |

At end, Target Clash V1 allows only existing `_recordCompletedGameForAds()` after a genuinely finished run. It explicitly denies `_markCloudDirty()`, `gamesPlayed++`, High Score, achievements, coins/economy, `save()`, and every cloud-progress mutation. The ad cadence is its own service call and must not be implemented by general persistence mutation. In-memory result preparation may occur later, but no V1 result persistence is authorized.

TC-02D audits every GameScreen mode-only hazard and exposes the required run identity, typed getters, and GameState guards, but does not modify `lib/screens/game_screen.dart`. TC-03 performs the Target Clash gameplay UI integration: relation buttons; Target Clash prompt/reveal; Power Shot UI; hiding ordinary AnswerStyle UI and ordinary power-up HUD; and every GameScreen runType guard identified by the TC-02 audit. Until TC-03, Target Clash starts only through controlled, test, or internal seams required for TC-02 validation—not through production menu/config UI.

## 20. GameBrain / services firewall

Target Clash creates no `QuestionExperienceObservation`, `ContextEvidenceObservation`, P1 study record, GameBrain instance observation, adaptive shadow call, skill update, learner model update, recommendation, `chooseDifficulty`, Canonical Fact Center claim, achievement, coin, shop, cloud, HighScore, or Hall of Fame entry. TC-02D must gate before these calls—not merely discard output afterwards. End-game ad cadence remains existing service behavior and no Target Clash progress is persisted.

## 21. Backward compatibility

Normal, Operation Quest, Mental Math, Master, Daily Boss, Survival, two-player turns, and existing saved data retain their current behavior. No enum-index persistence is introduced. `GameRunType.values` decoder coverage must tolerate the new name without turning it into a study-eligible run. TC-02 includes no menu/config/relation UI/results/replay UI, persistence schema, Hall of Fame, achievements, economy, cloud, or GameBrain integration.

## 22. Required tests

TC-02 later proves: enum identity; snapshot copy/retention and `questionTarget = 12 / 16 / 17`; snapshot/config operation, difficulty, and number-type mismatches fail closed; `withTimingStyle`/`withP1AgencyRoute` preserve config identity and mirror equality; normal Standard unchanged; successful V1 Easy, Medium, and Hard runs resolve exactly `12`, `16`, and `17` questions respectively; finite Easy/Medium/Hard paths; ordinary boundaries and retained target on wrong/timeout; exact deterministic request list for every ordinary difficulty/stage, Boss difficulty, and Final difficulty; only Triple shuffles; Bullseye always equals; all six Triple permutations are reachable through exactly one `nextInt(6)`-equivalent selection, with the exact 0–5 mapping, no reshuffle after question 1, and no persisted replay permutation; frozen V1 Boss profiles cannot defeat Boss before the final scheduled Boss slot; a synthetic or isolated runtime-state test reaching `bossHealth <= 0` before cap immediately exits Boss, and this is state-machine coverage rather than a reachable frozen V1 profile claim; technical generation failure may terminate before `questionTarget` but is not successful completion; Hard Fever next three resolved slots; Fever-only Bullseye remains Bullseye; unavailable Fever hardening retains the original question while consuming one Fever resolution; Fever plus Power Shot makes only the Power Shot effective replacement attempt, never double-regenerates, and may replace Bullseye; combo thresholds/reset/best; Perfect Hit; power cap/gating/no insertion/no Triple activation; every successful Power Shot consumes 6 to 0; all-unavailable Power Shot retains charge 6, sets no marker, retains the original question, and does not terminate the run; an already-Danger Power Shot marks its existing question without regeneration; Power Shot replacement creates a new immutable stage and changes exactly one slot; failed replacement leaves the prior stage structurally unchanged; its applied marker clears after exactly its scheduled question and cannot leak to the next; initial, ordinary-boundary, Triple, Boss, and Final stage-generation failures enter technical terminal state with no partial stage, completed-game ad cadence, persistence, economy, or GameBrain side effects; each four basic operation is accepted while mixed and special operations are rejected, and fixed V1 profile is not player-selectable; Boss 1/2/0 damage, cap failure; Final completed/cleared split; all score examples and zero wrong/timeout; per-question timeout/timer reuse; Target Clash starts with no warm-up; no ordinary initial power-ups; GameBrain runtime/admission remains absent; `gamesPlayed` and `cloudDirty` do not change; save/High Score/achievement paths are not called; completed-game ad cadence increments exactly once on genuine completion; TC-02 introduces no GameScreen production change; normal/Operation Quest/Mental Math regressions.

## 23. Exact proposed TC-02 implementation file scope

TC-02B production: `lib/models/enums.dart`, `lib/engine/game_state.dart`, and new `lib/features/target_clash/domain/target_clash_run_config.dart`; tests: a new snapshot/firewall test plus affected snapshot fixtures.

TC-02C production: new `lib/features/target_clash/domain/target_clash_runtime_state.dart` and the smallest extension to `lib/features/target_clash/domain/target_clash_question_generator.dart` required for supplied-target atomic materialization; tests: new runtime-state and generator tests.

TC-02D production: `lib/engine/game_state.dart` only; tests: new GameState Target Clash lifecycle/timer/firewall test. No UI file enters scope until TC-03.

## 24. Recommended TC-02 implementation sub-slices

| Slice | Dependency / commit boundary | Explicit exclusion |
| --- | --- | --- |
| TC-02B | identity, config, snapshot copy/normalization, default-deny predicates; commit after snapshot/firewall tests | runtime progression and UI |
| TC-02C | TC-01 supplied-target seam plus pure state/progression/scoring; commit after deterministic domain tests | GameState/timers/services |
| TC-02D | GameState start, typed answer/timeout, timer and end firewall; commit after lifecycle regressions | menu, relation UI, result UI, persistence |

## 25. Frozen owner decisions

1. **Power Shot all-unavailable consumption** — retain the original question and all six charge, set no marker, report unavailable, and do not terminate the run.
2. **Triple deterministic shuffle mechanism** — use exactly one GameState run-RNG `nextInt(6)` selection and the section 9 mapping before atomic preparation; never reshuffle or persist the permutation.
3. **Stage-generation failure disposition** — atomic stage failures are typed technical termination, not successful completion, with no partial stage or rewards/persistence/ad cadence.
4. **Canonical V1 operation/profile source** — player-selected basic operation plus typed `TargetClashRunConfig` and fixed internal `TargetClashProfile.v1`; carrier mirrors remain exact.
5. **V1 ordinary/Boss/Final request profiles** — use the deterministic section 8, 14, and 15 request lists; only Triple shuffles.

`OPEN OWNER DECISIONS: 0`.
