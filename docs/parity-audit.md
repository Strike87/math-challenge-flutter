# Math Challenge Flutter Parity Audit

Date: 2026-06-25

Canonical working tracker: `docs\behavioral-parity-tracker.md`

Note: this file is the broad architectural and historical parity reference. Do not use it as the living implementation tracker. Update it only when project architecture or product scope changes. Use the Behavioral Parity Tracker for active task status, confidence levels, source mappings, approved Flutter-only additions, regression tests, ownership, freeze status, and dependency ordering.

Original source of truth: `C:\Users\Strik\math-challenge\www\index.html`

Flutter implementation snapshot: `C:\Users\Strik\math_challenge_flutter`

This audit defines the work needed to make the Flutter version a 100% clone of the original game, while keeping the structure strong enough for future updates. A feature should only be considered complete when the rule behavior, visual intent, persistent state, edge cases, emoji/icons, sound/animation feedback, and release services match the original or are intentionally improved.

## Status Legend

| Status | Meaning |
| --- | --- |
| Complete | Current Flutter behavior appears equivalent to the original. |
| Partial | The feature exists but has missing details, weaker UX, or behavior differences. |
| Missing | Not implemented in Flutter yet. |
| Improved | Flutter intentionally goes beyond the original and should be preserved unless it breaks clone parity. |
| Needs test | Behavior appears present but must be verified with automated tests or device testing. |

## Executive Summary

The Flutter project already has a strong base. It contains the main screen flow, modal set, game state engine, question generator, saved settings, player setup, avatar builder, achievements, daily boss, master challenge, daily challenges, shop categories, audio service, haptics, and responsive UI components.

The Flutter version is not yet a 100% clone. The biggest gaps are monetization services, AdMob banners/interstitials/rewarded ads, real IAP product handling, confetti, exact celebration layering, shop buy-coin tab, rewarded-ad cooldown behavior, persistent power-up packs, exact stage story copy, exact avatar builder behavior, exact emoji/icon parity, and screen-by-screen visual matching.

The most important next step is not random implementation. We should lock a parity checklist, then work feature groups in this order: core game behavior, UI/visual clone, emoji/confetti/audio feedback, shop/economy, AdMob/IAP, then release QA.

## Source Inventory

### Original Primary Screens

The original HTML game has these primary screens:

| Original screen | Original anchor | Flutter equivalent | Status | Notes |
| --- | --- | --- | --- | --- |
| Main menu | `menuScreen` around line 5732 | `lib\screens\menu_screen.dart` | Partial | Structure exists. Needs exact header, campaign card, quick practice, bottom nav, spacing, and icon/emoji parity pass. |
| Number type menu | `numTypeScreen` around line 5838 | `lib\screens\numtype_screen.dart` | Partial | Natural/integers/rationals flow exists. Need tablet layout parity and locked-price behavior verification. |
| Game config | `configScreen` around line 5875 | `lib\screens\config_screen.dart` | Partial | Core controls exist. Need exact button states, labels, adaptive toggle behavior, and visual density parity. |
| Player setup | `playerScreen` around line 5945 | `lib\screens\player_screen.dart` | Partial | Player setup exists. Needs exact avatar carousel, customize button behavior, 1P/2P layout, and tablet pass. |
| Gameplay | `gameScreen` around line 5977 | `lib\screens\game_screen.dart` | Partial | Core gameplay exists. Needs exact HUD, boss/timer/prompt/answer layout, power-up HUD behavior, confetti, and feedback parity. |

### Original Modal Surfaces

The original has 13 modal surfaces. Flutter already has matching modal classes, which is a good structural base.

