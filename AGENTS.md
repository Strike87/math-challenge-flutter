# Math Challenge Agent Instructions

## Required reading

Before working, read:

- `docs/behavior_contracts.md`
- `docs/refactor_tracker.md`
- any feature specification explicitly named in the task

Do not rely on undocumented assumptions or old conversation history.

## Repository

This is a Flutter application.

Primary production-state orchestration currently remains in:

- `lib/engine/game_state.dart`

Do not broadly decompose `GameState` unless a reviewed tracker item explicitly
authorizes one narrow responsibility.

## Main orchestration rule

The root Codex session is the orchestrator.

For behavior-sensitive work:

- delegate read-only investigation to `parity_reasoner`;
- delegate an approved bounded implementation to `flutter_worker`;
- delegate final read-only review to `regression_reviewer`;
- wait for each role before continuing;
- never run multiple code-writing agents against the same working tree.

Use one bounded task per cycle:

```text
reason -> approve scope -> implement -> test -> review -> commit
```

## Working method

1. Inspect current behavior.
2. Audit the smallest safe boundary.
3. Obtain approval before implementation.
4. Start implementation from a clean branch based on updated `main`.
5. Implement only the approved boundary.
6. Run focused tests.
7. Run the full non-golden suite when shared behavior is involved.
8. Run visual parity tests.
9. Run `flutter analyze`.
10. Review the complete diff.
11. Commit the task separately.

Audit and implementation must remain separate tasks when behavior is complex.

## Behavior preservation

Do not incidentally change:

- gameplay rules;
- scoring;
- question generation;
- timers;
- adaptive-difficulty formulas;
- Survival progression or rewards;
- Master stage contracts;
- Daily Boss behavior;
- two-player turn counting;
- coins or shop prices;
- achievements;
- persistence keys or migrations;
- AdMob cadence;
- IAP delivery;
- navigation;
- reset behavior;
- user-visible copy or visuals.

The frozen contracts are recorded in `docs/behavior_contracts.md`.

### Unsupported hybrid compatibility

The publicly constructible `Survival + Master` state is unsupported by normal
UI flow but remains part of executable-reference behavior.

Do not delete the Survival phase-scoring branch or add a challenge/mode
coherence guard as incidental cleanup.

Any normalization or rejection of unsupported challenge/mode combinations
requires a separately approved behavior-matrix audit and product decision.

## Architecture boundaries

Pure domain policies and engines must not depend on:

- Flutter;
- Provider or Riverpod;
- `GameState`;
- `Storage` or SharedPreferences;
- navigation;
- notifications;
- UI;
- AdMob;
- IAP.

`GameState` remains responsible for orchestration, mutation, timing,
persistence, navigation, and external side effects unless an approved step
explicitly moves one responsibility.

## Explicit exclusions

Do not revive:

- broad `GameState` decomposition;
- a global `ModeController`;
- a global `GameSession` replacement;
- large file or module splits;
- merging primary and secondary adaptive mastery updates;
- full localization;
- accessibility tasks 6-9;
- splash or application-icon redesign;
- unrelated design-system cleanup;
- speculative folders or layers.

## Validation

Use the appropriate focused tests, followed by:

```powershell
flutter test --reporter compact --exclude-tags golden --no-pub
flutter test test\visual_parity_test.dart --reporter compact --no-pub
flutter analyze --no-pub
```

Use commands without `--no-pub` when package resolution requires it.

Before finishing:

```powershell
git diff --check
git diff --stat
git status --short
```

## Git safety

Never use `git add .`.

Do not commit:

- `android/key.properties`;
- `android/local.properties`;
- `*.jks`;
- `*.keystore`;
- `build/`;
- `.dart_tool/`;
- `android/.kotlin/`;
- `test/failures/`;
- logs;
- generated Graphify churn;
- secrets.

Do not commit, push, or merge automatically unless the user explicitly
instructs it.

---

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
