# Persistence Schema Audit

Date: 2026-06-27

Original source of truth: `C:\Users\Strik\math-challenge\www\index.html`

Flutter target: `C:\Users\Strik\math_challenge_flutter`

This document supports BPT-007, BPT-008, and BPT-009. RT-005 proves the active read/write compatibility decisions listed here. RT-006 proves the reset decisions against the same schema plus reset-only legacy keys. RT-007 proves old original-app data upgrades into the final Flutter keys on load.

## Scope Notes

- Original storage uses the HTML `LS` helper, which stores JSON in `localStorage`, except `mc_lowPerf`, which is written directly as a string by `localStorage.setItem`.
- Flutter storage uses `SharedPreferences` through `lib\services\storage.dart`.
- The original identifiers `mc_product_price`, `mc_purchase_approved`, `mc_receipts_ready`, and `mc_restore_receipts` are plugin listener tags, not persisted storage keys, so they are excluded from the schema table.
- v1.1 roadmap-only keys such as `mc_tf_correct_total`, `mc_complete_correct_total`, and `mc_boss_collection` are not active runtime keys in the current Flutter clone and are excluded from BPT-007.

## Schema Table

| Key | Original shape | Flutter shape | Read path | Write path | Migration decision | Reset decision | Test |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `mc_coins` | JSON number. | `int`. | Original `index.html:6737`; Flutter `lib\engine\game_state.dart:299`. | Original `index.html:6918`, `index.html:10937`, `index.html:11362`; Flutter `lib\engine\game_state.dart:336`. | Keep same key; verify numeric coercion from original JSON/local value. | Remove in BPT-008. | RT-005 coins load/save/migrate. |
| `mc_scores` | JSON array of high score objects. | JSON string list via `Storage.setObjectList`; loaded as growable `List<HighScore>`. | Original `index.html:6702`; Flutter `lib\engine\game_state.dart:304`. | Original `index.html:10562`; Flutter `lib\engine\game_state.dart:340`. | Keep same key; support original JSON array shape and keep growable working copy. | Remove in BPT-008. | RT-005 plus existing RT-004 high-score mutability regression. |
| `mc_gamesPlayed` | JSON number. | `int`. | Original `index.html:6703`; Flutter `lib\engine\game_state.dart:300`. | Original `index.html:10029`; Flutter `lib\engine\game_state.dart:337`. | Keep same key. | Remove in BPT-008. | RT-005 games-played load/save. |
| `mc_adaptLvl` | JSON number, fractional source of truth. | `double`. | Original `index.html:6704`; Flutter `lib\engine\game_state.dart:301`. | Original `index.html:10034`; Flutter `lib\engine\game_state.dart:338`. | Keep same key and preserve fractional value. | Remove in BPT-008. | RT-005 adaptive level persistence. |
| `mc_achs` -> `mc_achievements` | Original key is JSON array of `{id, unlocked}`. | Flutter key is comma string like `id=1,id2=0`. | Original `index.html:10402`; Flutter `lib\engine\game_state.dart:364`. | Original `index.html:10410`; Flutter `lib\engine\game_state.dart:339`. | Implemented: Flutter reads current key first, then legacy `mc_achs` fallback. | Remove both original and Flutter keys in BPT-008. | RT-005A. |
| `mc_skills` -> `mc_skillMap` | Original key is JSON object by operation with `easy`, `medium`, `hard`, `correct`, `count`, `mastery`, `confidence`. | Flutter key is JSON string map of `SkillData`, including `expert` and `insane`. | Original `index.html:6726`; Flutter `lib\engine\game_state.dart:386`. | Original `index.html:10030`; Flutter `lib\engine\game_state.dart:341`. | Implemented: Flutter reads current key first, then legacy `mc_skills`, defaulting missing `expert` and `insane` to 0. | Remove both original and Flutter keys in BPT-008. | RT-005B. |
| `mc_numTypeUnlocked` -> `mc_numTypeUnlocked_integers`, `mc_numTypeUnlocked_rationals` | Original key is JSON object `{integers: bool, rationals: bool}`. | Flutter uses two `int` flags, 0 or 1. | Original `index.html:6744`; Flutter `lib\engine\game_state.dart:309`. | Original `index.html:6921`; Flutter `lib\engine\game_state.dart:342`. | Implemented: original booleans migrate into split integer flags. | Remove original object and split flags in BPT-008. | RT-005C; RT-012 behavior later. |
| `mc_loginStreak` | JSON number. | `int`. | Original `index.html:6745`; Flutter `lib\engine\game_state.dart:312`. | Original `index.html:6944`; Flutter affected by `_updateLoginStreak`. | Keep same key. | Remove in BPT-008. | RT-005 streak load/save. |
| `mc_streakLastDay` -> `mc_lastLoginDay` | Original key is date string, usually `YYYY-MM-DD`. | Flutter key is integer day number. | Original `index.html:6930`; Flutter `lib\engine\game_state.dart:586`. | Original `index.html:6945`; Flutter `lib\engine\game_state.dart:593`. | Implemented: Flutter uses `mc_lastLoginDay` when present, otherwise normalizes original `mc_streakLastDay`. | Remove both keys in BPT-008. | RT-005I; RT-006 reset. |
| `mc_avatarCustom` -> `mc_avatarCustom1` | Original legacy P1 custom avatar object `{base, hat, accessory, color}`. | Flutter P1 custom avatar object under `mc_avatarCustom1`. | Original `index.html:6750`; Flutter `lib\engine\game_state.dart:313`. | Original fallback only; Flutter `lib\engine\game_state.dart:347`. | Implemented: if `mc_avatarCustom1` is absent, Flutter reads legacy `mc_avatarCustom` for P1. | Remove legacy and numbered keys in BPT-008. | RT-005G. |
| `mc_avatarCustom1` | JSON avatar object `{base, hat, accessory, color}`. | Same object encoded as JSON string. | Original `index.html:6753`; Flutter `lib\engine\game_state.dart:313`. | Original `index.html:11084`; Flutter `lib\engine\game_state.dart:347`. | Keep same logical shape. | Remove in BPT-008. | RT-005 avatar custom P1 round trip. |
| `mc_avatarCustom2` | JSON avatar object `{base, hat, accessory, color}`. | Same object encoded as JSON string. | Original `index.html:6754`; Flutter `lib\engine\game_state.dart:315`. | Original `index.html:11084`; Flutter `lib\engine\game_state.dart:348`. | Keep same logical shape. | Remove in BPT-008. | RT-005 avatar custom P2 round trip. |
| `mc_p1Data` -> `mc_p1_name`, `mc_p1_avatar` | Original player object `{name, avatar}`. Avatar may be a string or custom object. | Flutter split strings: name and avatar. | Original `index.html:6762`; Flutter `lib\engine\game_state.dart:326`. | Original `index.html:12735`; Flutter `lib\engine\game_state.dart:354`. | Implemented: split keys win when present; otherwise legacy player object is loaded. | Remove original and split keys in BPT-008. | RT-005D. |
| `mc_p2Data` -> `mc_p2_name`, `mc_p2_avatar` | Original player object `{name, avatar}`. Avatar may be a string or custom object. | Flutter split strings: name and avatar. | Original `index.html:6769`; Flutter `lib\engine\game_state.dart:328`. | Original `index.html:12736`; Flutter `lib\engine\game_state.dart:357`. | Implemented: same rule as P1. | Remove original and split keys in BPT-008. | RT-005D. |
| `mc_dailyProgress` | Original object by challenge id: `{current, completed}`. | JSON string map by id with `{current, completed}`; also supports numeric legacy values in code. | Original `index.html:6758`; Flutter `lib\engine\game_state.dart:420`. | Original `index.html:12567`; Flutter `lib\engine\game_state.dart:349`, `lib\engine\game_state.dart:513`. | Keep same logical shape; verify original object decode and completed flags. | Remove in BPT-008. | RT-005 daily progress migration. |
| `mc_dailyChallenges` | Original object `{date: Date.toDateString(), challenges: [challenge objects]}`. | JSON string object `{date: YYYY-MM-DD, challenges: [challenge ids]}`. | Original `index.html:12501`; Flutter `lib\engine\game_state.dart:490`. | Original `index.html:12511`; Flutter `lib\engine\game_state.dart:509`. | Implemented: Flutter normalizes date strings and accepts either challenge ids or challenge objects with ids; otherwise regenerates safely. | Remove in BPT-008. | RT-005H. |
| `mc_dailyCoinsDate` | Original `Date.toDateString()` string. | Flutter `YYYY-MM-DD` string. | Original `index.html:11299`; Flutter `lib\engine\game_state.dart:269`. | Original `index.html:11353`; Flutter `lib\engine\game_state.dart:1874`. | Implemented: Flutter normalizes original date strings before comparing. | Remove in BPT-008. | RT-005H. |
| `mc_dailyBossClaimed` | Original boss date key string. | Flutter `YYYY-MM-DD` string. | Original `index.html:7908`; Flutter `lib\engine\game_state.dart:609`. | Original `index.html:10044`; Flutter `lib\engine\game_state.dart:1270`. | Keep same key if date key is already `YYYY-MM-DD`; add fallback proof. | Remove in BPT-008. | RT-005 daily boss claim migration. |
| `mc_puBonus` | Original object `{time, fifty, double, shield, freeze, switch}`. | JSON string object with same keys. | Original `index.html:8257`; Flutter `lib\engine\game_state.dart:536`. | Original `index.html:11379`; Flutter `lib\engine\game_state.dart:554`. | Keep same logical shape; verify JSON object import. | Remove in BPT-008. | RT-005 power-up bonus migration; existing power-pack tests cover active behavior. |
| `mc_livesBonus` | JSON number. | `int`. | Original `index.html:8297`; Flutter `lib\engine\game_state.dart:759`. | Original `index.html:11383`; Flutter `lib\engine\game_state.dart:1908`. | Keep same key. | Remove in BPT-008. | RT-005 lives bonus migration. |
| `mc_shopOwned` | Original object map `{itemId: true}`. | Flutter `StringList` of item ids. | Original `index.html:11251`; Flutter `lib\engine\game_state.dart:322`. | Original `index.html:11371`; Flutter `lib\engine\game_state.dart:350`. | Implemented: truthy object keys migrate into a string list; false consumable entries are ignored. | Remove in BPT-008. | RT-005E; RT-011 shop behavior later. |
| `mc_unlockedAvatars` | Original JSON array of emoji strings. | Flutter `StringList`. | Original `index.html:8166`; Flutter `lib\engine\game_state.dart:323`. | Original `index.html:11388`; Flutter `lib\engine\game_state.dart:351`. | Implemented: JSON arrays and Flutter string lists both load. | Remove in BPT-008. | RT-005E. |
| `mc_unlockedHats` | Original JSON array of emoji strings. | Flutter `StringList`. | Original `index.html:11022`; Flutter `lib\engine\game_state.dart:324`. | Original `index.html:11395`; Flutter `lib\engine\game_state.dart:352`. | Implemented: JSON arrays and Flutter string lists both load. | Remove in BPT-008. | RT-005E. |
| `mc_adsRemoved` | JSON boolean, with original native store verification. | `bool`; no real Flutter IAP/ad service yet. | Original `index.html:6787`; Flutter `lib\engine\game_state.dart:325`. | Original `index.html:12252`; Flutter `lib\engine\game_state.dart:353`. | Keep key for local flag, but final trust model belongs to BPT-001/BPT-002. | Remove in BPT-008, unless platform restore rehydrates it later. | RT-005 local flag; RT-052/RT-050 service proof later. |
| `mc_iapDeliveredTxs` | JSON array of recent transaction keys. | Not currently active in Flutter. | Original `index.html:6743`; Flutter none. | Original `index.html:12210`; Flutter none. | Blocked until IAP service exists; if IAP is ported, migrate as string list or JSON array. | Remove in BPT-008. | RT-006 reset; RT-052 later. |
| `mc_lastRewardedAt` | JSON number timestamp. | Not currently active in Flutter. | Original `index.html:11715`; Flutter none. | Original `index.html:11739`; Flutter none. | Blocked until rewarded ads exist. | Remove in BPT-008. | RT-006 reset; RT-051 later. |
| `mc_adGameCount` | JSON number. | Not currently active in Flutter. | Original `index.html:11669`; Flutter none. | Original `index.html:11672`; Flutter none. | Blocked until interstitial/ad cadence exists. | Remove in BPT-008. | RT-006 reset; RT-050/RT-051 later. |
| `mc_sound` | JSON boolean. | `bool`, read into `SettingsService`. | Original `index.html:6710`; Flutter `lib\main.dart:36`. | Original `index.html:10619`; Flutter `lib\services\settings.dart:55`. | Implemented: setting toggles persist same key. | Remove in BPT-008. | RT-005F; RT-006 reset. |
| `mc_dark` | JSON boolean. | `bool`, read into `SettingsService`. | Original `index.html:7376`; Flutter `lib\main.dart:35`. | Original `index.html:10598`; Flutter `lib\services\settings.dart:49`. | Implemented: setting toggles persist same key. | Remove in BPT-008. | RT-005F; RT-006 reset. |
| `mc_vibration` | JSON boolean. | `bool`, read into `SettingsService`. | Original `index.html:6673`; Flutter `lib\main.dart:37`. | Original `index.html:7702`; Flutter `lib\services\settings.dart:61`. | Implemented: setting toggles persist same key. | Remove in BPT-008. | RT-005F; RT-006 reset. |
| `mc_dyslexia` | JSON boolean. | `bool`, read into `SettingsService`. | Original `index.html:6674`; Flutter `lib\main.dart:38`. | Original `index.html:7661`; Flutter `lib\services\settings.dart:67`. | Implemented: setting toggles persist same key. | Remove in BPT-008. | RT-005F; RT-006 reset. |
| `mc_colorblind` | JSON boolean. | `bool`, read into `SettingsService`. | Original `index.html:6675`; Flutter `lib\main.dart:39`. | Original `index.html:7667`; Flutter `lib\services\settings.dart:73`. | Implemented: setting toggles persist same key. | Remove in BPT-008. | RT-005F; RT-006 reset. |
| `mc_animSpeed` | JSON number. | `double`, read into `SettingsService`. | Original `index.html:6676`; Flutter `lib\main.dart:42`. | Original `index.html:7683`; Flutter `lib\services\settings.dart:91`. | Implemented: setting slider persists same key. | Remove in BPT-008. | RT-005F; RT-006 reset. |
| `mc_reduceMotion` | JSON boolean. | `bool`, read into `SettingsService`. | Original `index.html:6682`; Flutter `lib\main.dart:41`. | Original `index.html:7689`; Flutter `lib\services\settings.dart:85`. | Implemented: setting toggles persist same key. | Remove in BPT-008. | RT-005F; RT-006 reset. |
| `mc_lowPerf` | Raw string boolean from original direct `localStorage.setItem`; also reset key. | `bool`, read into `SettingsService`. | Original `index.html:6429`; Flutter `lib\main.dart:40`. | Original `index.html:7674`; Flutter `lib\services\settings.dart:79`. | Implemented: original `"true"`/`"false"` strings parse as bool and toggles persist bool. | Remove in BPT-008. | RT-005F; RT-005J; RT-006 reset. |
| `mc_achievements_raw` | No active original key. | Flutter fallback raw string. | Original none; Flutter `lib\engine\game_state.dart:365`. | None. | Decide whether to keep as legacy fallback or remove after `mc_achs` migration exists. | Remove in BPT-008. | RT-005 fallback cleanup decision. |
| `mc_skillMap_raw` | No active original key. | Flutter fallback raw string. | Original none; Flutter `lib\engine\game_state.dart:387`. | None. | Decide whether to keep as legacy fallback or remove after `mc_skills` migration exists. | Remove in BPT-008. | RT-005 fallback cleanup decision. |
| `mc_dailyProgress_raw` | No active original key. | Flutter fallback raw string. | Original none; Flutter `lib\engine\game_state.dart:421`. | None. | Decide whether to keep as legacy fallback or remove after original `mc_dailyProgress` migration exists. | Remove in BPT-008. | RT-005 fallback cleanup decision. |
| `mc_lastDailyBossClaimDay` | No active original key in current HTML; Flutter legacy int day fallback. | `int` day number fallback. | Original none; Flutter `lib\engine\game_state.dart:610`. | None. | Keep only as legacy fallback until daily boss claim migration is tested. | Remove in BPT-008. | RT-005 legacy boss claim fallback. |
| `mc_lastLoginDay` | No original key; Flutter-only int day number. | `int` day number. | Original none; Flutter `lib\engine\game_state.dart:586`. | Original none; Flutter `lib\engine\game_state.dart:593`. | Flutter-only replacement for `mc_streakLastDay`; migration must map original date string to this key. | Remove in BPT-008. | RT-005 login-day persistence; RT-006 reset. |
| `mc_unlocked_integers`, `mc_unlocked_rationals` | Legacy reset-only keys in original reset list; no active read/write found. | No active Flutter keys. | Original reset list only `index.html:10694`; Flutter none. | None. | Do not migrate; treat as obsolete legacy keys. | Remove in BPT-008 for cleanup. | RT-006 reset only. |