| Original modal | Original anchor | Flutter equivalent | Status | Notes |
| --- | --- | --- | --- | --- |
| Settings | `settingsModal` around line 6053 | `SettingsModal` | Partial | Toggles exist. Need verify theme, dyslexia, colorblind, reduce motion, low performance, and sound behavior apply globally. |
| Master intro | `masterIntroModal` around line 6123 | `MasterIntroModal` | Partial | Present. Needs exact copy, stage data display, and boss styling. |
| Daily Boss | `dailyBossModal` around line 6134 | `DailyBossModal` | Partial | Present. Rules now say 3 hearts. Need exact reward/status/copy and daily claim behavior tests. |
| Stage cleared | `stageClearedModal` around line 6155 | `StageClearedModal` | Partial | Present but generic. Original has richer stage-specific story text. |
| Win/results | `winModal` around line 6163 | `WinModal` | Partial | Present. Needs exact reward, ranking, mode-specific titles, and result table parity. |
| Quit confirm | `quitConfirmModal` around line 6176 | `QuitConfirmModal` | Complete / Needs test | Exists. Verify exact navigation outcome and gameplay pause behavior. |
| Hall of Fame | `highScoreModal` around line 6187 | `HighScoreModal` | Partial | Exists. Need verify 1P/2P tables, names, avatars, and sorting match original. |
| Achievements | `achievementsModal` around line 6195 | `AchievementsModal` | Partial | Exists. Need exact icons, descriptions, locked/unlocked styling, and reward display parity. |
| Tutorial | `tutorialModal` around line 6203 | `TutorialModal` | Partial | Present but likely simplified. Needs exact tutorial content and visual cards. |
| Avatar Builder | `avatarBuilderModal` around line 6235 | `AvatarBuilderModal` | Partial | Core builder exists. Needs exact player tabs, emoji sets, color behavior, save/equip behavior, and preview layering. |
| Skill Dashboard | `skillDashboardModal` around line 6297 | `SkillDashboardModal` | Partial | Exists. Need verify operation progress, badges, daily progress, and persistence. |
| Coin Shop | `coinShopModal` around line 6309 | `CoinShopModal` | Partial | Exists but not clone-complete. Missing real IAP tab, rewarded ad handling, and possibly exact tabs. |
| Daily Challenges | `dailyChallengesModal` around line 6395 | `DailyChallengesModal` | Partial | Exists. Need daily reset/target/reward behavior tests. |

## Feature Parity Matrix

### 1. Navigation And Screen Flow

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| App opens to main menu | Splash fades into menu; no ad on menu. | Partial | Flutter app opens to menu. Need compare launch/splash/native boot experience separately if Flutter release build will ship. |
| Header with coin pill and settings | Original uses settings button, coin display, and orange equals icon branding. | Partial | Confirm Flutter header matches exact orange equals icon, sizing, spacing, and tap targets. |
| Campaign cards | Master Challenge and Daily Boss cards. | Partial | Present, but need exact copy, icons, disabled/claimed state, and responsive widths. |
| Quick Practice grid | Addition, subtraction, multiplication, division, mixed operations bar. | Partial | Present/likely present. Need exact colors, icons, order, and mixed bar dimensions. |
| Bottom nav actions | Hall of Fame, achievements, shop, skills, daily. | Partial | Present through modals, but exact icons/emoji labels and button treatment need clone pass. |
| Back/quit flow | Quit confirm during game. | Needs test | Verify Android back button, modal dismissal, and active timer pause/resume behavior. |

### 2. Number Type Menu

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Natural numbers | Available by default. | Complete / Needs test | Verify exact operation ranges. |
| Integers unlock | Locked behind 50 coins. | Partial | Verify price, unlock persistence, button state, and insufficient-coin message. |
| Rationals unlock | Locked behind 100 coins. | Partial | Verify price, unlock persistence, button state, and insufficient-coin message. |
| Tablet layout | Original had known tablet issues. | Partial | Do dedicated tablet screenshot comparison after visual pass. |

