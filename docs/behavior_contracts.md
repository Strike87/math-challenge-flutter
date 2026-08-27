# Math Challenge Behavior Contracts

## Source of truth

The original/reference behavior remains authoritative except for explicitly
approved Flutter additions.

A refactor must preserve verified behavior and ordering unless a separate
product decision or confirmed bug authorizes a change.

## Adaptive difficulty

- Fast correct: `+7` below `1500ms`.
- Normal correct: `+5` from `1500ms` through `2999ms`.
- Slow correct: `+3` from `3000ms`.
- Wrong: `-4`.
- Timeout: `-2`.
- Confidence EMA alpha: `0.25`.
- Speed score: `max(0, 100 - milliseconds / 120)`.
- Difficulty thresholds: `45 / 65 / 82 / 93`.
- Secondary nudges: `+0.6 / +0.2 / -0.5`.
- Global adaptive level is derived from mean mastery.
- Operations retain independent mastery.
- Primary and secondary mastery updates remain separate and ordered.

## Modes

- Blitz global timer: `60` seconds.
- Combo global timer: `90` seconds.
- Survival phase advances every `5` correct answers.
- Survival boss event occurs every `10` correct answers.
- Survival boss reward: `+5` coins.
- Survival wrong answers and per-question timeouts reduce lives.
- Master uses authored stage parameters.
- Daily Boss uses its fixed daily configuration.
- Standard two-player question count is per player.
- Selecting `10` questions produces `20` combined turns.
- Per-player counter remains `1/10`, `2/10`, and so on.

## Unsupported challenge/mode hybrids

Public mutable state permits challenge/mode combinations that supported UI
flows do not actively start.

In particular, `GameMode.survival` combined with `Operation.master` preserves
the executable-reference ordering, including the Survival phase-scoring branch.

This combination is unsupported but publicly constructible. It is intentionally
retained for reference parity.

Do not remove the branch or normalize this hybrid as incidental refactoring.
Any coherence guard requires a separate product decision and a full audit of
scoring, timers, lives, coins, progression, achievements, UI, replay, and
persistence behavior.

## Delayed terminal feedback

- Sudden Death terminal delay: `600ms`.
- Survival terminal delay: `900ms`.
- Master terminal delay: `900ms`.
- Daily Boss terminal delay: `900ms`.
- Delayed callbacks remain cancellable, guarded, and idempotent.

## Economy

- Integer number-type unlock: `500` coins.
- Rational/decimal unlock: `1200` coins.
- Daily Bonus: `+20` once per local calendar day.
- Rewarded ad: `+10` only after a successful rewarded callback.
- Rewarded-ad cooldown: persisted `5` minutes.
- Closing or failing a rewarded ad grants nothing.

## Advertising

- Interstitials are initiated only from the completed-game path.
- They are shown only after result dismissal.
- They must never interrupt an active question.
- Removed-ads ownership disables applicable ads.

## Persistence

- Existing keys, defaults, and migrations remain compatible.
- Reset uses the canonical wipe list.
- Refactors must not silently change save ordering.
- Transaction-order repairs are deferred until an approved persistence
  boundary exists.

## Current extracted pure boundaries

- `CoinLedger`
- `DailyBonusPolicy`
- `NumberTypeUnlockPolicy`
- `AdaptiveDifficultyEngine`
- `SurvivalProgressionPolicy`
- `ToastController` presentation boundary

## Mental Math Practice v1 — frozen contract

### Status

- **FROZEN:** the product, behavior, ownership, and safety boundaries below.
- **AUTHORIZED FOR IMPLEMENTATION:** only the sequenced slices stated below.
- **NOT YET IMPLEMENTED:** Mental Math entry points, runtime scheduling, UI,
  persistence additions, and gameplay integration. `MM-TR-00` is foundation
  only; it does not provide Mental Math gameplay.

### Product flow and configuration

- Mental Math Practice v1 is one package with three entries: **Free Practice**,
  **Daily Mental Math**, and **Weak Skills Practice**. Targeted Repetition is
  an internal deterministic practice mechanic, not a mode or menu destination,
  and is neither GameBrain nor ML or misconception diagnosis.
