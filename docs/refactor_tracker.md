# Math Challenge Refactor Tracker

Only the first unchecked item under **Active** may be started.

## Closed temporary exception — Target Clash V5.5-A CI lint repair

- **Task ID:** TC-V55A-LINT-01
- **Status:** **CLOSED / EXPIRED / NON-REUSABLE** (2026-11-22, Africa/Cairo). The previously reviewed bounded TC-V55A-LINT-01 exception has been consumed by the merged lint repair and grants **no further implementation, acceptance, merge, or release authority**; it does not retroactively authorize the original out-of-order change.
- **Owner authorization:** 2026-11-21 (Africa/Cairo), documented in [PR #100 discussion](https://github.com/Strike87/math-challenge-flutter/pull/100#issuecomment-7053503322). Owner scope approval is not an independent review PASS.
- **Governance review:** PASS — `/root/goldfish_pr102_recovery_review`, fresh independent read-only context, reviewed `c95e40f875977b1fdb44edf9ac11da7d10521dcf`, timestamp 2026-11-21T13:07:22+02:00. This review applies to the corrected inactive amendment; any later scope or wording change requires re-review.
- **Historical governance violation:** PR #100 commit `bb8735179dd22e5937d245f25029948e7bd0a91a` was pushed before this exception received independent Goldfish PASS. That out-of-order action is retained as a historical governance violation and is **not** retroactively authorized. It was acceptance-blocked until the independently reviewed rollback/replay and final owner-approved merges; its historical violation status remains unchanged.
- **Required ordering (historical; no reuse):** independent fresh-context Goldfish PASS, owner confirmation and recorded bounded activation were required before the governed replay. These gates were documented for the completed work only; the closed exception cannot authorize another implementation or replay. Passing CI never substitutes for review.
- **Former bounded permitted task (completed; not a new authorization):** correct the existing `avoid_print` and `prefer_interpolation_to_compose_strings` findings in `test/target_clash_v55a_difficulty_matrix_test.dart` at the `TARGET_CLASH_V55A_MATRIX` log statement. Preserve the machine-readable prefix, JSON schema, 36 configuration observations, and every assertion.
- **Explicit exclusions:** no production code, gameplay or scoring, question generation, difficulty formulas, other test files, goldens, CI workflow, GameBrain, persistence, or release change. No automatic merge of [PR #100](https://github.com/Strike87/math-challenge-flutter/pull/100).
- **Ordering and authority:** this is a one-off exception request outside the first-unchecked-Active gate. **GBI remains the first unchecked Active item** with unchanged order, status, and gameplay authority. No general out-of-order authorization is granted.
- **Safe rollback/replay (completed):** the original provisional patch `bb8735179dd22e5937d245f25029948e7bd0a91a` was reversed non-destructively in `c046bce716efe7b651fb902715b2bef3ab68f9a4` and the reviewed lint-only correction was replayed in `bc7db33d6397e3d2e2ba92d71b7402faa84af6f6`, retaining the historical audit trail. Original procedure: before activation, preserve the original matrix commit and verify the provisional lint diff. If the exception is rejected or review remains blocked, leave PR #100 unaccepted and either revert only the lint commit with a non-destructive inverse commit or close the workstream without rewriting history. After activation, replay the identical lint-only change from a clean branch/worktree, compare the replay diff to the historical patch, and stop if unrelated files or behavior differ. Never force-push or reset shared history.
- **Acceptance gates (historical):** independent governance PASS and recorded activation; no unrelated PR #100 edits; focused Target Clash tests; applicable non-golden regression; visual parity without golden updates where evidenced; `flutter analyze`; diff checks; independent final regression review PASS; tracker reconciliation; and separate owner merge approval. **No new claim** is made that post-merge CI separately reran visual parity.
- **Lifecycle:** `PROPOSED` → `GOVERNANCE_REVIEW_PENDING` → `ACTIVE` after recorded PASS and owner confirmation → **`CLOSED / EXPIRED`** after owner-approved acceptance and merges. This exception **cannot be reused**. Its closure changes no item under `Active`; **GBI remains the first unchecked Active item**.
- **Closure evidence:** [PR #102](https://github.com/Strike87/math-challenge-flutter/pull/102) merged as `63d8ea410741f236c54625cd552837ec4ccc4ff2`; [PR #100](https://github.com/Strike87/math-challenge-flutter/pull/100) merged as `130113359603efa9c68205997904c5c0d26220ae`. External independent fresh-context governance and regression PASS were reported by the owner (not GitHub-native approvals); [post-merge Flutter and VM guard CI](https://github.com/Strike87/math-challenge-flutter/actions/runs/44952145408) succeeded. The [separate read-only closure-design audit](https://github.com/Strike87/math-challenge-flutter/pull/102#issuecomment-7069905930) returned PASS, reviewed `main` `130113359603efa9c68205997904c5c0d26220ae`; the owner confirmed that review used a separate new ChatGPT conversation and approved this bounded two-document implementation. This does **not** claim device acceptance, separate visual-parity PASS, or release.


## Active

- [x] BRAIN-06 — Offline synthetic-learning research tooling (CLOSED)
  - Terminal result: **MET — IRREDUCIBLE OBSERVABLE OVERLAP**. No additional
    BRAIN-06 synthetic decoder research is authorized.
  - The BRAIN-06 termination result establishes irreducible observable
    overlap only under the frozen E3-P synthetic response process and the
    observable channels modeled in that program, principally correctness,
    submitted response, and mathematical context. It does not establish the
    magnitude or inevitability of such overlap in real learners or under
    additional empirically validated observable channels.
  - Historical synthetic measurements from the separately preserved research
    lineage remain archival findings. Closure does not turn them into human
    calibration, production efficacy, diagnostic truth, or an authorization
    for E3 decoder use.
  - No production inference, app integration, real-user collection, export,
    persistence, upload, telemetry, or behavioral change was authorized.

- [x] BRAIN-07A — Context Evidence Advisory Production Contract
  - Documentation/contract work complete:
    `docs/brain_07_context_evidence_advisory_contract.md`.
  - It authorizes no production implementation, real-player observation
    collection, telemetry, or advisory release.

- [x] BRAIN-07B — Local shadow-only context-evidence observer
  - Implementation complete.
  - Verification record:
    - Added immutable direct-numeric context observations and explainable
      `insufficientEvidence` results behind the existing `GameBrain` facade.
    - Context evidence uses a separate bounded in-memory FIFO with capacity
      `10`; unsupported contexts are reported and not recorded.
    - `GameState` observes each completed supported question once after
      authoritative answer, mastery, adaptive, effect, and turn bookkeeping.
    - New runs and Replay start fresh observer windows; quit, Quest-map return,
      and reset discard the run-local observer.
    - Legacy GameBrain policies remain isolated, related-context evidence does
      not propagate, and no gameplay, persistence, Weak Skills, routing, UI,
      analytics, or diagnostic authority was added.
    - Focused context-evidence tests: 17/17 passed.
    - Full non-golden suite: 640/640 passed.
    - Visual parity suite: 38/38 passed.
    - `flutter analyze --no-pub`: clean.
    - `git diff --check`: clean.
    - Independent regression review passed.

- [x] BRAIN-07C — GameBrain v1 core validation and closure
  - Independently validated the BRAIN-07B shadow observer against the
    BRAIN-07A production contract.
  - Closure findings:
    - The only production call is post-authoritative answer processing; its
      immutable advisory result is retained only for diagnostics and discarded.
    - Supported evidence is restricted to normal, standard, basic-operation,
      Choice4 direct-numeric runs. Master, Daily Boss, Operation Quest,
      missing-operation, missing-number, True/False, and other unsupported
      contexts yield explicit `unsupportedContext` and are not recorded.
    - Context evidence remains local, immutable at its public boundary,
      FIFO-bounded to 10, non-persistent, non-propagating, and reset for new
      runs and replay.
    - No gameplay authority, synthetic threshold transfer, learner-truth
      vocabulary, analytics, telemetry, or privacy expansion was found.
  - A validation defect was fixed: normal True/False answers were previously
    able to enter the direct-numeric observer after conversion to a numeric
    choice. The support discriminator now requires `Choice4`; regression
    coverage confirms True/False is unsupported and unrecorded.
  - Verification record:
    - Focused context-evidence GameState test: 10/10 passed.
    - Full non-golden suite: 641/641 passed.
    - Visual parity suite: 38/38 passed.
    - `flutter analyze --no-pub`: clean.
    - `git diff --check`: clean.
    - Independent regression review passed.

- [x] GAMEBRAIN v1 CORE — COMPLETE
  - This closes the bounded core evidence/advisory architecture only. It does
    not authorize GameBrain to affect gameplay or mean that all gameplay
    systems are integrated.
  - Frozen integration principle: GameBrain may influence gameplay only through
    an explicit subsystem/mode adapter that enforces the authoritative domain
    contract; never through direct `GameState` mutation.

- [ ] GBI — GameBrain integration (INCREMENTAL AUTHORIZATION ONLY)
  - Each concrete integration requires separate approval. GBI-01 remains
    shadow-only and grants GameBrain no gameplay authority.
  - [x] GBI-00 — GameBrain integration architecture contract
    - Documentation-only contract complete:
      `docs/game_brain_integration_architecture.md`.
    - It freezes Core evidence/advisory ownership, GBI-owned gameplay
      interpretation, capability/constraint boundaries, fail-closed decisions,
      and candidate mode envelopes. It authorizes no production
      implementation, gameplay integration, telemetry, persistence, UI, or
      behavior change.
  - [x] GBI-01 — SHADOW ADAPTIVE INTEGRATION FOUNDATION
    - Added a pure GBI-owned interpretation boundary from the frozen public
      context-evidence advisory to an immutable adaptive integration decision.
    - `insufficientEvidence`, unsupported contexts, missing capability, illegal
      constraints, and unsupported proposals fail closed to `noAdaptation`.
    - Execution authority is permanently denied. `GameState` evaluates once
      after GameBrain observation and discards the decision without changing
      Adaptive Difficulty, mastery, confidence, next difficulty, or gameplay.
    - GameBrain Core and the Adaptive Difficulty engine remain unchanged.
    - No modes, UI, persistence, telemetry, synthetic research logic, or second
      integration were added or authorized.
    - Verification record:
      - Focused GBI-01 and GameState shadow-firewall tests: 18/18 passed.
      - GameBrain, Adaptive Difficulty, and relevant GameState tests: 109/109
        passed.
      - Full non-golden suite: 649/649 passed.
      - Visual parity suite: 38/38 passed.
      - `flutter analyze --no-pub`: clean.
      - `git diff --check`: clean.
      - `graphify update .`: passed; generated churn remains uncommitted.
  - [x] GAMEBRAIN REAL GAMEPLAY AUTHORITY GATE — documentation/governance
    - Frozen the prerequisites for any future conceptual
      `mayAffectGameplay = true` request; research findings, architecture
      prerequisites, and implementation work remain distinct.
    - Every authority request requires explicit review against all applicable
      requirements and fails closed to `noAdaptation` while any requirement is
      unresolved.
    - Completing this documentation task passes no subsystem gate, grants no
      gameplay authority, collects no data, and changes no production code.
      GBI-01 remains complete and valid only as shadow-only discarded
      interpretation.
  - Remaining candidate adapters (all separately unauthorized): GBI-02
    Adaptive Difficulty; GBI-03 Question Generator Intent; GBI-04 Distractor
    Generator; GBI-05 Weak Skills; GBI-07 constrained mode integrations
    (Standard, Blitz, Combo, Death, Survival, Master, Daily Boss, Operation
    Quest, and separately constrained two-player).
  - [x] GBI-06 — SKILL DASHBOARD SHADOW READ INTEGRATION
    - Shadow-only, test-observed read composition; no actual Skill Dashboard
      UI integration and no gameplay authority.
    - Canonical mastery remains authoritative. Public immutable GameBrain
      context evidence is optional enrichment and cannot overwrite or infer
      canonical mastery.
    - No GameBrain Core, Weak Skills policy/scheduling, GameState, persistence,
      telemetry, or P0 changes. `mayAffectGameplay = false`.

- [x] EV-01 — Skill Dashboard difficulty-evidence feasibility audit
  - Complete. Outcome: `CLAIM_NOT_SUPPORTED_NOW_BUT_VALIDATABLE`.
  - The target claim remains unimplemented and requires separately approved,
    bounded empirical validation before any production discussion.

- [x] EV-02 — Run-bounded difficulty-evidence validation protocol
  - **DESIGN FROZEN.** Execution is **NOT AUTHORIZED**.
  - `docs/game_brain_ev02_validation_protocol.md` freezes one bounded pilot,
    a small pre-registered candidate-rule family, independent held-out
    reference performance, and three terminal outcomes.
  - Execution parameters remain intentionally unset until pre-study
    authorization. No EV-03 is authorized.
  - P0 remains dormant and `mayAffectGameplay = false`.

- [x] BRAIN-01 — Pure GameBrain foundation
  - Add immutable, canonical-value snapshots and a deterministic, shadow-only
    domain decision policy behind the canonical newer modular `GameBrain`
    facade.
  - Keep bounded, read-only in-memory observations with a default capacity of
    `10`.
  - Expose only a generic, tentative opaque hypothesis after two matching,
    caller-supplied nonblank evidence tags for the same operation; evidence is
    retained verbatim and equal-count ties use deterministic insertion order.
  - No BRAIN-02 work, production integration, persistence, generator calls, or
    behavior changes are authorized in this foundation step.
  - Verification record:
    - Dart formatting changed GameBrain files cleanly.
    - Focused canonical GameBrain tests: 13 passed.
    - Adaptive engine and adaptive integration tests: passed.
    - Weak Skills policy and practice tests: passed.
    - Question generator tests: passed.
    - Full non-golden suite: 578 passed.
    - Visual parity suite: 38 passed.
    - `flutter analyze --no-pub`: clean.
    - `git diff --check`: clean.
    - `graphify update .`: passed; generated churn excluded.
    - Independent fallback regression reviewer passed because the configured
      reviewer was unavailable.

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

- [x] V2-03H — Weak Skills Practice
  - Add a full-width Quick Practice row beneath the six existing square cards.
  - Preserve the existing three-row, two-column square-card layout unchanged:
    - Addition | Subtraction
    - Multiplication | Division
    - Missing Operation | Mixed Operations
  - Display icon `🧠+` and title `Weak Skills Practice`.
  - Use only the existing canonical mastery data; do not create a second
    mastery or progression system.
  - Personalize practice around canonical operations that need more practice,
    and explain the selected focus to the player rather than silently
    reassigning operations.
  - Require sufficient evidence before classifying an operation as weak.
  - Lock the selected focus for the entire round.
  - Replay preserves the same focus and weighting.
  - Starting a genuinely new Weak Skills Practice run recalculates focus from
    the latest mastery data.
  - Inherit the player's normal Quick Practice number-type selection.
  - Preserve normal difficulty and other supported configuration choices.
  - Never write Operation Quest stars or progress.
  - Do not add a new currency or unlock system.
  - Existing mastery, achievements, history, adaptive updates, and scoring
    must continue through canonical paths.
  - V1 policy, subject to the mandatory pre-implementation audit:
    - Rank only Addition, Subtraction, Multiplication, and Division.
    - Use existing canonical operation mastery values.
    - Do not create Operation × Number Type mastery unless the audit proves
      that segmentation already exists canonically.
    - The player continues to choose or inherit the normal Quick Practice
      number type.
    - Candidate evidence threshold:
      - At least `10` total tracked answers.
      - At least `3` tracked attempts for an operation before it is eligible
        for weakness ranking.
    - Use balanced fallback practice across all four operations when evidence
      is insufficient.
    - Do not manufacture weakness from effectively tied mastery values.
    - Also use balanced fallback when fewer than two operations are eligible,
      all eligible operations have equal mastery, or the mastery spread is too
      small to represent a meaningful weakness.
    - Do not hard-code a meaningful-spread threshold until the audit confirms
      the mastery scale and existing conventions. The previously discussed
      `5`-point candidate is not approved without audit evidence.
    - Candidate focused weighting is `65%` primary weak operation and `35%`
      secondary weak operation. This is tunable V1 product policy, not a
      permanently frozen learning constant.
    - If two operations tie for the weakest eligible position, select both
      when possible.
    - If a tie affects only the second focus position, use an existing
      deterministic canonical operation order. Do not invent ordering before
      the audit.
    - New start from the menu/configuration calculates focus exactly once;
      active play keeps it locked; Replay preserves it; exiting and starting a
      new run recalculates it.
    - Live mastery updates during a round must not change its operation mix.
    - The run snapshot should own enough information to preserve focus across
      the round and Replay, subject to architecture audit.
    - Explain focused selection with supportive language such as
      `Recommended focus` and `Based on your practice history`.
    - Explain fallback with supportive language such as
      `Building your practice profile` and
      `This round will include all four operations.`
    - Avoid negative language such as `bad at`, `worst skill`, and `failed`.
    - End-of-round feedback may show improvement in targeted operations using
      existing mastery data, but must not create a separate Weak Skills score
      or mastery system.
    - Weak Skills Practice may contribute toward existing achievements through
      normal mastery paths only. Do not grant bonus mastery, special
      achievement credit, or achievement shortcuts.
  - Permanent product governance:
    - Every new feature must improve learning or motivation.
    - Progression must remain understandable and rewarding.
    - Quality and stability are more important than adding features quickly.
  - The completed read-only architecture/data audit confirmed:
    - Canonical mastery scale and default mastery values.
    - Exact mastery ownership and state location.
    - Per-operation attempt-count availability.
    - Whether total answer count already exists.
    - Whether mastery is operation-only or segmented by number type.
    - Canonical operation ordering.
    - Current adaptive mastery update timing and whether mastery changes live
      after every answer.
    - Run snapshot architecture and Replay snapshot behavior.
    - Existing mixed-operation generation policy.
    - Available deterministic RNG and testing patterns.
    - Existing result-screen capability for showing before/after mastery.
    - Whether any persistence migration would actually be required.
    - The safest fallback, tie, and spread policy consistent with current data.
  - No implementation agent may invent missing behavior.
  - The architecture/data audit must determine and obtain approval for the
    smallest safe implementation scope; this entry does not lock exact files
    or authorize speculative architecture.
  - Likely audit areas may include menu presentation, run
    configuration/snapshot, a small Weak Skills selection policy, results
    feedback, and focused tests.
  - Acceptance criteria:
    - `🧠+` Weak Skills Practice appears as a full-width row beneath the six
      square Quick Practice cards.
    - The existing six Quick Practice cards remain unchanged.
    - Focus selection uses canonical existing mastery data with no parallel
      mastery system.
    - The player is told why a focus or fallback was selected.
    - Insufficient evidence does not label a player weak prematurely.
    - Focus remains fixed for the whole round, Replay preserves it, and a
      genuinely new start recalculates it.
    - Number-type behavior is explicit and testable.
    - Tie and insufficient-spread behavior is explicit and deterministic.
    - Existing mastery, history, achievement, adaptive, and scoring paths
      remain canonical.
    - No Operation Quest stars or progress are written.
    - Mandatory parity gate passes before implementation.
    - Mandatory regression-review gate passes before commit.
    - Full required validation passes before commit.
  - Implementation complete.
  - Verification record:
    - Weak Skills Practice `🧠+` implemented.
    - Existing canonical `skillMap` mastery reused with no parallel mastery
      system and no persistence migration.
    - Evidence thresholds: `10` total attempts and `3` attempts per operation.
    - Meaningful mastery spread threshold: `10` points.
    - Focused scheduling is deterministic: `65%` primary and `35%` secondary.
    - Weakest-operation ties use deterministic `50%` / `50%` scheduling.
    - Insufficient evidence uses a balanced four-operation fallback.
    - Focus is locked for the entire round; Replay preserves it, while a fresh
      start recalculates it.
    - Follow-up reinforcement does not consume Weak Skills schedule slots.
    - Single-player is enforced without changing the global player preference.
    - Number-type and answer-style behavior is preserved.
    - Canonical history, mastery, adaptive, and achievement paths are
      preserved.
    - Operation Quest progress remains isolated.
    - Focused policy tests: 4/4 passed.
    - Focused orchestration/UI tests: 6/6 passed.
    - Full non-golden suite: 313/313 passed.
    - Visual suite: 18/18 passed.
    - `flutter analyze --no-pub`: clean.
    - `git diff --check`: clean.
    - `graphify update .`: passed; generated churn excluded.
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

## Proposed temporary exception — MD3-UX-02 B1-F footer text scaling

- **Task ID:** `MD3-UX-02-B1F-RECOVERY-01`. **Classification:** `CONTINUATION / Governance proposal`.
- **Status:** **PROPOSED / INACTIVE / NO IMPLEMENTATION OR MERGE AUTHORITY**. Even if this proposal is later merged, it does **not** activate out-of-order Flutter implementation, approve a historical local patch, or authorize any code PR, automatic merge, device build, or release.
- **Owner decision (scope limited):** 2026-11-22 (Africa/Cairo), project owner approved preparing this tracker-only proposal for review. **Explicit activation and implementation approval are not recorded by this document**; they require a subsequent decision under the gates below. Source: [Issue #103](https://github.com/Strike87/math-challenge-flutter/issues/103).
- **Design / proposed-exception review:** **PASS (owner-reported)**, separate fresh read-only reviewer context `/root/goldfish_md3_b1f_recovery_review`, read `main` `130113359603efa9c68205997904c5c0d26220ae` and tracker blob `751c523922463939970d3e67fe95b13a770bbd1a`; see [Goldfish evidence record](https://github.com/Strike87/math-challenge-flutter/issues/103#issuecomment-7070196724) and [V2 proposal](https://github.com/Strike87/math-challenge-flutter/issues/103#issuecomment-7069998898). Reviewer's exact model and terminal timestamp were **not supplied**; verify them from the isolated transcript before treating EGM Gate 2 provenance as complete. A design PASS is **not** an implementation-diff PASS.
- **Source / dependency (historical and current):** Original `main` baseline `130113359603efa9c68205997904c5c0d26220ae`; existing default menu footer uses `FittedBox(scaleDown)`, `maxLines: 1`, and `softWrap: false` in `lib/screens/menu_screen.dart` (blob `648e8312ef96040c7c3487ee4c4795a103bc336a`). **Historical branch base:** this inactive proposal was originally stacked on [PR #104](https://github.com/Strike87/math-challenge-flutter/pull/104) documentation-closeout HEAD `754edd35058c17dc04af4ac53766fcab4122bfc6` while the then-current `main` work register was stale. **Current base:** PR #104 was merged separately into `main` at `fb306ec18024135380946f61d85a82322b4e05cb` on 2026-11-22 (Africa/Cairo); PR #105 has been retargeted to that merged `main`, and this proposal remains **PROPOSED / INACTIVE**. **Do not merge this proposal, activate the exception, or implement Footer changes without verifying fresh `main`, the current PR diff, applicable CI, independent review and a separate explicit owner decision at each required gate; stop on drift.**
- **Authority boundary:** `GBI — GameBrain integration (INCREMENTAL AUTHORIZATION ONLY)` remains the **first unchecked Active item**. Its order, scope, status and gameplay authority are unchanged. This proposal grants no general exception to tracker sequencing or other MD3 slices.
- **Proposed allowed implementation ONLY after completed independent governance review of the actual tracker diff, separate owner approval of the amendment/activation, reconciliation and approved merge of PR #104, reviewed tracker PR merge, and explicit recorded activation:** change only the attribution Footer layout in `lib/screens/menu_screen.dart` to remove shrink-to-fit and permit wrapping; add or update only `test/menu_screen_footer_text_scale_test.dart` to verify the bounded accessibility behavior. The original local candidate is review-only, not already authorized.
- **Acceptance contract:** at logical 320×568 and 390×844, DPR=1 and text scales 1.0, 1.5, 2.0, preserve the exact attribution, central alignment, style/color and existing menu controls; no Flutter layout exception, overflow, clipping, ellipsis, or regression. At 2.0× on **both** widths, verify **at least two actual visible lines** using the rendered paragraph's line metrics (not widget-height growth alone). Scroll the **actual** enclosing `SingleChildScrollView` to the footer, then assert full visibility within the usable `SafeArea` rectangle including bottom spacing. Load and measure the **production-resolved** font from `AppTheme` (`PlusJakartaSans` by default; respect `OpenDyslexic` if that setting is in scope); do not silently use fallback font metrics.
- **Verification / visual parity:** focused and responsive widget tests; repeatably passing full non-golden suite with raw commands, exit codes and logs; `flutter analyze`; changed-file inventory; `git diff --check`; baseline/candidate visual parity evidence with the same Flutter/Dart/lockfile and fonts, **without `--update-goldens`**. The existing `Operation Quest` expectation may be called `BASELINE_REPRODUCED` **only** if the same failure is observed independently in baseline and candidate; record any new regression separately. Deliberate golden differences need separate owner authorization.
- **Unresolved historical tests:** local focused B1-F tests were reported to pass; a candidate full-suite timeout was intermittent and its root cause is **UNKNOWN**. Isolated reruns do not prove `ENVIRONMENT_ONLY` or full-suite acceptance. Post-merge `main` CI for unrelated Target Clash work is not B1-F candidate evidence.
- **Explicit exclusions:** no gameplay, scoring, timers, adaptive difficulty, generators, `GameState` decomposition, GameBrain runtime, persistence/reset, navigation behavior, ads/IAP, family/privacy, unrelated tests, golden files, new font/assets, SDK/lockfile, CI workflow, device acceptance or release.
- **Safe rollback / isolation:** retain the historical local B1-F patch and worktrees without rewriting shared history; after activation, work from a clean verified `main` on a separate bounded implementation branch. If blocked, leave the implementation unstarted. A subsequent revert must be non-destructive and preserve this audit trail; never force-push or reset a shared ref.
- **Lifecycle / next permitted action:** `PROPOSED` → `GOVERNANCE_REVIEW_PENDING` → owner-approved documentation merge with **INACTIVE** state → independently verified activation decision → `ACTIVE` for this bounded task only → final independent regression review, CI and **separate owner merge approval** → `CLOSED`/`EXPIRED` or `BLOCKED`. Scope is non-reusable. **Next action now: review this inactive one-file tracker diff; do not modify Footer code or activate the exception.**

## Temporary exception — TC-V55B Triple permutation test matrix (ACTIVE ONLY AFTER REVIEWED MERGE)

- **Task ID:** `TC-V55B-TRIPLE-MATRIX-TEST-01`. **Classification:** `CONTINUATION / TEST-ONLY GOVERNANCE PROPOSAL`; strictly separate from MD3 B1-F and the closed V5.5-A lint exception.
- **Status / effective authority:** **ACTIVATION PROPOSED FOR REVIEW — NOT ACTIVE ON `main` UNTIL THE ACTIVATION DIFF IS INDEPENDENTLY REVIEWED AND OWNER-APPROVED FOR MERGE.** This proposed status transition becomes **`ACTIVE / BOUNDED TEST-ONLY / SINGLE-USE` only upon a verified, separately authorized merge of this exact activation PR**. On the source branch and while review is pending, there is **NO TEST IMPLEMENTATION AUTHORITY**. Once effective, the exception is restricted to the single test file below and expires on closure, rejection or withdrawal; it cannot be reused for another Target Clash task.
- **Owner authorizations and provenance:** (1) On 2026-11-22 (Africa/Cairo), owner authorized Option A to prepare the original **INACTIVE documentation proposal**; that proposal was reviewed and separately owner-approved for merge in [PR #108](https://github.com/Strike87/math-challenge-flutter/pull/108). (2) On 2026-11-22, owner later explicitly approved **both pursuing activation and writing the bounded TC-V55B tests**, recorded verbatim in [Issue #107 owner decision](https://github.com/Strike87/math-challenge-flutter/issues/107#issuecomment-7079512443). This is precise owner approval for the bounded work **subject to the pre-existing mandatory Goldfish review, activation merge, and final implementation merge gates**; it does not itself merge an unreviewed branch.
- **Verified baseline and sources:** current pre-activation `main` **`923b095349be22bb7a1072e89497986f397ec292`**, PR #108 merged docs-only; [post-merge main CI 45024539724](https://github.com/Strike87/math-challenge-flutter/actions/runs/45024539724) **COMPLETED / SUCCESS** on that SHA (baseline only). Target Clash generator blob `41e12473cf4bfb07327e1c0d79f8c7f75583574f`, runtime blob `9ace1e3646fad3c485d029e84613c8c583357684`, V5.5-A matrix blob `e93d939f7974b721afe433da7b75aa9b1e1e9a7e`. Mandatory [Issue #107 R1 specification](https://github.com/Strike87/math-challenge-flutter/issues/107#issuecomment-7070591871) and [consolidated activation contract](https://github.com/Strike87/math-challenge-flutter/issues/107#issuecomment-7079481557).
- **Authority boundary / precise exception:** `GBI — GameBrain integration (INCREMENTAL AUTHORIZATION ONLY)` **remains first unchecked `Active`**, unchanged. Only after independent review and **explicit owner-approved merge of this separate Tracker activation** does the narrow `TC-V55B-TRIPLE-MATRIX-TEST-01` exception become **ACTIVE** *outside* the ordinary queue for one test-only cycle; GBI's GameBrain runtime authority is not delegated. B1-F stays **PROPOSED / INACTIVE**. Historical `TC-V55A-LINT-01` stays **CLOSED / EXPIRED / NON-REUSABLE**. No other out-of-order work becomes authorized.
- **Implementation scope, conditional on this activation actually landing in `main`:** add **exactly one new test file** `test/target_clash_v55b_triple_permutation_matrix_test.dart` on a new clean branch from the activated `main`. Test-only; no changes to existing tests, any production Dart, Flutter UI, assets/goldens, CI workflows, dependencies or GameBrain. This approval is not authority to merge the future test PR without CI, independent implementation Goldfish and a distinct owner merge decision.
- **Bounded matrix / canonical Stage 2 profile:** 4 operations (addition/subtraction/multiplication/division) × 2 Triple-enabled difficulties (Medium/Hard) × 3 number types (natural/integers/rationals) × 6 `TargetClashRuntimeState.tripleRequests(0..5)!` permutations = **144 domain materializations**. Use one legal **ordinaryStage2** retained target preflight per each of 24 configurations via `TargetClashRuntimeState.resolveRequests(... phase: TargetClashRequestProfilePhase.ordinaryStage2)` and `futureRequests: TargetClashRuntimeState.tripleRequests(0)!`; freeze it before testing all six permutations with real `prepareStageForTarget`, checking atomic three-question success, requested ordered relations/zones/answers, typed lawful canonical facts, numerical correctness, and identical retained target. Easy never enters Triple.
- **Mandatory RNG limitation (R1):** state `DOES_NOT_PROVE_REAL_GAMESTATE_RNG_SEQUENCE_EQUIVALENCE` in the test/report. Independent fixtures per permutation isolate domain materialization, **not** the actual shared `_qgen` lifecycle or the run's `_rng.nextInt(6)` order. Real GameState RNG-sequence equivalence would need a **different separately scoped authorization**; no gameplay defect is presumed.
- **P1 resolved in the activation contract — deterministic seed scheme / failure handling:** fixed enumeration order operations `addition, subtraction, multiplication, division` × difficulties `medium, hard` × types `natural, integers, rationals`; `configIndex=1..24`, `permutationIndex=0..5`. Stage 2 preflight generator MUST seed **both** `QuestionGenerator(rng: Random(5500 + configIndex))` **and** `selectionRandom: Random(6500 + configIndex)` (V5.5-A-style); `prepareStage` otherwise draws target from an unseeded selection RNG. After freezing one legal target, use a fresh generator per permutation seeded **both** `QuestionGenerator(rng: Random(7500 + (configIndex - 1) * 6 + permutationIndex))` and `selectionRandom: Random(8500 + (configIndex - 1) * 6 + permutationIndex)`. Record all seeds/config/permutation/slot/target/failure and measured elapsed time. **No silent retries, replacement targets, RNG manipulation or production tuning**; failures remain `UNKNOWN_CAUSE / TEST_FINDING` pending deterministic reproduction. Exact choices shall be checked by the independent activation Goldfish.
- **Verification gates if later authorized:** focused domain test and relevant existing TC tests, full non-golden suite with exact pass/skip counts and raw logs, `flutter analyze`, `git diff --check`, one-file diff inventory, measured test duration, PR CI, and **new independent final implementation Goldfish**. Preserve V5.5-A's machine-readable 36-config matrix and intentionally skipped 36,000-case R3 stress test. Do **not** run the stress suite by default or update goldens.
- **Cross-feature impact / explicit exclusions:** no edits to `GameState`, math generator, gameplay difficulty, scoring, timer, Boss/Fever/reveal behavior, GameBrain/modes/adaptive authority, persistence/reset, ads/IAP, family/privacy, navigation/MD3/accessibility, performance-critical production logic, assets, SDK/lockfile, signing or release. CI/runtime effect is restricted to the additional **bounded test duration**, which must be measured.
- **Review provenance / open gates:** PR #108 Muse/Spark 1.3 Goldfish **PASS on the prior INACTIVE documentation diff only**, not on this activation diff; historical design-only reviews do not authorize execution. This separately scoped status change has **NO independent Goldfish decision yet**; reviewer identity/model/context/timestamp/verdict `PENDING`. No TC-V55B test or implementation CI exists. Record a genuine fresh-context review on exact activation HEAD before merging; full test runtime budget stays `UNKNOWN` until measured. `docs/egm/WORK_REGISTER.md` still cites historical main `1301133` and requires separately authorized later reconciliation.
- **Lifecycle / next permitted action:** `INACTIVE on main` → **ACTIVATION-PR DRAFT + independent READ-ONLY Goldfish review** of this exact Tracker diff → guarded **owner-authorized activation merge** (owner's explicit bounded activation instruction recorded; stop on new drift or reviewer BLOCKED/INCONCLUSIVE) → verify `ACTIVE` status on `main` and post-merge CI → **single new test file** implementation from clean activated main → focused/full regression CI, analyzer, time measurement and final independent implementation Goldfish → **separate owner authorization to merge test PR** → `CLOSED / EXPIRED` or `BLOCKED`. **Never treat this Draft branch or owner authorization alone as currently active authority.**
- **Rollback/isolation:** preserve current `main` and historical evidence. If the proposal is rejected, close this Draft without altering `main`; if future authorized test work fails, revert only the bounded test commit via normal history-preserving procedures, never force-push or reset shared refs.

## Proposed governance recovery — PR #110 one-time Goldfish exception (INACTIVE; NOT AN IMPLEMENTATION AUTHORIZATION)

- **Task ID:** `TC-V55B-REVIEW-RECOVERY-01`. **Classification:** `CONTINUATION / GOVERNANCE-ONLY / PROPOSED`. **Owner authorization:** 2026-11-22 (Africa/Cairo), approved preparation of the limited governance proposal and subsequent documentation-only Draft PR; **not** governance activation, implementation review, PR #110 merge, production behavior or release.
- **Current status:** `PROPOSED / INACTIVE / NOT INDEPENDENTLY REVIEWED / NOT MERGED / NOT ACTIVATED`. The active, already merged TC-V55B *test-only* authority remains distinct. `GBI` remains the first unchecked `Active` tracker task; no queue reordering or other exception is created.
- **Exact scope:** [PR #110](https://github.com/Strike87/math-challenge-flutter/pull/110) fixed base `e87d623391f05e219c350366713d5f8569ba6120` and HEAD `e2f3d300996fa120e1b05ab3026f60b7f1559f70`; original [frozen one-review contract](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7079802240). New proposed rules are recorded exclusively in [PR110_GOLDFISH_RECOVERY_ADDENDUM.md](egm/PR110_GOLDFISH_RECOVERY_ADDENDUM.md); this Tracker entry **does not itself override** the frozen contract.
- **Why proposed:** First Muse implementation review `INCONCLUSIVE` (original GitHub Actions raw logs inaccessible and isolation not established), later standalone governance preflights `BLOCKED` due to `ONE_REVIEW_PER_UNCHANGED_HEAD`. Owner-exported original Push/PR Flutter job archives are now available. Preserve every historical review decision; no PASS is inferred from archives, CI, coordinator evidence or this proposal.
- **Activation gate:** only if a **fresh independent governance Goldfish `PASS` on the exact two-document governance diff**, a **separately owner-approved governance merge**, a verified actual merge into `main`, then **distinct explicit project-owner authorization for activation** and a verifiable activation record (named approver/authority, timestamp and time zone, exact one-review scope, PR #110 base/HEAD, PR #111 reviewed HEAD and verified merge SHA, permanent owner-decision evidence link or dated verbatim source, and one-use expiry) all complete, may the addendum prospectively authorize **one** further independent read-only implementation Goldfish review of the unchanged PR #110 HEAD. If any gate is missing, stop `BLOCKED` or `INCONCLUSIVE`; no retry.
- **One-use / no merge authority:** the replacement review must independently inspect primary source and complete original owner-exported Push/PR logs in a genuinely isolated context, document model and provenance, and consume its one-time opportunity on `PASS`, `BLOCKED` or `INCONCLUSIVE`. An accepted technical `PASS` still requires **separate explicit owner merge approval** for PR #110 and does not authorize build/release. The candidate SHA is not to be changed cosmetically to evade review rules.
- **Permitted docs-only proposal diff:** this new Tracker entry and `docs/egm/PR110_GOLDFISH_RECOVERY_ADDENDUM.md` only. **Exclusions:** `AGENTS.md`, `docs/egm/WORKFLOW.md`, existing review comments/history, source/test code, product or GameBrain, golden files, dependencies, CI, credentials, privacy, builds, releases, and automatic merges.
- **Next permitted action:** inspect exact Draft governance PR diff, then obtain genuinely independent read-only governance review. **Do not** conduct the replacement PR #110 implementation review or merge either PR until their respective gates complete.

## Proposed PR #110 bounded final-review fallback (INACTIVE; GOVERNANCE ONLY)

- **Task:** `TC-V55B-PR110-FALLBACK-01`; **classification:** `CONTINUATION / PROPOSED / DOCS-ONLY`; **authority:** owner requested preparation of an alternative after repeated documented independent-review eligibility failures. This does **not** authorize executing fallback, changing code or merging PR #110.
- **Specific exception candidate:** [PR #110](https://github.com/Strike87/math-challenge-flutter/pull/110), base `e87d623391f05e219c350366713d5f8569ba6120`, HEAD `e2f3d300996fa120e1b05ab3026f60b7f1559f70`, one new **test-only** file (+199/-0), no production changes. GBI remains first unchecked `Active`; all TC-V55B design, RNG limitations and technical acceptance requirements remain mandatory.
- **Background / current gate:** [PR #111](https://github.com/Strike87/math-challenge-flutter/pull/111) merged the independent-review recovery addendum at `97cbe7066f07e53bee8c705b25ac9e292aca07ec`, later activated for one independent implementation review in [comment 7084820892](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7084820892). Additional eligibility-only preflights remained `INCONCLUSIVE` (model identity or cleanroom memory isolation). They did not become implementation PASS, and repeated preflight retries are paused. Under current effective governance, the **mandatory independent final review remains unmet**, and a general `AGENTS.md` fallback does not silently supersede the frozen PR #110 contract.
- **Proposed limited prospective override:** Appendix §7 of [PR110_GOLDFISH_RECOVERY_ADDENDUM.md](egm/PR110_GOLDFISH_RECOVERY_ADDENDUM.md) proposes, **only after separately reviewed, owner-approved governance merge and a distinct explicit post-merge owner activation**, one read-only `OWNER_AUTHORIZED_BOUNDED_FALLBACK_AUDIT / NON_INDEPENDENT` in place of the final independent implementation review **for this one fixed test-only PR**. This proposal cannot be described as `Goldfish PASS` or taken as authorization to merge. The previously activated independent-review slot would be recorded `PAUSED / SUPERSEDED` at fallback activation, not reused as a retry loophole.
- **Fallback evidence requirement:** directly examine the original full Push/PR logs, 144 row permutations and dual seeds, source contracts and MathFact/zone/distance assertions, real test limits, V5.5-A 36 cases, non-golden suite 1439/2 skips, analyzer, VM guard, potential P0–P3, and missing validation, with exact reproducible provenance. A coordinator's preliminary read-only audit is **not** a qualified fallback terminal verdict.
- **Approval stages:** independent governance amendment diff `PASS` → separate owner approval to merge governance PR and verified docs-only merge → **new** explicit owner authorization to activate and execute a one-use non-independent read-only fallback → terminal bounded audit `PASS/BLOCKED/INCONCLUSIVE` → if PASS, **separate owner PR #110 merge approval** → later separately authorized TC-V55B exception expiry. No auto-merge, code edits, device acceptance, build, signing or release.
- **Proposal-only scope:** only this Tracker appendix and §7 added to the existing EGM recovery addendum. `AGENTS.md`, `WORKFLOW.md`, the original frozen review comment, historic statuses, Dart files/tests, assets, CI and other product features are untouched. This record does **not** itself activate fallback or change the effective review gate.
- **Current status / next action:** `PROPOSED / INACTIVE / GOVERNANCE_GOLDFISH_PENDING / NO_FALLBACK_OR_MERGE_AUTHORITY`; review exact docs-only Draft PR then request a genuinely separate governance-diff review. If reviewer unable to establish isolation or precedence, report `BLOCKED/INCONCLUSIVE` and **stop**, rather than auto-retrying.


## Proposed PR #112 non-independent governance-review exception (INACTIVE; NO MERGE AUTHORITY)

- **Task:** `TC-V55B-PR112-GOVERNANCE-REVIEW-EXCEPTION-01`; **classification:** `GOVERNANCE-ONLY / PROPOSED / SINGLE-TARGET / NON_INDEPENDENT`. Applies exclusively to governance PR #112, not to PR #110's implementation acceptance. **GBI remains first unchecked Active** and unchanged.
- **Owner drafting authorization:** on 2026-11-23 (Africa/Cairo), owner requested the coordinator to perform review and create an exception, then expressly answered `موافق` to drafting an explicit PR #112 non-independent governance-review amendment. This is a coordinator-recorded ChatGPT instruction, not a GitHub-native signed approval, and **not permission to merge, activate fallback, or release**.
- **Reason:** two Claude governance attempts ended `INCONCLUSIVE / SOURCE_SCOPE_LIMIT`; subsequent review lacked certifiable fresh isolation, while the coordinator is inherently non-independent. Preserve both outcomes unchanged. The coordinator's preliminary text assessment is **not independent F0 PASS**.
- **Proposed authority and precedence:** Addendum §7.5 proposes a **specific prospective substitution** for the otherwise-mandatory independent F0 governance review of PR #112 only, including the corresponding §5 G1 and EGM Gate 2 independence requirement for this single amendment. It does **not** automatically change existing effective governance, and does not generalize to other tracker items or high-risk changes.
- **Next gates:** exact-new-HEAD read-only `OWNER_AUTHORIZED_NON_INDEPENDENT_GOVERNANCE_AUDIT` with full original GitHub sources, explicit non-independence and P0–P3, terminal PASS/BLOCKED/INCONCLUSIVE (one use) → if supported PASS and CI, **separate new owner approval** accepting deviation and merging PR #112, verify docs-only main merge SHA → **different later owner approval** to activate and execute one bounded PR #110 technical fallback → if bounded PASS, **another separate owner approval** before PR #110 merge. Any BLOCKED/INCONCLUSIVE stops; no automatic retry.
- **Status:** `PROPOSED / F0-NI_PENDING / NOT EFFECTIVE / NO PR112 MERGE / NO PR110 FALLBACK ACTIVATION / NO PR110 MERGE OR RELEASE AUTHORITY`. Historical independent-review failures and the prior activated recovery record remain preserved.

## TC-V55B post-merge closeout — authoritative superseding record (2026-11-23)

- **Task:** `TC-V55B-TRIPLE-MATRIX-TEST-01` and one-use `TC-V55B-PR112-GOVERNANCE-REVIEW-EXCEPTION-01`; **status:** `CLOSED / CONSUMED / EXPIRED / NON-REUSABLE`. This is a post-merge reconciliation; it **supersedes the earlier PROPOSED / INACTIVE / PENDING status text above without erasing its historical sequence**.
- **Source of authority:** The owner separately approved the non-independent F0-NI governance-review deviation and PR #112 merge (F1-NI), then approved one-use PR #110 technical fallback activation (F2), and subsequently explicitly approved PR #110 merge (F4). These approvals were given in the coordinating ChatGPT conversation, not represented as signed GitHub-native reviews.
- **Governance merge:** [PR #112](https://github.com/Strike87/math-challenge-flutter/pull/112) `MERGED`, merge commit [`14342c4f655798189220d356f273c4d1be3562c5`](https://github.com/Strike87/math-challenge-flutter/commit/14342c4f655798189220d356f273c4d1be3562c5), reviewed proposal HEAD `d11f71a6aac44eebedaffc2d7c2bfc7201ac9a24`. The F0-NI review was **non-independent**, not a fresh Goldfish PASS; the explicitly accepted governance deviation is **one-use only**.
- **Implementation activation and review:** [F2 activation](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7087196729) recorded `OWNER_AUTHORIZED_BOUNDED_FALLBACK_AUDIT / NON_INDEPENDENT` for the fixed PR #110 test-only HEAD `e2f3d300996fa120e1b05ab3026f60b7f1559f70`. [F3 terminal audit](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7087207498) recorded **bounded NON_INDEPENDENT PASS**, P0/P1 none found, P2 scope/provenance/observability limitations. The single-use fallback slot is **CONSUMED / EXPIRED**; historical independent Goldfish review attempts remain INCONCLUSIVE and are not relabeled PASS.
- **Test-only merge:** [PR #110](https://github.com/Strike87/math-challenge-flutter/pull/110) `MERGED / CLOSED`, merge commit [`f5ad982695bc9985e456934a00cc44553d546021`](https://github.com/Strike87/math-challenge-flutter/commit/f5ad982695bc9985e456934a00cc44553d546021), fixed HEAD `e2f3d300996fa120e1b05ab3026f60b7f1559f70`, one test file `test/target_clash_v55b_triple_permutation_matrix_test.dart` (+199/-0). [PR-head CI](https://github.com/Strike87/math-challenge-flutter/actions/runs/45027283169) was `SUCCESS` before merge. The F3 audit reports 24 configurations × six permutations = 144 domain materializations, zero failures, 1439 non-golden tests passing and two skips, analyzer and VM guard success from original owner-exported Push/PR logs; these are **review-record claims**, not independently rerun as part of this documentation closeout.
- **Limits:** `DOES_NOT_PROVE_REAL_GAMESTATE_RNG_SEQUENCE_EQUIVALENCE`; no actual device acceptance, build/signing, or release authorization. A non-independent F3 PASS is not independent Goldfish PASS. Neither merged exception authorizes another Target Clash task, replay, governance waiver, or future non-independent audit.
- **Tracker sequencing:** **GBI remains the first unchecked item under Active**; no gameplay authority, mode integration, or order change. The separate MD3-UX-02 B1-F proposal remains `PROPOSED / INACTIVE`.
- **Next permitted action:** this docs-only closeout PR requires its own review and a **new separate owner approval before merge**. Do not treat drafting or passing CI as merge authorization.
