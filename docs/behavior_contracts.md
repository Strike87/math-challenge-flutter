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