- Free Practice follows the existing Quick Practice operation/mechanic choice,
  then **Practice Style -> Number Type -> Config -> Player Setup -> Gameplay ->
  Results**. Practice Style selects Timing Practice or Mental Math; it is not a
  Mental Math hub. Do not create a separate mini-app.
  Unsupported choices remain visible-disabled where safe; visible-but-disabled
  is preferred to hidden.
- Reuse the canonical `10`, `15`, `20`, and `25` question-count selector. The
  chosen target is immutable; Targeted Repetition substitutes future questions
  and never adds turns or a separate length control.
- Supported operations are Addition, Subtraction, Multiplication, Division,
  Mixed, and the existing operator-blank Missing Operation mechanic. Missing
  Operation remains canonical Choice4-only (`8 ? 7 = 56`); it is distinct from
  Quest-only operand-blank Missing Number and from future Targeted Repetition.
  Reuse canonical operation and question-generation ownership.
- Reuse available Natural, Integers, and Rationals eligibility. The frozen run
  Number Type never changes, including for a targeted follow-up.
- The selected visible difficulty (Easy, Medium, or Hard) is fixed. Adaptive is
  off, visible-disabled, and runtime fail-closed; it must not promote or demote
  Mental Math difficulty.
- Both existing canonical answer styles, 4 Choices and True / False, are
  supported. True / False remains the existing downstream canonical projection;
  there is no second proposition, distractor, scoring, or validation engine.
  Any incompatible existing combination is visible-disabled.
- Per Question is the only Mental Math TimingStyle. Deep Thinking / Untimed
  and Time Bank are visible-disabled. TimingStyle remains immutable in the
  run snapshot.

### Evidence and product firewalls

- MM-00's immutable Mental Math entry/context fact must fail closed in all
  current evidence paths: `_captureQuestionExperienceIfSupported`,
  `_contextEvidenceKey`/context observation, and
  `_supportsP1F01IntegrityRun`. This prevents QEO/context observations and
  GameBrain shadow advisories as well as making P1-F01 eligibility false. Do
  not broaden its `chooseDifficulty` / Per Question envelope or use Mental
  Math outcomes as confirmatory evidence.
- Mental Math has no GameBrain personalization, player-model decision,
  difficulty override, or inferred misconception. A wrong answer identifies
  only an eligible fact for deterministic practice scheduling.
- Reuse canonical mastery and skill history for ordinary correct, wrong, and
  timeout outcomes. Do not add a second mastery model, targeted-repetition
  inference label, history database, leaderboard, Hall of Fame category,
  special reward, or Daily Mental Math streak/reward.
- Sessions retain normal completion lifecycle behavior and existing global ad
  cadence without a Mental-Math-specific ad path. Any existing generic economy
  or completion side effect must be reviewed and explicitly bounded before it
  is enabled; it must not create duplicate rewards.

### Entry-specific rules

- **Free Practice** reuses normal Quick Practice configuration, Player Setup,
  gameplay, and Results surfaces through the lightweight Practice Style step.
- **Daily Mental Math** receives its direct menu entry only in MM-04.
- **Weak Skills Practice** receives Mental Math integration only in MM-03.
- **Daily Mental Math** uses deterministic local-date-derived configuration,
  distinct from Daily Boss. It inherits no boss lives, rewards, claims,
  achievements, or progress semantics. Daily configuration determinism does
  not promise an identical outcome-dependent question sequence.
- **Weak Skills Practice** reuses canonical eligibility, evidence threshold,
  ranking, fallback, focus lock, `WeakSkillsPlan` snapshot, mastery data, and
  deterministic focus schedule. The plan is frozen for the round; Targeted
  Repetition may substitute a due question only after the Weak Skills schedule
  advances normally. It must not rerank, mutate focus, or become a second
  schedule owner.

### Targeted Repetition and canonical fact families

- Targeted Repetition repeats the same underlying `MathFact` through a
  different legal canonical representation, not merely the same operation and
  difficulty. `MM-TR-00` (`cdc1c57`) provides the sole foundation:
  `MathFact`, `FactRepresentation`, `Question.fact`, and
  `QuestionGenerator.buildRelated(...)`. Never parse rendered text or opaque
  keys, or reconstruct operands in `GameState`.
