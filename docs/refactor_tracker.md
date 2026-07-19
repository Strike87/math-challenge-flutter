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

- [x] V2-03C — Correct True/False proposition and disabled 50/50 badge
  - Display one complete proposition inside the question card.
  - Replace the existing question placeholder with the stored proposed answer.
  - Remove the detached proposed-answer line.
  - Keep the existing True and False buttons.
  - Keep 50/50 visible and disabled during True/False.
  - Hide the 50/50 quantity badge during True/False.
  - Do not consume or reset 50/50 inventory.
  - Returning to Choice4 must reveal the real inventory count.
  - Add `test/goldens/15_true_false_gameplay.png`.
  - Verification record:
    - Focused answer-style tests: 11 passed.
    - Focused gameplay/widget tests: 28 passed.
    - True/False golden test: 1 passed.
    - Full non-golden suite: 288 passed.
    - `flutter analyze --no-pub`: clean.
    - `git diff --check`: clean.
  - Preferred commit: `fix: correct True/False proposition and 50/50 disabled
    badge`.

- [x] V2-03D — Change the Operation Quest main-menu icon
  - Change only the main-menu Operation Quest card icon from `➕` to `🗺️`.
  - Keep the `Operation Quest` title and current campaign subtitle.
  - Do not change individual trail icons or the Operation Quest modal icon.
  - Implementation complete.
  - Verification record:
    - Focused menu visual tests: 2 passed.
    - Normal golden tests: 2 passed, covering 4 images.
    - Focused menu/navigation tests: 2 passed.
    - Full non-golden suite: 288 passed.
    - `flutter analyze --no-pub`: clean.
    - `git diff --check`: clean.
    - The four approved menu goldens were regenerated and remained
      byte-identical because the golden renderer maps both emoji to the same
      missing-glyph box.
    - Semantic assertions verify that `🗺️` is present and `➕` is absent.
  - Preferred commit: `ui: update Operation Quest menu icon`.

- [x] V2-03E — Add Missing Operation to Quick Practice
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
  - Implementation complete.
  - Verification record:
    - Missing Operation Quick Practice uses the shared `QuestionMechanic` path.
    - Ambiguity rejection is preserved.
    - Operator choices are randomized once per question, remain stable during
      rebuilds, and are graded by selected value.
    - Replay preserves the mechanic and generates a fresh question layout.
    - Finite-pool exhaustion safely reuses valid facts.
    - Natural, Integer, and Rational/Decimal forms are covered.
    - Existing 50/50 behavior is preserved.
    - Long-run and two-player coverage passed.
    - Full non-golden suite: 302 passed.
    - Visual suite: 16 passed.
    - `flutter analyze --no-pub`: clean.
    - `git diff --check`: clean.
    - Independent fallback regression reviewer passed under the `AGENTS.md`
      reviewer availability policy.
  - Preferred commit: `feat: add Missing Operation to Quick Practice`.

