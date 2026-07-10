# Graph Report - math_challenge_flutter_repo  (2026-07-10)

## Corpus Check
- 129 files · ~504,132 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2065 nodes · 2694 edges · 102 communities (89 shown, 13 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `9f8c0a2c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- game_state.dart
- modals.dart
- iap.dart
- game_screen.dart
- StatelessWidget
- admob.dart
- game_config.dart
- package:flutter_test/flutter_test.dart
- player.dart
- common.dart
- audio.dart
- game_data.dart
- question_generator_test.dart
- settings.dart
- visual_parity_test.dart
- admob_parity_test.dart
- config_screen.dart
- main.dart
- menu_screen.dart
- mode_player_eligibility_test.dart
- feedback_layer_test.dart
- celebration_overlay.dart
- iap_adult_gate_test.dart
- enums.dart
- avatars.dart
- question_generator.dart
- storage.dart
- iap_delivery_test.dart
- shield_animation_test.dart
- iap_restore_native_safety_test.dart
- package:shared_preferences/shared_preferences.dart
- modal_behavior_test.dart
- numtype_screen.dart
- player_screen.dart
- State
- power_up_rules_test.dart
- package:flutter/services.dart
- @visibleForTesting
- GameState
- ../game_config.dart
- celebration.dart
- daily_boss_test.dart
- dart_build_result.json
- storage_migration_test.dart
- IapPurchaseAdapter
- GeneratedPluginRegistrant.java
- MainActivity
- gradlew
- AdMobService
- AudioService
- _AppShellState
- AdMobException
- IapException
- _AvatarPickerDialogState
- _PressableScale
- AdMobService
- AdultGateChallenge?
- @mathchallenge
- AudioService
- CelebrationEvent
- DailyBoss?
- DailyChallenge
- Difficulty
- GameMode
- HighScore
- IapProduct?
- IapPurchaseAdapter
- NumberType
- Operation
- QuestionGenerator
- SettingsService
- ShopItem
- SkillData
- UI Widgets
- graphify reference: add a URL and watch a folder
- graphify reference: commit hook and native CLAUDE.md integration
- graphify reference: incremental update and cluster-only
- graphify reference: add a URL and watch a folder
- graphify reference: commit hook and native CLAUDE.md integration
- graphify reference: incremental update and cluster-only
- Achievement Trigger Audit
- 12. Coin shop — exact items and prices
- 8. Adaptive difficulty / mastery system — exact constants
- Answer Evaluation
- Engine Flow
- Format Selection Rules
- Testing Blueprint
- graphify reference: GitHub clone and cross-repo merge
- graphify reference: transcribe video and audio
- graphify reference: GitHub clone and cross-repo merge
- graphify reference: transcribe video and audio
- State Changes
- AGENTS.md
- CLAUDE.md
- CLAUDE.md
- extraction-spec.md
- extraction-spec.md
- _GoogleBannerAd

## God Nodes (most connected - your core abstractions)
1. `SettingsService` - 73 edges
2. `GameState` - 25 edges
3. `Math Challenge Flutter v1.1 Technical Blueprint` - 22 edges
4. `Math Challenge — Complete Game Data & Behavior Reference` - 19 edges
5. `Feature Parity Matrix` - 17 edges
6. `Behavioral Parity Tracker (BPT)` - 15 edges
7. `Math Challenge — Full 1:1 Behavioral Port Master Prompt (Flutter)` - 13 edges
8. `What You Must Do When Invoked` - 12 edges
9. `What You Must Do When Invoked` - 12 edges
10. `Math Challenge — Visual Identity Spec for Flutter Implementation` - 12 edges

## Surprising Connections (you probably didn't know these)
- `_FakeAdMobService` --implements--> `AdMobService`  [EXTRACTED]
  test/admob_parity_test.dart → lib/services/admob.dart
- `MockAudioService` --implements--> `AudioService`  [EXTRACTED]
  test/visual_parity_test.dart → lib/services/audio.dart
- `_FakeIapPurchaseAdapter` --implements--> `IapPurchaseAdapter`  [EXTRACTED]
  test/iap_adult_gate_test.dart → lib/services/iap.dart
- `_FakeIapPurchaseAdapter` --implements--> `IapPurchaseAdapter`  [EXTRACTED]
  test/iap_delivery_test.dart → lib/services/iap.dart
- `_FakeIapPurchaseAdapter` --implements--> `IapPurchaseAdapter`  [EXTRACTED]
  test/iap_restore_native_safety_test.dart → lib/services/iap.dart

## Import Cycles
- None detected.

## Communities (102 total, 13 thin omitted)

### Community 0 - "game_state.dart"
Cohesion: 0.01
Nodes (277): accepting, achievements, _activeDailyChallenge, activePlayer, adaptive, adaptLvl, adaptLvlRaw, _adaptThresholdEasy (+269 more)

### Community 1 - "modals.dart"
Cohesion: 0.02
Nodes (87): CustomPainter, double?, a, accuracy, actions, active, _answerController, _avatarBuilderColor (+79 more)

### Community 2 - "iap.dart"
Cohesion: 0.03
Nodes (75): Completer, _, DateTime, Duration, InAppPurchase, accepts, AdultGateChallenge, all (+67 more)

### Community 3 - "game_screen.dart"
Cohesion: 0.03
Nodes (70): Animation, AnimationController, active, _ActivePlayerPowerUpIcon, _ActivePowerUpGlow, _AnswersGrid, _buildOpacity, child (+62 more)

### Community 4 - "StatelessWidget"
Cohesion: 0.05
Nodes (57): MathChallengeApp, _PlayerCard, SettingsService, NeoButton, _AccessibilityPanel, AchievementsModal, _AdultGateQuestionStep, _AdultGateWarningStep (+49 more)

### Community 5 - "admob.dart"
Cohesion: 0.03
Nodes (64): AdRequest, AdRequest get, BannerAd?, _ad, AdMobErrorCode, AdMobRequestPolicy, AdMobUnitIds, adRequest (+56 more)

### Community 6 - "game_config.dart"
Cohesion: 0.04
Nodes (56): achievementsDef, avatarAccessories, avatarBases, avatarColors, avatarHats, bgDark, bgLight, blitzTimerDefault (+48 more)

### Community 7 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.05
Nodes (52): dart:convert, _channel, LinkLauncher, open, package:flutter/services.dart, package:math_challenge/engine/game_state.dart, package:math_challenge/models/enums.dart, package:math_challenge/models/game_data.dart (+44 more)

### Community 8 - "player.dart"
Cohesion: 0.04
Nodes (50): AvatarData get, enums.dart, accessory, accuracy, ans, _avatar, AvatarData, avgMs (+42 more)

### Community 9 - "common.dart"
Cohesion: 0.04
Nodes (49): ../constants/avatars.dart, dart:ui, EdgeInsets?, AppFonts, availableAvatars, avatar, AvatarSelectorTile, AvatarWidget (+41 more)

### Community 10 - "audio.dart"
Cohesion: 0.04
Nodes (45): @pragma, AudioPlayer, dart:io, _PluginRegistrant, register, dart:typed_data, Future, int get (+37 more)

### Community 11 - "game_data.dart"
Cohesion: 0.05
Nodes (41): Achievement, boss, confidence, consumable, correct, count, DailyBoss, DailyChallenge (+33 more)

### Community 12 - "question_generator_test.dart"
Cohesion: 0.05
Nodes (41): package:math_challenge/engine/question_generator.dart, _additionRanges, _answerIndex, audioGlobalChannel, audioPlayerChannel, _containsNegative, direct, dividend (+33 more)

### Community 13 - "settings.dart"
Cohesion: 0.05
Nodes (36): Color get, double get, FontWeight get, accent, _animSpeed, bg, bodyLineHeight, bodyWeight (+28 more)

### Community 14 - "visual_parity_test.dart"
Cohesion: 0.06
Nodes (30): package:math_challenge/screens/menu_screen.dart, package:math_challenge/screens/numtype_screen.dart, required Size logicalSize,
  double, child, debugTonePlayCount, debugVibrationCount, devicePixelRatio, expectNoVisualException (+22 more)

### Community 15 - "admob_parity_test.dart"
Cohesion: 0.07
Nodes (29): AdMobRequestPolicy get, AdMobService? adService,
  int, package:flutter/widgets.dart, audioGlobalChannel, audioPlayerChannel, bannerForceHidden, bannerHides, bannerShows (+21 more)

### Community 16 - "config_screen.dart"
Cohesion: 0.07
Nodes (28): active, color, compact, _diffDesc, disabled, firstSpace, icon, label (+20 more)

### Community 17 - "main.dart"
Cohesion: 0.06
Nodes (33): _adMobUseTestAds, adService, adUnitIds, _AppShell, _AppShellState, build, child, createState (+25 more)

### Community 18 - "menu_screen.dart"
Cohesion: 0.07
Nodes (26): IconData?, _brandWordStyle, _CampaignCard, color, _DailyNavBtn, _EqualBrandBar, _EqualBrandIcon, gs (+18 more)

### Community 19 - "mode_player_eligibility_test.dart"
Cohesion: 0.17
Nodes (11): package:math_challenge/screens/player_screen.dart, return, audioGlobalChannel, audioPlayerChannel, _host, init, load, main (+3 more)

### Community 20 - "feedback_layer_test.dart"
Cohesion: 0.08
Nodes (23): package:confetti/confetti.dart, package:math_challenge/widgets/celebration_overlay.dart, Set, audioGlobalChannel, audioPlayerChannel, _classBlock, _correctEmojiSet, init (+15 more)

### Community 21 - "celebration_overlay.dart"
Cohesion: 0.08
Nodes (24): ConfettiController, dart:async, build, _CelebrationBadge, CelebrationOverlay, _CelebrationOverlayState, _colorsFor, _confettiAllowed (+16 more)

### Community 22 - "iap_adult_gate_test.dart"
Cohesion: 0.09
Nodes (21): audioGlobalChannel, audioPlayerChannel, buyCalls, buyProduct, _ChallengeSequence, completeCalls, completePurchase, _index (+13 more)

### Community 23 - "enums.dart"
Cohesion: 0.10
Nodes (20): division,
  mixed,
  master,
  dailyBoss,, easy,
  medium,
  hard,
  expert,, fifty,
  double,
  shield,
  freeze,, combo, Difficulty, fromString, GameMode, insane (+12 more)

### Community 24 - "avatars.dart"
Cohesion: 0.11
Nodes (18): dart:math, all, AvatarCategory, AvatarPool, birds, bugs, _buildAll, categories (+10 more)

### Community 25 - "question_generator.dart"
Cohesion: 0.11
Nodes (18): int?, ans, _applyNumType, build, _buildBase, _buildChoices, key, _QBase (+10 more)

### Community 26 - "storage.dart"
Cohesion: 0.11
Nodes (18): containsKey, getBool, getDouble, getInt, getString, getStringList, init, _prefs (+10 more)

### Community 27 - "iap_delivery_test.dart"
Cohesion: 0.11
Nodes (18): Map, audioGlobalChannel, audioPlayerChannel, buyCalls, buyProduct, completeCalls, completePurchase, init (+10 more)

### Community 28 - "shield_animation_test.dart"
Cohesion: 0.11
Nodes (18): Opacity, package:math_challenge/screens/game_screen.dart, init, load, lowPerf, main, _makeState, pump (+10 more)

### Community 29 - "iap_restore_native_safety_test.dart"
Cohesion: 0.11
Nodes (18): audioGlobalChannel, audioPlayerChannel, buyCalls, buyError, buyProduct, completeCalls, completePurchase, init (+10 more)

### Community 30 - "package:shared_preferences/shared_preferences.dart"
Cohesion: 0.09
Nodes (27): main, package:flutter/material.dart, package:integration_test/integration_test.dart, package:math_challenge/main.dart, package:math_challenge/screens/config_screen.dart, package:math_challenge/services/admob.dart, package:math_challenge/services/iap.dart, package:math_challenge/services/storage.dart (+19 more)

### Community 31 - "modal_behavior_test.dart"
Cohesion: 0.11
Nodes (17): AvatarCustom, package:math_challenge/widgets/modals.dart, ScrollableState, audioGlobalChannel, audioPlayerChannel, _dailyChallengesHost, init, linkChannel (+9 more)

### Community 32 - "numtype_screen.dart"
Cohesion: 0.08
Nodes (25): Color?, ../engine/game_state.dart, ../game_config.dart, build, color, desc, icon, label (+17 more)

### Community 33 - "player_screen.dart"
Cohesion: 0.12
Nodes (17): avatar, _AvatarOption, build, createState, _goBack, gs, onTap, pid (+9 more)

### Community 34 - "State"
Cohesion: 0.13
Nodes (22): GameScreen, _MotionSettingsBridge, _MotionSettingsBridgeState, _BossCircle, _BossCircleState, _FloatingShieldBadge, _FloatingShieldBadgeState, GameScreen (+14 more)

### Community 35 - "power_up_rules_test.dart"
Cohesion: 0.13
Nodes (14): _answerCorrect, audioGlobalChannel, audioPlayerChannel, _count, init, load, main, _makeState (+6 more)

### Community 36 - "package:flutter/services.dart"
Cohesion: 0.05
Nodes (37): 10. Achievements, 11. Shop, Economy, IAP, And Ads, 12. Avatar Builder, Emoji, And Icons, 13. Confetti, Celebration, Audio, And Haptics, 14. Visual Theme And Responsive Layout, 15. Persistence And Migration, 16. Release Services And Android Integration, 1. Navigation And Screen Flow (+29 more)

### Community 37 - "@visibleForTesting"
Cohesion: 0.15
Nodes (13): @visibleForTesting, debugGenerateDailyBoss, debugGetAdaptDiff, debugQuestionTimerDurationMs, debugRecordAdaptiveAnswer, debugRecordCompletedGameForAds, debugRestartQuestionTimer, debugSetMasterStage (+5 more)

### Community 38 - "GameState"
Cohesion: 0.18
Nodes (11): ChangeNotifier, GameState, build, ConfigScreen, build, build, MenuScreen, build (+3 more)

### Community 39 - "../game_config.dart"
Cohesion: 0.05
Nodes (36): 10. Cleaner Architecture, 1. Multi-Type Question System, 2. Mistake Review, 3. Boss Collection, 4. Format-Aware High Scores, 5. Daily Streak Calendar, 6. Smart Learning Mode, 7. Avatar Closet Upgrade (+28 more)

### Community 40 - "celebration.dart"
Cohesion: 0.20
Nodes (9): bool get, CelebrationEvent, CelebrationKind, emoji, id, isActive, kind, message (+1 more)

### Community 41 - "daily_boss_test.dart"
Cohesion: 0.20
Nodes (9): package:math_challenge/models/player.dart, answerCorrect, audioGlobalChannel, audioPlayerChannel, beatDailyBoss, expectBoss, main, makeState (+1 more)

### Community 42 - "dart_build_result.json"
Cohesion: 0.22
Nodes (8): build_end, build_start, code_assets, data_assets, dependencies, file:///C:/Users/Strik/Downloads/flutter/bin/cache/dart-sdk/version, file:///D:/FlutterProjects/math_challenge_flutter_repo/.dart_tool/package_config.json, file:///D:/FlutterProjects/math_challenge_flutter_repo/pubspec.yaml

### Community 43 - "storage_migration_test.dart"
Cohesion: 0.07
Nodes (26): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+18 more)

### Community 44 - "IapPurchaseAdapter"
Cohesion: 0.29
Nodes (7): DevIapPurchaseAdapter, IapPurchaseAdapter, NativeIapPurchaseAdapter, UnavailableIapPurchaseAdapter, _FakeIapPurchaseAdapter, _FakeIapPurchaseAdapter, _FakeIapPurchaseAdapter

### Community 45 - "GeneratedPluginRegistrant.java"
Cohesion: 0.60
Nodes (3): GeneratedPluginRegistrant, FlutterEngine, Keep

### Community 46 - "MainActivity"
Cohesion: 0.40
Nodes (3): FlutterEngine, MainActivity, FlutterActivity

### Community 47 - "gradlew"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

### Community 48 - "AdMobService"
Cohesion: 0.40
Nodes (5): AdMobService, DevAdMobService, GoogleMobileAdsService, UnavailableAdMobService, _FakeAdMobService

### Community 49 - "AudioService"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 50 - "_AppShellState"
Cohesion: 0.08
Nodes (24): 1. README Cleanup, 1. Settings Support Links, 2. Child-Friendly Help Text, 2. .gitignore Cleanup, 3. Generated Files Tracked By Git, 3. Vocabulary And Tone Pass, 4. Legibility Pass, 4. Modal Price Test Assertion (+16 more)

### Community 53 - "_AvatarPickerDialogState"
Cohesion: 0.09
Nodes (22): Approved Clone Additions, Behavior Freeze, Behavior Tracker, Behavioral Parity Tracker (BPT), BPT-001 Purchase Contract, BPT-001A: Adult Gate / Purchase Entry, BPT-001B: Product Constants / Purchase Launch, BPT-001C: Delivery / Duplicate Protection / Acknowledgement (+14 more)

### Community 54 - "_PressableScale"
Cohesion: 0.09
Nodes (21): Accessibility, Add Custom Fonts (Optional but Recommended), AdMob Setup, Build a Debug APK, Build a Release APK (for sideloading), Build an AAB (for Google Play Store upload), Build Instructions (Android APK / AAB), Credits (+13 more)

### Community 55 - "AdMobService"
Cohesion: 0.11
Nodes (18): 0. Locked architectural decisions — do not revisit these, 10. What "done" means for this task, 1. Core game loop & question generation (per mode), 2. Power-ups, 3. Achievements, 4. Daily challenges, 5. Coin economy & shop, 6. Settings & accessibility (+10 more)

### Community 56 - "AdultGateChallenge?"
Cohesion: 0.11
Nodes (17): 10. What this spec does NOT cover (intentionally), 11. How to use this spec, 1. Overall theme, 2. Color tokens (exact hex/rgba values), 3. Typography, 4. Border radius scale (use these exact tokens, not arbitrary values), 5. Shadows, 6. Button styles (+9 more)

### Community 61 - "AudioService"
Cohesion: 0.12
Nodes (15): package:flutter_test/flutter_test.dart, package:math_challenge/game_config.dart, package:math_challenge/models/celebration.dart, main, audioGlobalChannel, audioPlayerChannel, expectQuitCancelsDelayedLoss, main (+7 more)

### Community 62 - "CelebrationEvent"
Cohesion: 0.13
Nodes (14): 10. Daily challenges — exact full list (6 total), 11. Power-ups — exact 6 types, 13. Avatar customization options, 14. In-app purchase products — exact 4 products, 15. AdMob — exact cadence numbers, 17. Persisted storage keys (corrected, ~40+ confirmed), 18. How this document relates to the other two, 2. Number type transforms (applied after base generation) (+6 more)

### Community 64 - "DailyBoss?"
Cohesion: 0.13
Nodes (14): Boss Collection, Config Screen Changes, Current Code Anchors, Goal, Math Challenge Flutter v1.1 Technical Blueprint, Mistake Review, New Files, Non-Negotiables (+6 more)

### Community 65 - "DailyChallenge"
Cohesion: 0.20
Nodes (10): 16. Accessibility & display settings — exact behavior per toggle, Animation speed, Colorblind-safe palette, Dark mode, Dyslexia-friendly font, Performance / low-power mode, Reduce motion, Reset All Data (+2 more)

### Community 66 - "Difficulty"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 67 - "GameMode"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 68 - "HighScore"
Cohesion: 0.22
Nodes (8): build_end, build_start, code_assets, data_assets, dependencies, file:///C:/Users/Strik/Downloads/flutter/bin/cache/dart-sdk/version, file:///D:/FlutterProjects/math_challenge_flutter_repo/.dart_tool/package_config.json, file:///D:/FlutterProjects/math_challenge_flutter_repo/pubspec.yaml

### Community 69 - "IapProduct?"
Cohesion: 0.25
Nodes (8): 3. Timer system, Adaptive penalty, Base timer by difficulty (Standard mode and similar), Blitz / Combo modes, Daily Boss, Important — timer resume correctness (Fix #9), Master mode, Survival mode — per-phase timer

### Community 70 - "IapPurchaseAdapter"
Cohesion: 0.29
Nodes (6): Persistence Schema Audit, RT-005 Coverage, RT-007 Coverage, Schema Table, Scope Notes, Verified Findings

### Community 71 - "NumberType"
Cohesion: 0.29
Nodes (7): Phase 1: Foundation, Phase 2: True / False, Phase 3: Complete, Phase 4: Shuffle, Master, Daily Boss, Phase 5: Mistake Review And Boss Collection, Phase 6: Tutorial And Polish, Phase Checklist

### Community 72 - "Operation"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 73 - "QuestionGenerator"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 74 - "SettingsService"
Cohesion: 0.33
Nodes (6): 1. Operations & number ranges (exact, per difficulty), Addition, Division, Fill-in-the-blank variant, Multiplication, Subtraction

### Community 75 - "ShopItem"
Cohesion: 0.33
Nodes (6): `AnswerSubmission`, `BossCollectionEntry`, `MistakeRecord`, New Types, `QuestionAttempt`, `QuestionFormat`

### Community 76 - "SkillData"
Cohesion: 0.40
Nodes (5): 4. Scoring system, Base points, Combo multiplier — TWO DIFFERENT SYSTEMS (don't conflate them), Double points power-up interaction, Per-mode speed bonus (added to base before multipliers)

### Community 77 - "UI Widgets"
Cohesion: 0.40
Nodes (5): `ChoiceAnswerGrid`, `CompleteKeypad`, `QuestionFormatBadge`, `TrueFalseAnswerGrid`, UI Widgets

### Community 78 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 79 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 80 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

### Community 81 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 82 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 83 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

### Community 84 - "Achievement Trigger Audit"
Cohesion: 0.50
Nodes (3): Achievement Trigger Audit, Confirmed Fixes, Regression Proof

### Community 85 - "12. Coin shop — exact items and prices"
Cohesion: 0.50
Nodes (4): 12. Coin shop — exact items and prices, Avatars (permanent unlock, 200–400 coins), Hats (permanent unlock, 100–300 coins), Packs (special handling — NOT simple permanent unlocks)

### Community 86 - "8. Adaptive difficulty / mastery system — exact constants"
Cohesion: 0.50
Nodes (4): 8. Adaptive difficulty / mastery system — exact constants, How `adaptLvl` (the 0–10 difficulty dial) is derived, Running-sum optimization (Fix #30), Secondary fine-grained nudge (Fix #10)

### Community 87 - "Answer Evaluation"
Cohesion: 0.50
Nodes (4): Answer Evaluation, Choice 4, Complete, True / False

### Community 88 - "Engine Flow"
Cohesion: 0.50
Nodes (4): Compatibility wrapper, Current simplified flow, Engine Flow, Target v1.1 flow

### Community 89 - "Format Selection Rules"
Cohesion: 0.50
Nodes (4): Daily Boss, Format Selection Rules, Master mode, Normal modes

### Community 90 - "Testing Blueprint"
Cohesion: 0.50
Nodes (4): Manual QA, New Unit Tests, Testing Blueprint, Widget Tests

### Community 95 - "State Changes"
Cohesion: 0.67
Nodes (3): `GameState`, `RuntimeState`, State Changes

## Knowledge Gaps
- **1545 isolated node(s):** `build_start`, `build_end`, `file:///C:/Users/Strik/Downloads/flutter/bin/cache/dart-sdk/version`, `file:///D:/FlutterProjects/math_challenge_flutter_repo/.dart_tool/package_config.json`, `file:///D:/FlutterProjects/math_challenge_flutter_repo/pubspec.yaml` (+1540 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SettingsService` connect `StatelessWidget` to `game_state.dart`, `numtype_screen.dart`, `State`, `game_screen.dart`, `player_screen.dart`, `modals.dart`, `GameState`, `common.dart`, `audio.dart`, `settings.dart`, `visual_parity_test.dart`, `config_screen.dart`, `main.dart`, `menu_screen.dart`, `celebration_overlay.dart`?**
  _High betweenness centrality (0.067) - this node is a cross-community bridge._
- **Why does `GameState` connect `GameState` to `game_state.dart`, `numtype_screen.dart`, `State`, `game_screen.dart`, `player_screen.dart`, `modals.dart`, `visual_parity_test.dart`, `config_screen.dart`, `main.dart`, `menu_screen.dart`, `celebration_overlay.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `AdMobService` connect `AdMobService` to `game_state.dart`, `main.dart`, `admob.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `build_start`, `build_end`, `file:///C:/Users/Strik/Downloads/flutter/bin/cache/dart-sdk/version` to the rest of the system?**
  _1545 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `game_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007194244604316547 - nodes in this community are weakly interconnected._
- **Should `modals.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.022727272727272728 - nodes in this community are weakly interconnected._
- **Should `iap.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02631578947368421 - nodes in this community are weakly interconnected._