- The generator owns facts, operands, result, representation and inverse
  legality, commutative transformations, Number Type conversion, answers,
  choices, distractors, RNG, and mathematical validity. The scheduler owns
  only pending/due state, attempts, seen representations, and request intent.
- Canonical legality is stricter than mathematical validity. Easy allows only
  direct/missing-result form; Medium and Hard allow direct, missing-left, and
  missing-right forms. Mixed resolves to an effective basic operation.
- Reversal is permitted only for Addition and Multiplication. Inverse
  Addition/Subtraction and Multiplication/Division forms are permitted only
  when the selected operation scope permits both operations (normally Mixed).
  A single-operation run never injects its inverse. Every related request must
  preserve difficulty, Number Type, operation scope, ranges, signed/rational
  constraints, and division-by-zero safety; if none is legal, decline and use
  normal canonical generation.
- Any future Targeted Repetition for Missing Operation must preserve its
  operator-blank mechanic.
- The representation request occurs upstream of the existing AnswerStyle and
  True / False projection. Targeted Repetition never constructs false
  propositions, chooses wrong values, or creates distractors.
- Only wrong answers and question timeouts may enqueue an eligible generated
  fact. Correct, skipped, replaced, abandoned, and unfinished questions do
  not enqueue one.
- A same-fact follow-up requires at least **two completed intervening
  questions**; late facts may expire. At most **two** follow-ups are allowed
  per fact family, with a correct first follow-up resolving it and the second
  always resolving/dropping it afterward. Prefer unseen legal
  representations; otherwise decline targeted generation.
- Cap pending fact families at **three**. Deduplicate/merge a fact already
  pending, with no unbounded priority amplification. Do not schedule targeted
  questions back-to-back when a normal legal question can be generated.
- Targeted Repetition state (pending families, attempts, seen representations,
  and priority) is run-local only. Replay preserves the Mental Math entry and
  immutable configuration, including a `WeakSkillsPlan` where applicable, but
  resets the Targeted Repetition queue empty.

### Required implementation order and acceptance boundaries

- **MM-00:** add the immutable Mental Math entry/context and P1-F01 firewall.
- **MM-01:** integrate Free Practice through existing product surfaces.
- **MM-02:** add the bounded Targeted Repetition scheduler using MM-TR-00.
- **MM-03:** integrate Weak Skills Practice.
- **MM-04:** integrate Daily Mental Math.
- **MM-05:** complete visual parity, regression review, and independent
  closure.

Future acceptance must verify that `GameState` retains `Question.fact` when
it creates `runtimeQuestion`; Mental Math context must fail closed for timing
and Adaptive; and the scheduler replaces or suppresses legacy immediate
`_FollowUpData` behavior rather than running alongside it.

## Mental Math v2 Free Practice — frozen contract

### Status and scope

- **FROZEN FOR PLANNING; NOT IMPLEMENTED:** This supersedes the v1 Free
  Practice flow and configuration rules only. It does not authorize source
  implementation in this contract-freeze step.
- Mental Math v2 is a distinct deterministic arcade-style learning loop in
  the existing Math Challenge visual identity. It is neither Adaptive,
  GameBrain, ML, personalization, nor a separate mini-app.
- Targeted Repetition remains planned MM-02 work and is not implemented by
  this contract. Daily Mental Math and Mental Math Weak Skills also remain
  unimplemented.

### Entry and fixed configuration

- The v2 Free Practice flow is **Quick Practice operation/mechanic -> Practice
  Style -> Mental Math -> Number Type -> short 3-2-1 countdown -> Mental Math
  Gameplay -> Results**. It skips Config and Player Setup.
- The selected Quick Practice operation/mechanic remains authoritative. Number
  Type remains user-selectable: Natural Numbers, Integers, or Rationals /
  Decimals.
- Every v2 run is one-player, Choice4-only, Standard mode, with no user choice
  of Difficulty, Question Count, Timing Style, Adaptive, Deep Thinking, or
  Time Bank. The 40-question safety cap is internal, not a selector.

### Deterministic core loop

- A run begins at Momentum `0`, a 10.0-second question timer, and streak `0`.
  It ends at Momentum `+10` (**MASTERY REACHED**), Momentum `-10`
  (**PRACTICE COMPLETE**), or 40 completed questions (**TRAINING COMPLETE**).
