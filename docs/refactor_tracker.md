# Math Challenge Refactor Tracker

Only the first unchecked item under **Active** may be started.

## Active

- [ ] R5 Survival scoring branch audit
  - Type: audit only
  - Goal: determine whether the suspicious Survival scoring branch is
    unreachable, redundant, narrowly reachable, or behaviorally significant
  - Production edits: prohibited
  - Preserve:
    - Survival score
    - `+1` coin per correct
    - `+5` boss reward
    - achievements
    - persistence
    - all other mode scoring
  - Required result:
    - control-flow map
    - per-mode scoring table
    - reachability verdict
    - side-effect map
    - test-coverage report
    - smallest recommended next step

## Completed

- [x] R3 CoinLedger
- [x] R3 DailyBonusPolicy
- [x] R3 NumberTypeUnlockPolicy
- [x] R4 adaptive global-level calculation
- [x] R4 primary mastery/confidence calculation
- [x] R4 adaptive difficulty thresholds
- [x] R4 secondary adaptive nudge
- [x] R5 SurvivalProgressionPolicy

## Deferred

- Rewarded-ad orchestration
- IAP delivery and deduplication
- Shop transaction restructuring
- Persistence transactions
- Timer ownership
- Complete mode controllers
- Survival scoring restructuring pending audit

## Explicitly excluded

- Broad GameState decomposition
- Global ModeController
- Large module split
- Combining primary and secondary mastery updates
- Full localization
- Accessibility tasks 6-9
- Unrelated design-system cleanup