### 3. Configuration Screen

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Player count | 1 or 2 players. | Complete / Needs test | Verify 2P state resets and scorecards. |
| Game modes | Standard, Blitz, Death, Survival, Combo. | Partial | Logic exists. Need tests for timer/lives/combo scoring edge cases. |
| Difficulty | Easy, Medium, Hard. | Complete / Needs test | Verify range/timer/scoring parity. |
| Question count | 10, 15, 20, 25. | Complete / Needs test | Verify result condition and progress text. |
| Adaptive difficulty | Toggle exists in original. | Partial | Verify Flutter implements same adaptive adjustment rules, not just the setting. |
| Banner removed from config | Original final behavior hides banner on config screen. | Missing / Not applicable yet | No Flutter AdMob service yet. When added, config must stay banner-free. |

### 4. Player Setup And Avatar Selection

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Player names | Persisted names for P1/P2. | Partial | Verify storage keys and defaults match original migration expectations. |
| Default avatars | P1 dog, P2 frog/cat depending original saved fallback. | Partial | Verify exact defaults after clean install. |
| Avatar carousel | Horizontal emoji selection plus custom avatar slot. | Partial | Need exact scroll behavior, size, selected state, and keyboard/touch behavior. |
| Customize button | Opens avatar builder for selected player. | Partial | Present. Need exact builder pid flow and two-player switching behavior. |
| Shop-unlocked avatars | Bought avatars appear in avatar picker/builder. | Partial | Present but needs tests after purchase/unlock. |

### 5. Core Game Rules

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Standard mode | Ends after target question count. | Complete / Needs test | Add test for score and result trigger. |
| Blitz mode | 60 second total timer. | Partial | Verify timer ticks, end state, and daily challenge `blitz_15`. |
| Death mode | Wrong answer ends run. | Partial | Verify no accidental lives behavior. |
| Survival mode | Lives-based mode with progress. | Partial | Verify original lives count, wrong-answer handling, and survivor achievement. |
| Combo mode | Combo thresholds and score multipliers. | Partial | Need exact threshold tests: 3, 5, 10 with 2x, 3x, 5x. |
| Two-player flow | Alternating/current player flow with separate scorecards. | Partial | Need detailed 2P tests and visual clone pass. |
| Timer per question | Base by difficulty, min 3000 ms, penalty divisor 3. | Partial | Verify exact timer constants and adaptive changes. |
| Scoring | Base 10, fast bonus, streak bonus, combo multiplier. | Partial | Add scoring unit tests for all modes. |
| Power-up every 3 correct | Original grants power-up interval 3. | Partial | Verify Flutter grants and displays matching power-ups. |
| Power-up behavior | Skip, time, fifty-fifty, shield. | Partial | Verify each power-up changes state and UI like original. |

### 6. Math Engine

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Addition/subtraction/multiplication/division | Difficulty-based ranges. | Partial | Question generator exists. Need exact range comparison against original. |
| Mixed operations | Random operation mix. | Partial | Verify includes same operation set and division constraints. |
| Natural numbers | Whole positive ranges. | Partial | Need range tests. |
| Integers | Negative values allowed. | Partial | Need generated-answer tests. |
| Rationals | Fraction/decimal style answers. | Partial | Need formatting and distractor parity tests. |
| Answer choices | Correct answer plus distractors, shuffled. | Partial | Verify distractor uniqueness and button position randomization. |
| Daily Boss fresh questions | Same boss per date, fresh questions per retry. | Complete / Needs test | Recent fix aligns with original. Add regression test. |

### 7. Master Challenge

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| 5 stages | Jungle, River Crossing, Ancient Ruins, Dragon's Cave, Treasure Vault. | Complete / Needs test | Stage data exists. Verify exact names, bosses, goals, timers, operation, number type. |
| Stage boss icons | 🦍, 🐊, 🗿, 🐲, 🧞. | Partial | Verify exact emoji rendering and HUD placement. |
| Stage-specific atmosphere | Original uses themed `atm-*` backgrounds. | Missing / Partial | Flutter needs visual theme equivalents for each stage. |
| Stage clear flow | Clear stage, show stage modal, advance. | Partial | Present but story/copy needs exact clone. |
| Math Wizard achievement | Unlocks after completing Stage 3. | Complete / Needs test | Recent fix applied; add regression test. |
| Math Legend achievement | Unlocks after beating all 5 stages. | Complete / Needs test | Verify reward and toast. |
| Extra life pack | Applies to Master mode. | Partial | Flutter stores life bonus; verify exact consumption timing. |