## Verified Findings

1. Flutter now reads legacy object/array keys for achievements, skill data, number-type unlocks, player data, shop ownership, unlocked avatars/hats, avatar custom data, and active daily data.
2. Settings toggles now persist through `SettingsService`.
3. `mc_lastLoginDay` is Flutter-only and is covered by the BPT-008 reset list.
4. Monetization/ad keys are original runtime keys, but Flutter has no IAP/AdMob service yet. They are documented as inactive now and tested later under RT-050, RT-051, and RT-052.

## RT-005 Coverage

- Load original `mc_achs`, save Flutter `mc_achievements`, and preserve unlocked states.
- Load original `mc_skills`, save Flutter `mc_skillMap`, and preserve mastery/count values while defaulting new fields.
- Load original `mc_numTypeUnlocked`, save split integer flags.
- Load original `mc_p1Data` and `mc_p2Data`, save split Flutter player keys.
- Load original `mc_shopOwned` object, save Flutter owned item list.
- Load original unlocked avatar/hat arrays, save Flutter string lists.
- Load original `mc_dailyChallenges` and `mc_dailyProgress`; migrate cleanly when date and ids normalize, otherwise regenerate safely.
- Load original setting keys, toggle each setting, save, and reload.
- Verify same-key JSON primitive compatibility, legacy P1 avatar custom fallback, daily date normalization, login streak migration, and raw `mc_lowPerf`.
- Inactive monetization/ad keys are documented for BPT-001/BPT-002 and do not control current Flutter runtime.

## RT-007 Coverage

- Migrate original `mc_achs` into Flutter `mc_achievements` on app load.
- Migrate original `mc_skills` into Flutter `mc_skillMap`, including defaulting newer adaptive fields.
- Migrate original `mc_numTypeUnlocked` into split Flutter unlock flags.
- Migrate original `mc_p1Data` and `mc_p2Data` into split player fields.
- Migrate original `mc_shopOwned`, `mc_unlockedAvatars`, and `mc_unlockedHats` into Flutter ownership/list storage.
- Normalize original daily/login date formats into Flutter keys.
- Prove migration is idempotent and does not silently delete separate legacy keys. Same-key legacy shapes may be intentionally rewritten to the final Flutter shape.
