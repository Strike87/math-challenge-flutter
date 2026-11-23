# Project memory — source index, not a second source of truth

Baseline evidence inspected: `main` at
`5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae` on 2026-11-20. Revalidate every
row against current source, contracts, and GitHub before a task begins. This
file indexes authority; it does not copy or replace contracts.

## Mission

Math Challenge is a Flutter/Dart mathematics game with multiple gameplay modes,
progression, adaptive difficulty, shadow-only GameBrain evidence architecture,
family/age guardrails, accessibility, ads/billing, and optional cloud services.
The public [README](../../README.md) is an overview only and may lag current
feature state.

## Authoritative project map

| Area | Authoritative starting points | Boundary to preserve |
| --- | --- | --- |
| Agent governance and task lifecycle | [AGENTS.md](../../AGENTS.md), [behavior contracts](../behavior_contracts.md), [refactor tracker](../refactor_tracker.md), [EGM workflow](WORKFLOW.md) | Existing precedence, first-unchecked tracker gate, explicit owner authorization, and independent review remain controlling. |
| Core orchestration and lifecycle | [GameState](../../lib/engine/game_state.dart), [game screen](../../lib/screens/game_screen.dart) | `GameState` owns orchestration, mutation, timing, persistence, navigation, and side effects; no broad decomposition without authorization. |
| Math facts and question generation | [question generator](../../lib/engine/question_generator.dart), [models/enums](../../lib/models/enums.dart), [question mechanic](../../lib/features/gameplay/domain/question_mechanic.dart) | Generator/domain contracts own mathematical legality, representations, answers, and choices. |
| Standard, Blitz, Combo, Death, and two-player play | [behavior contracts](../behavior_contracts.md), [GameState](../../lib/engine/game_state.dart), [config screen](../../lib/screens/config_screen.dart), [player screen](../../lib/screens/player_screen.dart) | Preserve timers, turn counts, scoring, answer styles, and configuration snapshots. |
| Survival | [SurvivalProgressionPolicy](../../lib/features/gameplay/domain/survival_progression_policy.dart), [behavior contracts](../behavior_contracts.md), [survival tests](../../test/survival_boss_event_test.dart) | Preserve phase progression, boss events, lives, rewards, timeout behavior, and the unsupported Survival + Master reference branch. |
| Master | [behavior contracts](../behavior_contracts.md), [GameState](../../lib/engine/game_state.dart), [refactor tracker](../refactor_tracker.md) | Authored stage parameters and terminal-delay behavior remain authoritative; do not infer GameBrain control. |
| Daily Boss | [behavior contracts](../behavior_contracts.md), [GameState](../../lib/engine/game_state.dart), [menu screen](../../lib/screens/menu_screen.dart) | Fixed daily configuration, claims, lives, rewards, and progression remain distinct from Mental Math. |
| Operation Quest | [Operation Quest domain](../../lib/features/operation_quest/domain/operation_quest.dart), [operation-quest docs](../refactor_tracker.md), [menu screen](../../lib/screens/menu_screen.dart) | Trail, unlock, star, and progress ownership stays separate from ordinary practice and Weak Skills. |
| Weak Skills Practice | [Weak Skills policy](../../lib/features/weak_skills/domain/weak_skills_policy.dart), [Weak Skills adapter](../../lib/features/weak_skills/integration/weak_skills_advisory_signal_adapter.dart), [behavior contracts](../behavior_contracts.md), [refactor tracker](../refactor_tracker.md) | Canonical mastery and frozen focus remain authoritative; no parallel mastery, reward, or GameBrain authority. |
| Mental Math | [Mental Math frozen contracts](../behavior_contracts.md), [refactor tracker](../refactor_tracker.md), [practice-style screen](../../lib/screens/practice_style_screen.dart) | v1/v2 are contract-controlled and partly unimplemented; preserve fail-closed GameBrain evidence, fixed configuration, and required implementation order. |
| Target Clash | [Target Clash contracts](../target_clash/), [run config](../../lib/features/target_clash/domain/target_clash_run_config.dart), [runtime state](../../lib/features/target_clash/domain/target_clash_runtime_state.dart), [generator](../../lib/features/target_clash/domain/target_clash_question_generator.dart) | Target Clash generator/runtime own legality and state; do not import unrelated mode or GameBrain authority. |
| Progression, mastery, achievements, and rewards | [behavior contracts](../behavior_contracts.md), [GameState](../../lib/engine/game_state.dart), [storage](../../lib/services/storage.dart), [refactor tracker](../refactor_tracker.md) | Preserve canonical mastery, scoring, coins, achievements, reset, and persistence keys/order. |
| Family safety and eligibility | [family eligibility](../../lib/features/family/domain/family_eligibility.dart), [age gate](../../lib/features/family/presentation/family_age_gate_screen.dart), [GameBrain eligibility](../../lib/features/game_brain/domain/game_brain_eligibility.dart) | Privacy/age restrictions fail closed; never expand evidence or collection authority implicitly. |
| Persistence and cloud save | [storage](../../lib/services/storage.dart), [cloud progress policy](../../lib/features/cloud_save/domain/cloud_progress_policy.dart), [persistence audit](../persistence-schema-audit.md) | Existing keys, defaults, migrations, reset, and transaction boundaries require explicit review. |
| Monetization and external side effects | [AdMob](../../lib/services/admob.dart), [IAP](../../lib/services/iap.dart), [behavior contracts](../behavior_contracts.md) | Ad cadence, rewarded callbacks, paid entitlements, and coin delivery require separate authorization and evidence. |
| Accessibility and visual parity | [visual identity spec](../flutter-visual-identity-spec.md), [visual parity tests](../../test/visual_parity_test.dart), [Target Clash accessibility contract](../target_clash/target_clash_tc_05_final_visual_accessibility_regression_contract.md) | No incidental UI, copy, text-scale, contrast, or accessibility changes; automated parity is not human approval. |
| GameBrain | [integration architecture](../game_brain_integration_architecture.md), [governance decisions](../game_brain_governance_decisions.md), [GameBrain facade](../../lib/features/game_brain/game_brain.dart), [refactor tracker](../refactor_tracker.md) | GameBrain is advisory/shadow-only unless a separately authorized adapter grants bounded capability; it never owns correctness, RNG, score, timers, progression, or persistence. |