### 8. Daily Boss

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Daily deterministic boss | Boss selected from date. | Complete / Needs test | Recent local date hash fix applied. |
| Boss roster | Lava Dragon, Clockwork Sphinx, Frost Kraken, Storm Golem, Solar Phoenix, Nebula Hydra. | Complete / Needs test | Verify all data fields exactly. |
| 3 hearts | Daily Boss always uses 3 hearts. | Complete / Needs test | Recent fix applied. |
| Fresh questions per retry | Same boss, random questions each attempt. | Complete / Needs test | Verify retry produces different question sequence. |
| Once-per-day reward | Reward only once per local day. | Complete / Needs test | Recent storage-key fix applied. |
| Daily Boss achievement | Unlock on clear. | Complete / Needs test | Verify exact toast/reward behavior. |
| Daily Boss modal | Shows boss, operation, difficulty, number type, reward, claimed state. | Partial | Needs exact copy and visual clone. |

### 9. Daily Challenges And Skill Dashboard

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Challenge list | blitz_15, streak_7, division_10, master_stage, daily_boss, perfect_5. | Partial | Verify exact targets, rewards, icons, text. |
| Daily reset | Challenges reset by day. | Partial / Needs test | Verify Flutter resets on local date like original. |
| Progress tracking | Progress increments from relevant gameplay events. | Partial | Recent master-stage update added. Need tests for all six challenge types. |
| Claim rewards | Coins paid once per challenge. | Partial | Verify claim flags and no double-claim. |
| Skill dashboard | Tracks operation skill and progress. | Partial | Recent JSON persistence fix applied. Need exact visual and calculation parity. |

### 10. Achievements

| Achievement | Original trigger | Flutter status | Required work |
| --- | --- | --- | --- |
| First Win | Win first game. | Needs test | Verify trigger/reward. |
| Speed Demon | Fast win / fast answer condition. | Needs test | Verify exact threshold. |
| Perfect Score | No wrong answers. | Needs test | Verify all modes. |
| Streak Master | Streak milestone. | Needs test | Verify threshold. |
| Power User | Use power-up. | Needs test | Verify every power-up path. |
| Math Wizard | Complete Master Stage 3. | Complete / Needs test | Recent fix applied. |
| Persistent | Play multiple games / persistence trigger. | Needs test | Verify exact original condition. |
| Quick Learner | Learning/progress trigger. | Needs test | Verify exact original condition. |
| Survivor | Survival mode trigger. | Needs test | Verify exact survival threshold. |
| Avatar Artist | Create custom avatar. | Complete / Needs test | Verify save/equip unlock. |
| Skill Master | Skill dashboard mastery. | Needs test | Verify exact operation threshold. |
| Daily Grind | Daily challenges. | Needs test | Verify exact claim count/streak. |
| Daily Boss | Clear Daily Boss. | Complete / Needs test | Verify reward and once-only toast. |
| Math Legend | Beat all Master stages. | Complete / Needs test | Verify final stage only. |

