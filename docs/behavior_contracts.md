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
- Reuse the normal visual and navigation flow: **Number Type -> Config ->
  Player Setup -> Gameplay -> Results**. Do not create a separate mini-app.
  Unsupported choices remain visible-disabled where safe; visible-but-disabled
  is preferred to hidden.
- Reuse the canonical `10`, `15`, `20`, and `25` question-count selector. The
  chosen target is immutable; Targeted Repetition substitutes future questions
  and never adds turns or a separate length control.
- Supported operations are Addition, Subtraction, Multiplication, Division,
  and Mixed. Reuse canonical operation and question-generation ownership.
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
  gameplay, and Results surfaces.
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
