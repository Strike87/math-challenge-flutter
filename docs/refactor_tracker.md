# Math Challenge Refactor Tracker

Only the first unchecked item under **Active** may be started.

## Active

- [ ] V2-03A — Operation Quest Missing Number Trail
  - Corrected baseline: V2-02F Missing Operation is complete at
    `6 TRAILS • 18 STAGES`.
  - Target: `7 TRAILS • 21 STAGES`.
  - Approved question forms:
    - Easy: direct result only.
    - Medium: missing left or right operand only.
    - Hard: direct result, missing left operand, or missing right operand.
  - Reuse existing generated questions and choices; do not change
    `QuestionGenerator` production code.
  - Missing-dividend answers may use the generator's existing derived dividend
    ranges.
  - Existing overlap with ordinary Medium and Hard missing-operand arithmetic
    is intentional.
  - Concrete `Question.type` continues to drive history, mastery, achievements,
    adaptive-state records, and `division_10`.
  - Trail heading/icon: `🔢 Missing Number Trail`.
  - Stage labels, in order: `Find the Number`, `Number Detective`, and
    `Missing Number Master`.
  - Zero-star Hard copy: `Missing Number Master Complete`.
  - Cleared Hard copy: `Missing Number Trail Complete`.
  - Persistence remains `mc_operationQuestProgress` schema version 1.
  - Excluded: Regions, bosses, modifiers, True/False Quest, Written Answer,
    Integers, Decimals, Mixed Number Systems, Order of Operations, and
    Fractions.

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
- [x] R5 Step 2C — VERIFIED, no code change
  - The unsupported but publicly constructible `Survival + Master` branch is
    retained for executable-reference parity; any coherence guard requires a
    separate behavior-matrix audit and product decision.

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