### 11. Shop, Economy, IAP, And Ads

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Coin balance | Earn/spend coins, persisted. | Partial | Present. Need storage migration test against original keys. |
| Avatar shop | Dragon, Robot, Alien, Ninja, Wizard, Unicorn. | Partial | Present likely. Verify exact prices, icons, labels. |
| Hat shop | Crown, Wizard, Top Hat, Halo, Fire, Star. | Partial | Verify exact emoji. Original wizard hat uses `🧙‍♂️`; Flutter may use `🧙`. |
| Packs tab | Power Pack, daily bonus, extra life. | Partial | UI exists. Behavior incomplete. |
| Power Pack | Costs 500, gives 5 of each power-up for next game(s). | Missing / Partial | Flutter currently needs persistent bonus behavior matching original. |
| Daily bonus pack | Watch rewarded ad for +100 coins, daily/cooldown controlled. | Missing / Partial | Flutter currently needs real rewarded ad and daily claim/cooldown behavior. |
| Extra life pack | Costs 450, consumable Master life bonus. | Partial | Verify storage and consumption. |
| Buy coins tab | Original IAP tab has coin products and restore purchases. | Missing | Add real buycoin tab and product cards. |
| IAP product IDs | `100_coins`, `500_coins`, `1200_coins`, `ads_remove`. | Missing | Add Flutter `in_app_purchase` service with exact IDs and purchase option handling if needed. |
| IAP purchase option IDs | `100-coins-buy`, `500-coins-buy`, `1200-coins-buy`, `ads-remove-buy`. | Missing | Needed for Play Console one-time products if Flutter billing API exposes offer details. |
| Remove ads | Non-consumable, restores across installs. | Missing | Add purchase, restore, and local entitlement application. |
| Restore purchases | Required for remove ads. | Missing | Add button and auto-restore on startup. |
| AdMob banner | Original shows banner only on number type and player setup. | Missing | Add `google_mobile_ads` and strict screen/modal gating. |
| AdMob interstitial | Original preloads and shows at safe moments. | Missing | Add service with no-crash no-fill handling. |
| AdMob rewarded | Original used for daily coin bonus. | Missing | Add rewarded flow before granting +100 coins. |
| Real ad IDs | Original web project has production IDs. | Missing in Flutter | Add release-safe config, no hardcoded test-only IDs in production. |

### 12. Avatar Builder, Emoji, And Icons

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Base emoji set | 🐶 🐱 🦁 🐸 🐼 🦊 🐯 🦋 🐙 🦉 🐧 plus shop unlocks. | Partial / Improved | Flutter has richer categories. Preserve improvements, but first category must exactly include original defaults. |
| Hat set | Empty, 🎓, 🧢, 🪖, 👒, 🎀, 🌸 plus shop hats. | Partial | Verify exact set/order. |
| Accessory set | Empty, 👓, 🕶️, 🧣, 🧤, 👑, 💍, 📿, 🎀, 🪭, ⌚, 🧸, 💎, 🏅, 🪆. | Partial | Verify exact set/order. |
| Color overlays | Original color set with null and 8 colors. | Partial | Verify exact hex values and preview behavior. |
| Preview layering | Base, color overlay, hat, accessory layered with relative positions. | Partial | Flutter preview needs screenshot comparison. |
| Player tabs in builder | Original builder can switch P1/P2 inside modal. | Partial | Flutter opens builder for a pid. Need decide whether to clone tabs exactly. |
| Big emoji feedback | Original shows large emoji feedback during gameplay. | Partial | Flutter has `BigEmojiOverlay`. Need exact timing/content/position. |
| Header orange equals icon | Original requested orange equals icon in header. | Partial | Verify Flutter header uses exact same symbol asset/treatment. |
| Button icons | Original uses emoji/icons on many controls. | Partial | Audit every button: menu, setup, shop, modal close, power-ups, bottom nav. |

### 13. Confetti, Celebration, Audio, And Haptics

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Confetti canvas | Original has `confettiCanvas`, resize handling, reduce-motion/low-performance guards. | Missing | Add Flutter `confetti` package or custom particle layer. Must respect reduce motion and low performance. |
| Confetti trigger | Original triggers celebration on win/stage/daily boss/important rewards. | Missing | Add centralized `CelebrationService` or state event. |
| Big emoji celebration | Original shows large emoji feedback like 🎉. | Partial | Present. Need exact trigger map and animation duration. |
| Toast feedback | Original has rich toasts for shop, achievements, rewards. | Partial | Present but exact content/timing needs audit. |
| Audio | Original sound effects for correct/wrong/win/click. | Partial | Flutter `AudioService` exists. Need exact event mapping and settings behavior. |
| Haptics | Original vibrates on key actions. | Partial | Flutter uses vibration dependency. Need exact reduced/disabled behavior and platform fallback. |
| Reduce motion | Original corrected `html.reduce-motion` selector and suppresses animation speed/confetti. | Partial | Flutter setting exists; must be wired to every animation and future confetti layer. |