- Correct, wrong, and actual gameplay timeout respectively add `+1`, `-1`, and
  `-1` Momentum; no completed question changes Momentum by more than one.
  Speed, streak, recovery, challenge zones, visuals, and bonuses never add
  Momentum.
- Correct answers add one streak; wrong and actual gameplay timeout reset it.
  Streak is feedback-only and never affects Momentum, timers, legality, score
  authority, or challenge-zone selection.
- The next-question timer begins at 10.0 seconds, changes by `-0.5` after a
  correct answer and `+1.0` after wrong or actual timeout, and is clamped to
  6.0--12.0 seconds. Unused time never rolls forward. Lifecycle interruption
  must not manufacture a wrong or timeout outcome.

### Challenge zones and canonical generation

- The deterministic Momentum mapping is: `-10..-4` Recovery/Easy,
  `-3..+3` Flow/Medium, `+4..+7` Challenge/Hard, and `+8..+9` Mastery/Hard.
  The Mastery zone may prefer richer legal canonical representations.
- The canonical generator remains final authority for operation/mechanic,
  Number Type, difficulty legality, representations, answers, distractors,
  RNG, and mathematical validity. v2 must not broaden canonical legality.
- `QuestionMechanic.missingOperation` remains operator-blank only:
  `number ? number = number`. It must never be transformed into missing
  operand/result, `missingNumber`, or `standard` without a separately approved
  future contract.

### Deferred Targeted Repetition contract

- Future MM-02 may enqueue a fact only after wrong or actual timeout; correct
  answers do not enqueue. A due follow-up needs at least two completed
  intervening questions, never extends the 40-question cap, and is not
  back-to-back when a normal legal question exists.
- It caps at two follow-ups per fact and three pending fact families; duplicate
  evidence merges. A correct follow-up resolves; a wrong first follow-up permits
  one final later follow-up; the second always drops. Illegal related requests
  decline to ordinary legal generation.
- A recovered fact may show **FACT RECOVERED**, with no extra Momentum or timer
  reward. Any Missing Operation follow-up preserves the operator-blank mechanic.

### Presentation, results, and exclusions

- The countdown may show **MENTAL MATH**, “Build your momentum”, “Reach +10 to
  master”, then 3, 2, 1, GO; it is not a settings page or long tutorial.
  Momentum `+9` and `-9` may show visual-only mastery/recovery cues.
- Results use the non-punitive terminal labels above. Recommended metrics are
  Peak Momentum, Best Streak, Accuracy, Average Response Time, Fastest Answer,
  and Facts Recovered. No second mastery system is created.
- Mental Math uses the player's globally selected Settings avatar with no
  Mental-Math-specific selector. The avatar is presentation-only: it may be
  prominent in countdown/results and subtle or omitted during active play; it
  never affects Momentum, timer, zones, canonical legality, Targeted
  Repetition, rewards, outcomes, GameBrain, or Adaptive.
- Continue using canonical skill mastery and history for ordinary learning
  outcomes, with no second mastery system. Suppress ordinary score/high-score
  ranking, Hall of Fame, coins/reward bonuses, power-up rewards, and new
  Mental-Math-specific achievements. Momentum, peak Momentum, streak, best
  streak, dynamic timer budget, completed count, terminal reason, and
  session-only metrics receive no new persistence schema.
- v2 core adds no coins, lives, power-ups, 50/50, score multipliers,
  achievements, new persistence system, GameBrain personalization, ML, or
  Adaptive behavior.
- Preserve the existing canonical AdMob policy: never show an interstitial
  during active gameplay; do not add Mental-Math-specific interstitial logic;
  retain completed-game cadence and `adsRemoved` behavior. No reward loop does
  not imply an ad exemption; any exemption needs a separate monetization
  contract.
- V2 implementation guards only legacy side effects that conflict with these
  rules. It must not broadly bypass `_endGame` or canonical persistence merely
  because the terminal condition is custom: preserve canonical mastery/history
  and AdMob behavior while suppressing incompatible ordinary score/reward/Hall
  of Fame behavior.
- Mental Math remains fail-closed out of P1-F01 evidence, GameBrain
  advisory/shadow eligibility, DecisionContext study, and QEO/context evidence
  paths. GameBrain remains central intelligence, not central authority.