## Source hierarchy and immutable principles

- Current state is established by current `main`, live source, CI, and merged
  PRs; intended behavior is established by approved contracts and decisions.
  If they disagree, record `DRIFT` and seek a scoped decision.
- GameBrain core is not authority for question correctness, RNG, score, timers,
  progression, persistence, or user truth. Any gameplay influence needs an
  explicit reviewed adapter/gate.
- Modes, number types, answer styles, progression, ads, IAP, family safety,
  accessibility, and persistence must not inherit changes accidentally.
- Mental Math contracts include planned or unimplemented slices; an index entry
  is not evidence that gameplay exists.
- A fresh Goldfish reviewer receives only this cited source map and enumerated
  references, never the design conversation or private chain of thought.

## Validated checkpoints

- [PR #98](https://github.com/Strike87/math-challenge-flutter/pull/98) merged
  as `c6aa227a3b9f7eb5b691ee43e01ba8dbc838579a`; no release claim follows.
- [PR #99](https://github.com/Strike87/math-challenge-flutter/pull/99) merged
  into `main` as `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae`; no device or
  release claim follows.
- V5.5-A is separate test-only [PR #100](https://github.com/Strike87/math-challenge-flutter/pull/100); see the register for current failed CI evidence.
- EGM bootstrap is [PR #101](https://github.com/Strike87/math-challenge-flutter/pull/101); its review status is tracked separately and must not be called approved until a fresh reviewer returns `PASS`.

## Handoff minimum

Task ID, objective, responsible owner, baseline/base/head SHAs, exact sources,
approved scope, forbidden scope, tracker authorization, decisions with
references, PR/commit/check links, test counts/skips, reviewer provenance,
unresolved risks, last verification timestamp, next permitted action, and
authorization still needed.

A change is not complete because someone wrote “done” in chat.

## TC-V55B and PR #112 governance checkpoint — 2026-11-23

This is a dated source-index update; older `Validated checkpoints` entries are historical and must not be read as the current PR status.

- [PR #112](https://github.com/Strike87/math-challenge-flutter/pull/112) merged at `14342c4f655798189220d356f273c4d1be3562c5` after an **owner-accepted non-independent F0-NI** governance review; no claim of independent Goldfish PASS.
- [PR #110](https://github.com/Strike87/math-challenge-flutter/pull/110) merged at `f5ad982695bc9985e456934a00cc44553d546021` (fixed test-only HEAD `e2f3d300996fa120e1b05ab3026f60b7f1559f70`). [PR CI](https://github.com/Strike87/math-challenge-flutter/actions/runs/45027283169) succeeded. [F2 activation](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7087196729) and [F3 bounded non-independent PASS](https://github.com/Strike87/math-challenge-flutter/pull/110#issuecomment-7087207498) are recorded; the one-use exception is expired.
- The test establishes 144 bounded domain materializations, **not** production GameState RNG-sequence equivalence. No device acceptance or release is asserted. [Tracker](../refactor_tracker.md) and [work register](WORK_REGISTER.md) remain authoritative for gate and workstream status. **GBI is still the first unchecked Active item.**
- This documentation-only closeout proposal requires review and **separate owner merge approval**; it grants no runtime, code, build or release authority.