### 14. Visual Theme And Responsive Layout

| Feature | Original behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| Neo theme | Bright, playful math-game UI with cards, colorful buttons, emoji. | Partial | Flutter has theme system. Need screen-by-screen screenshot comparison. |
| Dark theme | Original supports dark mode. | Partial | Flutter setting exists. Need visual QA. |
| Dyslexia font | Original supports dyslexia-friendly mode. | Partial | Verify Flutter font/style swap. |
| Colorblind mode | Original supports colorblind mode. | Partial | Verify all answer/status colors still distinguishable. |
| Low performance mode | Original reduces costly visuals. | Partial | Flutter setting exists. Need connect to animations/confetti. |
| Tablet layout | Original had tablet-specific issues fixed over time. | Partial | Need tablet goldens for number type, config, player setup, game. |
| Text fitting | Original had lots of mobile/tablet text fitting work. | Partial | Verify all button labels in English fit at common device sizes. |
| Safe areas / edge-to-edge | Original Android version had edge-to-edge fixes. | Partial | Flutter needs SafeArea/insets QA on Android 15+. |

### 15. Persistence And Migration

| Feature | Original storage key | Flutter status | Required work |
| --- | --- | --- | --- |
| Coins | `mc_coins` | Complete / Needs test | Verify load/save. |
| Ads removed | `mc_adsRemoved` | Partial | Flag exists; no real IAP/ad service yet. |
| Achievements | `mc_achievements` | Complete / Needs test | Recent JSON fix applied with legacy fallback. |
| Daily Boss claim | `mc_dailyBossClaimed` | Complete / Needs test | Recent fix applied with legacy fallback. |
| Daily progress | Original JSON style keys | Partial | Recent persistence fix applied. Add reset-by-date tests. |
| Skill map | Original JSON style keys | Complete / Needs test | Recent persistence fix applied. |
| Avatar custom P1/P2 | `mc_avatarCustom1`, `mc_avatarCustom2` | Partial | Verify compatibility and exact object fields. |
| Unlocked avatars/hats | `mc_unlockedAvatars`, `mc_unlockedHats` | Partial | Verify encoding and migration. |
| Power-up bonus | `mc_puBonus` | Missing / Partial | Needed for Power Pack parity. |
| Extra life bonus | `mc_livesBonus` | Partial | Verify exact behavior. |
| High scores | Original high score keys | Partial | Need exact schema and migration check. |
| Settings | Theme/sound/reduce-motion keys | Partial | Verify exact compatibility or document intentional Flutter-only migration. |

### 16. Release Services And Android Integration

| Feature | Original/required behavior | Flutter status | Required work |
| --- | --- | --- | --- |
| AdMob SDK | Real banner/interstitial/rewarded ads. | Missing | Add `google_mobile_ads`, Android app ID metadata, consent/family configuration as needed. |
| IAP SDK | Google Play one-time products and restore. | Missing | Add `in_app_purchase` or chosen billing plugin. |
| Product IDs | `100_coins`, `500_coins`, `1200_coins`, `ads_remove`. | Missing | Add constants and test purchase flow. |
| Purchase option IDs | `100-coins-buy`, `500-coins-buy`, `1200-coins-buy`, `ads-remove-buy`. | Missing | Add where supported by API; otherwise document billing API limitation. |
| Launcher icon | Math Challenge icon. | Partial | Flutter launcher config exists. Verify exact original branding. |
| Splash screen | Original splash was tuned. | Partial | Flutter native splash not audited yet. |
| Android edge-to-edge | Must handle Android 15+ insets. | Partial | Flutter SafeArea likely helps, but release build needs device QA. |

