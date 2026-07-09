# Post-P0 Cleanup + Teacher Polish Checklist

Status: checklist artifact only. Do not start implementation until this is approved.

Sources:
- POST-P0 CLEANUP PLAN WITH VERIFICATION
- PHASE 1.5 - TEACHER APPROVED POLISH

Working rules:
- Verify each issue in the current repo before editing.
- If an issue is absent, mark it verified absent and skip it.
- Fix only the confirmed issue.
- Do not change gameplay, scoring, timers, question generation, difficulty, Survival, Master, Daily Boss mechanics, achievements, coins, rewards, shop prices, AdMob, IAP, GameState architecture, splash/icon color, radius styling, visual identity, or big module structure.
- Stop after Phase 1 unless Phase 1.5 is explicitly approved to start.

## Preflight

- [ ] Run `git status --short`.
- [ ] Record existing modified, deleted, and untracked files.
- [ ] Confirm no unrelated dirty files are touched.
- [ ] Run graph/navigation checks only as needed before editing.

## Phase 1 - Safe Post-P0 Hygiene

Goal: safe cleanup before Play internal testing.

### 1. README Cleanup

- [ ] Search README for stale content:
  - [ ] `com/example`
  - [ ] `com.example`
  - [ ] `AdMob not yet integrated`
  - [ ] `placeholder only`
  - [ ] old package paths
- [ ] If found, update to `com.mohamedk.mathchallenge`.
- [ ] If found, remove stale AdMob placeholder wording.
- [ ] Preserve useful build/release instructions.
- [ ] Document release signing / `key.properties` setup if missing.
- [ ] If none found, mark verified absent.

### 2. .gitignore Cleanup

- [ ] Verify `.gitignore` contains:
  - [ ] `key.properties`
  - [ ] `android/key.properties`
  - [ ] `*.jks`
  - [ ] `*.keystore`
  - [ ] `*.salive`
  - [ ] `p0_*.txt`
  - [ ] `p0_*.png`
  - [ ] `release_test_*.txt`
  - [ ] `release_test_*.xml`
  - [ ] `release_white_screen_*.txt`
  - [ ] `debug_*_log.txt`
  - [ ] `debug_*_screenshot*.png`
- [ ] Add only missing entries.

### 3. Generated Files Tracked By Git

- [ ] Run:
  - [ ] `git ls-files -- p0_*.txt p0_*.png release_test_*.txt release_test_*.xml release_white_screen_*.txt debug_*_log.txt debug_*_screenshot*.png *.salive`
- [ ] If any are tracked, remove from git tracking only with `git rm --cached`.
- [ ] Do not delete useful local files unless necessary.
- [ ] If none are tracked, mark verified absent.

### 4. Modal Price Test Assertion

- [ ] Check whether `test/modal_behavior_test.dart` still expects `Price unavailable`.
- [ ] Check whether the test uses `DevIapPurchaseAdapter`.
- [ ] Check whether `DevIapPurchaseAdapter.priceFor` returns `Test price`.
- [ ] If all true, update the test only:
  - [ ] `expect(find.text('Test price'), findsWidgets);`
  - [ ] `expect(find.text('Price unavailable'), findsNothing);`
- [ ] Confirm hardcoded IAP price checks remain absent:
  - [ ] `$0.99`
  - [ ] `$3.99`
  - [ ] `$7.99`
  - [ ] `$1.99`
- [ ] Do not change production IAP code.

### 5. Website app-ads.txt

Website/domain task only. Do not change Flutter app code for this item.

- [ ] Create or verify this file exists at the website root:
  - [ ] `https://mathchallenge.me/app-ads.txt`
- [ ] Required plain-text content:

```text
google.com, pub-5674349229505017, DIRECT, f08c47fec0942fa0
```

- [ ] Do not wrap it in HTML.
- [ ] Do not place it under `/privacy` or `/support`.
- [ ] It must return HTTP 200.
- [ ] It must be plain text.
- [ ] After deploy, open the URL in browser and confirm the exact line appears.
- [ ] Then click `Check for updates` in AdMob.

### Phase 1 Validation
- [ ] `flutter test test/modal_behavior_test.dart --reporter compact`
- [ ] `flutter test test/production_safety_config_test.dart --reporter compact`
- [ ] `flutter test --reporter compact`
- [ ] `flutter analyze`
- [ ] `flutter build apk --release`
- [ ] `flutter build appbundle --release`

Phase 1 final status target: `Post-P0 Hygiene Cleanup - VERIFIED`

## Phase 1.5 - Teacher Approved Polish

Status: do not start until explicitly approved after Phase 1.

Goal: small child-friendly, teacher-friendly polish only.

### 1. Settings Support Links

- [ ] Find where Settings / Help / About text currently lives.
- [ ] Check whether a link-opening utility/package already exists.
- [ ] If no link-opening package exists, report before adding a dependency.
- [ ] Add a small Support / About section without redesigning Settings:
  - [ ] `support@mathchallenge.me`
  - [ ] `https://mathchallenge.me`
- [ ] Email tap opens `mailto:support@mathchallenge.me`.
- [ ] Website tap opens `https://mathchallenge.me`.
- [ ] If opening fails, show `Could not open link.`

### 2. Child-Friendly Help Text

