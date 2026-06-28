# Achievement Trigger Audit

Date: 2026-06-27

Original source of truth: `C:\Users\Strik\math-challenge\www\index.html`

Flutter target: `C:\Users\Strik\math_challenge_flutter`

This audit supports BPT-006 / RT-004. The original achievement definitions live in `ACHIEVEMENTS_DEF` at `index.html:6586`. The original `_unlock` method at `index.html:10413` only unlocks, saves, previews, and shows a toast; it does not grant coins or any other reward. Therefore the achievement reward column is `None` for every achievement.

| ID | Title | Reward | Original trigger | Original source | Flutter source / verification |
| --- | --- | --- | --- | --- | --- |
| `first_win` | First Victory | None | `gamesPlayed >= 1` after a completed game. | `index.html:6587`, `index.html:10426` | `lib\engine\game_state.dart:1416`; audited and fixed to match source. |
| `speed_demon` | Speed Demon | None | `rt.fastAnswers >= 5`. | `index.html:6588`, `index.html:10427` | `lib\engine\game_state.dart:1425`; covered by RT-004. |
| `perfect_score` | Perfect Score | None | Player 1 has answered at least once and `correct == total`. | `index.html:6589`, `index.html:10428` | `lib\engine\game_state.dart:1418`; covered by RT-004. |
| `streak_master` | Streak Master | None | Player 1 max streak is at least 10. | `index.html:6590`, `index.html:10429` | `lib\engine\game_state.dart:1423`; source-matched. |
| `power_upper` | Power Upper | None | `rt.puUsed >= 5`. | `index.html:6591`, `index.html:10430` | `lib\engine\game_state.dart:1753`; source-matched. |
| `math_wizard` | Math Wizard | None | Unlock after completing Master Stage 3, when stage advancement makes `master.level >= 3`. | `index.html:6592`, `index.html:9998` | `lib\engine\game_state.dart:1252`; covered by RT-004. |
| `persistent` | Persistent | None | `gamesPlayed >= 10`. | `index.html:6593`, `index.html:10438` | `lib\engine\game_state.dart:1401`; source-matched. |
| `quick_learner` | Quick Learner | None | `adaptLvl >= 8`. | `index.html:6594`, `index.html:10439` | `lib\engine\game_state.dart:1436`; source-matched. |
| `survivor` | Survivor | None | Death mode and Player 1 score is at least 250. | `index.html:6595`, `index.html:10440` | `lib\engine\game_state.dart:1427`; covered by RT-004. |
| `avatar_artist` | Avatar Artist | None | Player 1 or Player 2 custom avatar differs from the default base, hat, accessory, or color. | `index.html:6597`, `index.html:10449` | `lib\engine\game_state.dart:1861`; source-matched. |
| `skill_master` | Skill Master | None | Any skill entry has `count >= 5` and `mastery >= 90`. | `index.html:6598`, `index.html:10456` | `lib\engine\game_state.dart:1429`; audited and fixed from confidence-based unlock to source count/mastery rule; covered by RT-004. |
| `daily_grind` | Daily Grind | None | At least 3 daily challenge progress entries are completed. | `index.html:6599`, `index.html:10462` | `lib\engine\game_state.dart:1731`; covered by RT-004. |
| `daily_boss` | Boss Breaker | None | Daily Boss win flag is true. | `index.html:6600`, `index.html:10437` | `lib\engine\game_state.dart:1267`; covered by RT-004. |
| `math_legend` | Math Legend | None | Full Master mode completion through the explicit `masterWin` path. | `index.html:6601`, `index.html:10434` | `lib\engine\game_state.dart:1248`; covered by RT-004. |

## Confirmed Fixes

- `first_win` now unlocks from completed-game count, matching `gamesPlayed >= 1`, instead of only a win path.
- `skill_master` now requires both enough attempts and source mastery: `count >= 5 && mastery >= 90`.
- High scores loaded from storage are copied into a growable list because the end-game path mutates the working collection with `add`, `sort`, and trimming.

## Regression Proof

- `flutter test test\achievement_trigger_test.dart`
- `flutter test`
- `flutter analyze`

All passed on 2026-06-27.