## Highest Priority Clone Gaps

1. Monetization is the largest functional gap. Add AdMob, rewarded ads, IAP products, remove-ads entitlement, and restore purchases before calling the Flutter app release-ready.

2. Confetti is explicitly missing. The original has a dedicated confetti canvas and performance guards. Flutter needs a celebration layer with confetti, emoji, audio, haptics, and reduce-motion support.

3. Coin Shop is not clone-complete. It needs the buycoin tab, real purchases, restore purchases, rewarded-ad claim behavior, exact product labels, exact prices, and exact shop tabs.

4. Power Pack behavior is incomplete. Buying the pack must persist and grant five of each power-up in the same way the original does.

5. Avatar Builder needs exact parity. The current Flutter implementation is promising, but the original player tabs, emoji sets, accessory order, color values, preview layering, and save/equip behavior need an exact comparison.

6. Stage/story presentation is weaker than the original. Master stage cleared and win flows need the original stage-specific text and boss personality.

7. Visual parity needs screenshots. Every screen should be compared on phone and tablet sizes after the functionality pass.

8. Architecture should be split before the game grows much more. `GameState` is doing too much and should gradually become smaller feature services.

## Suggested Architecture For Future Updates

The Flutter project should move toward feature modules while keeping current behavior stable.

| Module | Responsibility |
| --- | --- |
| `GameState` | Thin app/session coordinator exposed to Provider. |
| `GameEngine` | Rules, scoring, timers, answer handling, mode transitions. |
| `QuestionService` | Question generation, distractors, formatting, randomization. |
| `ProgressionService` | Achievements, daily challenges, skill dashboard, rewards. |
| `EconomyService` | Coins, shop items, consumables, unlocks. |
| `AdService` | Banner/interstitial/rewarded loading, gating, lifecycle. |
| `PurchaseService` | Product query, purchase, restore, entitlement delivery. |
| `CelebrationService` | Confetti, big emoji, haptics, sounds, reduced-motion rules. |
| `AvatarService` | Base/hats/accessories/colors, custom avatar persistence. |
| `SettingsService` | Theme, sound, motion, accessibility, low-performance mode. |

Do not rewrite everything at once. Extract services only when implementing or fixing a related feature. The first good extraction candidates are `AdService`, `PurchaseService`, `CelebrationService`, and `EconomyService`.

## Test Plan Required For 100% Clone

### Unit Tests

| Area | Tests |
| --- | --- |
| Question generation | Operation ranges, division validity, rational formatting, unique choices, mixed operation distribution. |
| Scoring | Base score, fast bonus, streak bonus, combo multipliers, wrong-answer behavior. |
| Timers | Blitz total timer, per-question timers, low-time penalty, adaptive difficulty. |
| Master Challenge | Stage progression, Stage 3 Math Wizard, Stage 5 Math Legend, extra life consumption. |
| Daily Boss | Date-based boss selection, 3 hearts, fresh retry questions, once-per-day reward. |
| Daily Challenges | All six progress triggers, claim once, reset by date. |
| Shop | Unlock avatars/hats, insufficient coins, power pack delivery, extra life delivery. |
| IAP | Product constants, consumable delivery once, non-consumable restore, error handling. |
| Ads | Banner screen gating, rewarded reward only after ad completion, interstitial no-fill safety. |
| Settings | Sound, reduce motion, low performance, dyslexia, colorblind mode. |

### Widget And Golden Tests