- [ ] Find existing Help / About / Settings / Daily Boss / Master info areas.
- [ ] Add or improve short help text for:
  - [ ] How to play
  - [ ] Boss fights
  - [ ] Hearts / lives
  - [ ] Coins and rewards
  - [ ] Power-ups
- [ ] Boss copy must stay mechanically accurate:
  - [ ] Defeat the boss by answering enough questions correctly.
  - [ ] Wrong answers or timeouts cost hearts.
  - [ ] Reach the goal before your hearts run out to win.
- [ ] Do not describe boss fights as score-based.

### 3. Vocabulary And Tone Pass

- [ ] Review child-facing text in:
  - [ ] Settings
  - [ ] Help / About
  - [ ] Daily Boss
  - [ ] Master Mode
  - [ ] Results modal
  - [ ] Shop
  - [ ] Player Setup
  - [ ] error / failure messages
- [ ] Prefer short, friendly, encouraging wording.
- [ ] Do not change mechanics, rewards, prices, IAP, AdMob, or achievements.

### 4. Legibility Pass

- [ ] Check small-screen readability in:
  - [ ] Settings
  - [ ] Help / About
  - [ ] Daily Boss
  - [ ] Master Mode
  - [ ] Results modal
  - [ ] Shop
  - [ ] Player Setup
- [ ] Fix only obvious overflow, clipped labels, cramped important text, or bad wrapping.
- [ ] Do not redesign layouts.

### 5. Sound Usefulness Check

- [ ] Confirm correct answer sound is useful.
- [ ] Confirm wrong answer sound is not harsh.
- [ ] Confirm boss / celebration sounds are not excessive.
- [ ] Confirm automatic reward sounds are not noisy.
- [ ] Confirm reduce motion / low performance behavior is respected where relevant.
- [ ] If no issue is found, report `Sound effects checked; no code change needed.`

### 6. Optional Educational Microcopy

- [ ] If there is a safe Help / About location, add one short line:
  - [ ] `Practice addition, subtraction, multiplication, and division through quick challenges and boss battles.`
- [ ] Do not add marketing-heavy text.

### Phase 1.5 Validation

- [ ] `flutter test --reporter compact`
- [ ] `flutter analyze`
- [ ] `flutter build apk --release`
- [ ] `flutter build appbundle --release`
- [ ] If a link-opening dependency is added, confirm Android still builds.
- [ ] If a link-opening dependency is added, confirm no unnecessary sensitive permissions were introduced.

Phase 1.5 final status target: `Teacher Approved Polish - VERIFIED`

## Later Phases - Not Before Internal Testing

### Phase 2 - Avatar Typing Verification

- [ ] Search:
  - [ ] `git grep -n "Object avatar" -- lib test`
  - [ ] `git grep -n "Object .*avatar" -- lib test`
  - [ ] `git grep -n "dynamic .*avatar" -- lib test`
  - [ ] `git grep -n "avatar;" -- lib/models lib/screens lib/widgets`
- [ ] If absent, mark verified absent.
- [ ] If present, fix only unsafe avatar typing and preserve avatar behavior.
- [ ] Validate with `flutter test --reporter compact` and `flutter analyze`.

### Phase 3 - Animation Controller Mutation Verification

- [ ] Inspect `_BossCircle`.
- [ ] Inspect `_FloatingShieldBadge`.
- [ ] Look for controller state mutation inside `build()`.
- [ ] If absent, mark verified absent.
- [ ] If present, move mutation to lifecycle methods only.
- [ ] Validate with `flutter test test/feedback_layer_test.dart --reporter compact`, full tests, and analyze.

### Phase 4 - Broad `context.watch` Verification

- [ ] Search:
  - [ ] `git grep -n "context.watch<SettingsService>" -- lib`
  - [ ] `git grep -n "context.watch<GameState>" -- lib/screens/game_screen.dart lib/widgets`
- [ ] If already narrow enough, mark no change needed.
- [ ] If broad watches remain, replace only safe cases with `context.select` or `Selector`.
- [ ] Validate with full tests and analyze.

### Phase 5 - Constants / Small Code Quality Verification

- [ ] Search for endless sentinels:
  - [ ] `git grep -n "99999" -- lib test`
  - [ ] `git grep -n "999999999" -- lib test`
- [ ] Search AvatarPool random:
  - [ ] `git grep -n "millisecondsSinceEpoch" -- lib test`
  - [ ] `git grep -n "AvatarPool.random" -- lib test`
- [ ] Search and inspect `numTypeUnlocked`:
  - [ ] `git grep -n "numTypeUnlocked" -- lib test`
- [ ] Search `TextPainter` in radar code:
  - [ ] `git grep -n "TextPainter" -- lib/widgets/modals.dart lib`
- [ ] Fix only verified issues.
- [ ] Validate with full tests and analyze.

### Phase 6 - Tooling

- [ ] Verify whether `integration_test` exists.
- [ ] If missing, add one basic smoke test only.
- [ ] Verify whether `.github/workflows` exists.
- [ ] If missing, add simple CI for pub get, tests, and analyze.
- [ ] Do not add signed release builds without safe secrets.
- [ ] Validate with full tests and analyze.

## Report Template

For each phase:
- Issue checked:
- Search command / result:
- Fixed, skipped, or verified absent:
- Files changed:
- Tests run:
- Behavior safety confirmation:
- Unresolved items and why:





