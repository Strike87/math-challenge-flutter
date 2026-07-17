# Math Challenge Refactor Tracker

Only the first unchecked item under **Active** may be started.

## Active

- [x] V2-03A — Operation Quest Missing Number Trail
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

- [x] V2-03B — Stabilize interstitial lifecycle and navigation performance
  - Initialize Mobile Ads once.
  - Retain and asynchronously preload one ready interstitial.
  - Replay, Main Menu, and Operation Quest Map navigation must never wait for
    an interstitial to load.
  - Show an interstitial only when one is already ready; otherwise continue
    navigation immediately.
  - Clear the retained ad before showing it.
  - Dispose the consumed ad and asynchronously preload the next ad after
    dismissal or show failure.
  - Reset loading state after every load outcome.
  - Use bounded retry/backoff after load failure.
  - Prevent stale callbacks from showing an ad after gameplay resumes.
  - Preserve the every-three-completed-games policy.
  - Never show an interstitial during an active question.
  - Add diagnostic timing sufficient to measure remaining non-ad hitches,
    including end-game, ad eligibility/show/dismissal, replay, Quest Map,
    persistence, modal creation, and route/state-transition boundaries.
  - Physical-device timing smoke remains required before claiming full
    performance verification.
  - Implementation complete; device verification still required.
  - Verification record:
    - Focused AdMob tests: 25 passed.
    - Focused replay/navigation tests: 3 passed.
    - Full non-golden suite: 286 passed.
    - `flutter analyze --no-pub`: clean.
    - `git diff --check`: clean.
  - Preferred commit: `fix: stabilize interstitial lifecycle and navigation
    performance`.

- [ ] V2-03C — Correct True/False proposition and disabled 50/50 badge
  - Display one complete proposition inside the question card.
  - Replace the existing question placeholder with the stored proposed answer.
  - Remove the detached proposed-answer line.
  - Keep the existing True and False buttons.
  - Keep 50/50 visible and disabled during True/False.
  - Hide the 50/50 quantity badge during True/False.
  - Do not consume or reset 50/50 inventory.
  - Returning to Choice4 must reveal the real inventory count.
  - Add `test/goldens/15_true_false_gameplay.png`.
  - Preferred commit: `fix: correct True/False proposition and 50/50 disabled
    badge`.

- [ ] V2-03D — Change the Operation Quest main-menu icon
  - Change only the main-menu Operation Quest card icon from `➕` to `🗺️`.
  - Keep the `Operation Quest` title and current campaign subtitle.
  - Do not change individual trail icons or the Operation Quest modal icon.
  - Preferred commit: `ui: update Operation Quest menu icon`.

- [ ] V2-03E — Add Missing Operation to Quick Practice
  - Add Missing Operation as the fifth Quick Practice card.
  - Do not add Missing Number.
  - Use the same ordinary configuration flow as the existing practice cards.
  - Enable:
    - Natural, Integer, and Rational/Decimal number types.
    - Easy, Medium, and Hard difficulties.
    - Standard, Blitz, Death, Survival, and Combo modes.
    - One player.
    - Two players where existing configuration rules permit.
    - Choice4.
    - `10`, `15`, `20`, and `25` questions.
    - Existing adaptive-difficulty availability.
    - Ordinary replay and high-score behavior.
  - Disable True/False for Missing Operation.
  - Never write Operation Quest stars or progress.
  - Preserve concrete-operation credit for history, mastery, adaptive records,
    achievements, and `division_10`.
  - Promote `OperationQuestQuestionMechanic` to shared `QuestionMechanic`.
  - Add `lib/features/gameplay/domain/question_mechanic.dart`.
  - Rename the run-snapshot field to `questionMechanic`.
  - Move the existing Missing Operation transformation and operator mapping
    into the shared gameplay domain; do not duplicate Quest logic.
  - Extend the shared transformer safely for Integer and Rational/Decimal
    forms.
  - Do not add a new `Operation`, `GameMode`, `GameRunType`, or `AnswerStyle`.
  - No persistence migration.
  - Keep the two-column Quick Practice grid.
  - Center the fifth card while keeping the same card width.
  - Fit long practice-card labels safely at high text scale.
  - If Integer or Rational/Decimal support requires an unapproved architecture
    expansion, mark this task BLOCKED rather than silently disabling them.
  - Preferred commit: `feat: add Missing Operation to Quick Practice`.

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