| Surface | Needed snapshots |
| --- | --- |
| Main menu | Phone and tablet, light/dark. |
| Number type | Phone and tablet, locked/unlocked states. |
| Config | Phone and tablet, all option groups visible. |
| Player setup | 1P and 2P, avatar carousel, keyboard open if possible. |
| Gameplay | Standard, Blitz, Daily Boss, Master stage, 2P. |
| Avatar Builder | Base/hats/accessories/colors, player switching. |
| Coin Shop | All tabs, insufficient coins, owned state, IAP products. |
| Results | Standard win, Daily Boss clear, Master complete. |

### Device QA

| Device class | Checks |
| --- | --- |
| Small phone | No clipped text, answer buttons fit, bottom nav usable. |
| Tall phone | Menu card widths match, gameplay not edge-cramped. |
| Tablet | Number type, config, player setup, and game screens must match original design intent. |
| Android 15+ | Insets, navigation/status bars, splash, keyboard, edge-to-edge behavior. |
| Offline | IAP/ad errors handled; gameplay works. |
| Fresh install | Default state, no false purchases, daily boss generated. |

## Implementation Roadmap

### Phase 1: Lock Parity Data

Goal: make constants and copy exact.

- Compare `GameConfig` constants against original `index.html`.
- Fix any data mismatches in master levels, daily bosses, achievements, shop items, timers, scoring, and emoji.
- Add tests for every fixed constant group.
- Freeze a `clone_contract.md` file once exact constants are verified.

### Phase 2: Core Logic Parity

Goal: gameplay should behave like the original even before visual perfection.

- Add scoring/timer/mode tests.
- Add daily boss and master challenge regression tests.
- Fix Daily Challenges reset/progress if tests reveal mismatch.
- Implement Power Pack persistent delivery.
- Verify two-player behavior.

### Phase 3: UI And Visual Clone Pass

Goal: every screen should feel like the original.

- Build screenshot comparison checklist for phone and tablet.
- Match menu/header, orange equals icon, campaign cards, quick practice, bottom nav.
- Match number type, config, and player setup tablet layouts.
- Match gameplay HUD, scorecards, boss/timer circle, prompt, answer buttons, power-up HUD.
- Match modal sizes, titles, icons, and button treatments.

### Phase 4: Confetti, Emoji, Audio, Haptics

Goal: restore the game feel, not just the rules.

- Add `confetti` dependency or equivalent particle layer.
- Create one celebration controller for confetti, big emoji, sound, and haptics.
- Trigger it for wins, boss clears, stage clears, achievements, and important rewards.
- Respect reduce motion and low performance.
- Audit every emoji/icon against the original, including header equals icon and wizard hat.

### Phase 5: Shop, Ads, And IAP

Goal: release-grade economy parity.

- Add real buycoin tab.
- Add `AdService` with banner gating: number type and player setup only.
- Add rewarded flow for daily +100 coins.
- Add interstitial flow with no-fill safety.
- Add `PurchaseService`.
- Add product IDs: `100_coins`, `500_coins`, `1200_coins`, `ads_remove`.
- Add purchase option IDs where the billing API supports them: `100-coins-buy`, `500-coins-buy`, `1200-coins-buy`, `ads-remove-buy`.
- Add restore purchases and startup entitlement restore for `ads_remove`.
- Add fake/mock purchase service for tests.

### Phase 6: Release QA

Goal: prove the clone is shippable.

- Run `flutter analyze`.
- Run all tests.
- Build debug APK.
- Build release AAB.
- Test IAP in Play Console closed track.
- Test AdMob with test ads first, then production IDs only when ready.
- Run tablet and Android 15+ insets QA.

## Definition Of 100% Clone

The Flutter version can be called a 100% clone when every original feature falls into one of these buckets:

1. Implemented exactly with matching behavior, content, persistence, visuals, and feedback.
2. Intentionally improved, with the improvement documented and tested.
3. Intentionally removed from Flutter, with the reason documented.

Right now, the Flutter version is a strong foundation, not a full clone. The clone work should focus first on behavior and services, then visual and emotional parity: confetti, emoji, story copy, audio, haptics, and the tiny details that make the original feel alive.
