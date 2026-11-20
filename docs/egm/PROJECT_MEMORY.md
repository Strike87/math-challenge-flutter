# Project memory — source index, not a second source of truth

Baseline evidence inspected: `main` at `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae` (2026-11-20). Revalidate before each task.

## Mission
Math Challenge: Flutter/Dart mathematics game with modes, progression, adaptive and shadow-only GameBrain evidence architecture, family/age guardrails, accessibility, ads/billing and optional cloud services. See [README](../../README.md) for public overview; it may not reflect the newest feature state.

## Authoritative reference map
| Area | Start here | Guardrail |
| --- | --- | --- |
| Entire app & agent process | [AGENTS.md](../../AGENTS.md), [behavior contracts](../behavior_contracts.md), [refactor tracker](../refactor_tracker.md) | Preserve verified parity; obey bounded agent workflow |
| Core state & lifecycle | [game_state.dart](../../lib/engine/game_state.dart) | No unauthorized broad decomposition |
| Shared math generation | [question_generator.dart](../../lib/engine/question_generator.dart) | Changes affect multiple modes |
| GameBrain | [integration architecture](../game_brain_integration_architecture.md), [governance decisions](../game_brain_governance_decisions.md), [GameBrain docs](../game_brain/) | Advisory/shadow boundaries; never infer gameplay authority |
| Target Clash | [feature docs](../target_clash/), [domain](../../lib/features/target_clash/domain/), [presentation](../../lib/features/target_clash/presentation/) | Canonical generator & runtime own gameplay legality |
| Persistence/economy/ads | [behavior contracts](../behavior_contracts.md), [persistence audit](../persistence-schema-audit.md) | Schema, coins, ad cadence and paid entitlements require explicit impact review |
| Visual/accessibility | [identity spec](../flutter-visual-identity-spec.md), [visual parity tests](../../test/visual_parity_test.dart) | No incidental UI or accessibility changes |
| Historical progress | [refactor tracker](../refactor_tracker.md), [work register](WORK_REGISTER.md), GitHub PR/commit history | Historical checked items are not proof of current CI |

## Immutable baseline principles
- GameBrain core is not the authority for question correctness, RNG, score, timers or progression. Any gameplay influence needs its own explicit authorized adapter/gate.
- Normal mode, adaptive, Survival, Master, Daily Boss, Operation Quest, two-player, and Target Clash must not inherit each other's changes accidentally.
- Respect family/privacy guardrails, persistence schema, purchases, ads and reset.
- Source hierarchy for **current** state: current `main` source and CI + merged PRs; for intended behavior: approved contracts and decisions; if these disagree, flag DRIFT and seek scoped decision rather than rewriting history.
- Fresh Goldfish reviewer gets this specific document only if it is explicitly cited as review source; do not include the design conversation.

## Existing validated checkpoints
- Target Clash V5.4 PR [#99](https://github.com/Strike87/math-challenge-flutter/pull/99) merged into `main`, merge commit `5b2259cc3725d7ae7bff1c1fcb567e318ecc47ae`. CI at PR passed. No APK/AAB or release asserted.
- V5.5-A is a **separate** test-only workstream; see [work register](WORK_REGISTER.md) for its draft PR and verification status.
- Older GameBrain refactor-tracker closures should remain in the tracker, not be re-created here.

## Session handoff template
Task ID / objective / baseline SHA / exact sources / approved scope / forbidden scope / decisions with references / PR or commit / tests and skip counts / review type (independent or fallback) / unresolved risks / next smallest action / authorization still needed.

A change is not complete merely because someone wrote “done” in chat.
