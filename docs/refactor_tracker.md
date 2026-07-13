# Math Challenge Refactor Tracker

Only the first unchecked item under **Active** may be started.

## Active

- [ ] R5 Step 2C — Survival hybrid-only scoring branch disposition audit
  - Type: audit only
  - Goal: determine whether the Survival+Master-only scoring branch should
    remain, be documented, be guarded against, or be proposed for later removal
  - Production edits: prohibited
  - Preserve:
    - executable-reference parity
    - scoring order
    - valid Survival behavior
  - Implementation: do not begin

## Completed

- [x] R3 CoinLedger
- [x] R3 DailyBonusPolicy
- [x] R3 NumberTypeUnlockPolicy
- [x] R4 adaptive global-level calculation
- [x] R4 primary mastery/confidence calculation
- [x] R4 adaptive difficulty thresholds
- [x] R4 secondary adaptive nudge
- [x] R5 SurvivalProgressionPolicy
- [x] R5 Step 2A — Survival scoring branch audit
- [x] R5 Step 2B — Survival scoring characterization
  - Verified evidence:
    - `test/survival_boss_event_test.dart` contains the valid Survival scoring
      characterization
    - Focused Survival tests: 2 passed
    - Question timer tests: 19 passed
    - Achievement tests: 10 passed
    - Full non-golden suite: 252 passed
    - Visual parity suite: 13 passed
    - `flutter analyze`: clean
    - `regression_reviewer` reported no confirmed findings

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