- [x] V2-03F — Quick Practice layout restructuring
  - Convert Mixed Operations from the separate full-width `_MixBar` into the
    sixth square `_PracticeCard`.
  - Place Mixed Operations beside Missing Operation so Quick Practice uses
    three rows of two cards:
    - Addition | Subtraction
    - Multiplication | Division
    - Missing Operation | Mixed Operations
  - Preserve the existing `goToConfig('mixed')` behavior and all existing
    gameplay and configuration behavior.
  - Remove obsolete `_MixBar` code if unused.
  - Update only directly affected tests and approved goldens.
  - Do not add Weak Skills Practice.
  - Do not reorder Master Challenge, Daily Boss, or Operation Quest.
  - Do not change `GameState`, generators, persistence, mastery, replay, or
    gameplay logic.
  - Expected production scope:
    - `lib/screens/menu_screen.dart`
  - Expected focused tests:
    - `test/missing_operation_practice_test.dart`
    - `test/visual_parity_test.dart`
  - Expected direct menu goldens:
    - `01_menu_phone_light.png`
    - `01_menu_phone_dark.png`
    - `02_menu_tablet_light.png`
    - `02_menu_tablet_dark.png`
  - Potential menu-backed modal goldens requiring separate adjudication:
    - `02b_operation_quest_map_phone.png`
    - `09_daily_boss_modal.png`
    - `12_coin_shop_modal.png`
    - `13_settings_modal_light.png`
    - `13_settings_modal_dark.png`
  - Do not update those modal goldens unless visual review proves the modal
    foreground and layout are unchanged and only the underlying menu or
    background changed.
  - Acceptance criteria:
    - Six square Quick Practice cards total, with two cards per row.
    - Missing Operation and Mixed Operations share the final row.
    - No duplicate Mixed Operations entry and no Missing Number card.
    - Existing tap and navigation behavior is preserved.
    - Responsive phone and tablet layout, light and dark rendering, and
      text-scale usability are preserved.
    - No unrelated behavior changes.
    - Mandatory parity and regression-reviewer gates pass.
    - Full required validation passes before commit.
  - Implementation complete.
  - Verification record:
    - Six square Quick Practice cards render as three rows of two cards.
    - Missing Operation and Mixed Operations share the final row.
    - Mixed Operations preserves `goToConfig('mixed')` navigation.
    - Missing Operation preserves `goToConfig('missingOperation')` navigation.
    - Responsive and text-scale coverage passed.
    - Full non-golden suite: 303 passed.
    - Visual suite: 16 passed.
    - `flutter analyze --no-pub`: clean.
    - `git diff --check`: clean.
    - Mandatory fallback parity gate passed under the `AGENTS.md` availability
      policy.
    - Independent fallback regression reviewer passed under the `AGENTS.md`
      availability policy.

- [x] V2-03G — Reorder main-menu challenge rows
  - Reorder the existing three main-menu challenge rows/cards to:
    1. Master Challenge
    2. Daily Boss
    3. Operation Quest
  - Preserve each existing widget/card implementation.
  - Preserve all existing callbacks and navigation targets.
  - Preserve Master Challenge behavior.
  - Preserve Daily Boss behavior, daily state, rewards, and challenge logic.
  - Preserve Operation Quest navigation, stars, trails, unlocks, and progress.
  - Do not change Quick Practice.
  - Do not add Weak Skills Practice.
  - Do not modify `GameState`, generators, persistence, mastery, achievements,
    adaptive logic, or gameplay.
  - Do not redesign the cards or rename titles or subtitles.
  - This is a presentation-order change only.
  - Expected production scope:
    - `lib/screens/menu_screen.dart`
  - Expected focused tests:
    - `test/visual_parity_test.dart`
    - Any existing menu/navigation test that explicitly checks challenge order.
  - Expected direct menu goldens:
    - `01_menu_phone_light.png`
    - `01_menu_phone_dark.png`
    - `02_menu_tablet_light.png`
    - `02_menu_tablet_dark.png`
  - Menu-backed modal goldens may also change because the reordered menu is
    visible through translucent or blurred overlays.
  - Do not pre-authorize modal golden updates; visually adjudicate each
    failure before updating it.
  - Acceptance criteria:
    - Master Challenge appears before Daily Boss.
    - Daily Boss appears before Operation Quest.
    - Final order is exactly Master Challenge, Daily Boss, Operation Quest.
    - All three existing navigation callbacks remain unchanged.
    - No challenge is duplicated or removed.
    - Quick Practice remains unchanged and no Weak Skills Practice is added.
    - Responsive phone/tablet and light/dark rendering remain valid.
    - No unrelated gameplay or progression behavior changes.
    - Mandatory parity gate passes before implementation.
    - Mandatory regression reviewer passes before commit.
  - Implementation complete.
  - Verification record:
    - Final order: Master Challenge → Daily Boss → Operation Quest.
    - Presentation-order-only change.
    - Existing Master Challenge navigation preserved.
    - Daily Boss dynamic and claimed-state behavior preserved.
    - Operation Quest navigation preserved.
    - 10px spacing between challenge cards preserved.
    - 20px spacing after Operation Quest preserved.
    - Quick Practice unchanged.
    - Full non-golden suite: 303/303 passed.
    - Visual suite: 16/16 passed.
    - `flutter analyze --no-pub`: clean.
    - `git diff --check`: clean.
    - Mandatory parity gate passed.
    - Independent fallback regression reviewer passed under the `AGENTS.md`
      reviewer availability policy.

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
