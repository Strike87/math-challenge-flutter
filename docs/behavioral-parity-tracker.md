# Behavioral Parity Tracker (BPT)

Date: 2026-06-28

Original source of truth: `C:\Users\Strik\math-challenge\www\index.html`

Flutter snapshot: `C:\Users\Strik\math_challenge_flutter`

This tracker is the single living baseline for cloning behavior before more UI fixes. The original HTML remains the behavioral source of truth unless a Flutter-only addition is explicitly approved in this document.

`docs\parity-audit.md` is now reference-only. Update that broader audit only when the project architecture or product scope changes. Day-to-day parity progress, verification, ownership, dependencies, regression tests, and freeze status belong here.

## Status Legend

| Status | Meaning |
| --- | --- |
| VERIFIED | Behavior has been checked against the original source and, where needed, tests or runtime verification prove parity. |
| IMPLEMENTED NOT VERIFIED | Flutter has an implementation, but source comparison or tests still show risk, drift, or unproven edge cases. |
| COULD NOT REPLICATE | The behavior is missing, blocked by platform limits, or intentionally not present. Must include a reason before it can be accepted. |

## Confidence Legend

| Confidence | Meaning |
| --- | --- |
| Confirmed | Verified by reading both the original HTML and Flutter implementation. |
| Likely | Strong source evidence exists, but the exact runtime path has not been fully tested. |
| Needs verification | Requires a device run, widget test, unit test, Play Console test, or screenshot comparison. |

## Approved Clone Additions

These are intentional product decisions. Do not remove them during parity work unless the user explicitly approves removal.

| Addition | Flutter location | Status | Confidence | Notes |
| --- | --- | --- | --- | --- |
| Settings screen `Player Avatar` tile | `lib\widgets\modals.dart:216`, `lib\widgets\modals.dart:393` | VERIFIED | Confirmed | Approved improvement over the original settings modal. Preserve it while cloning the rest of settings. |
| Player Setup `Tap to change` avatar flow | `lib\screens\player_screen.dart:157`, `lib\widgets\common.dart:720` | VERIFIED | Confirmed | Approved improvement. Available avatars must still obey unlock rules. |
| Custom header layout | `lib\screens\menu_screen.dart:165`, `lib\screens\menu_screen.dart:178` | IMPLEMENTED NOT VERIFIED | Needs verification | Keep stacked `MATH` / `CHALLENGE`, equal-sign icon beside them, and `BOSS BATTLE EDITION` in one row. Needs visual QA for alignment. |
| Main menu footer Daily day-calendar icon | `lib\screens\menu_screen.dart:94` | VERIFIED | Confirmed | Approved addition. Preserve the calendar-style icon for the footer Daily tab while cloning the rest of the footer behavior and styling. |

## Difficulty Model Rule

Manual UI difficulty choices are only:

- easy
- medium
- hard

Internal engine difficulties are:

- easy
- medium
- hard
- expert
- insane

`expert` and `insane` are internal progression levels, not extra setup-screen choices. They must remain supported by the engine, question generator, timer lookup, adaptive difficulty, skill counters, persistence migration, and tests.

## Behavior Tracker

| ID | System | Type | HTML source | Flutter source | Status | Confidence | Owner | Test | Source Verified | Regression ID | Finding / required proof |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BPT-001 | IAP / Google Play purchases | Ported local behavior | `index.html:6648`, `index.html:12013`, `index.html:12161`, `index.html:12453` | `lib\services\iap.dart:25`, `lib\engine\game_state.dart:2308`, `lib\widgets\modals.dart:2399`, `lib\widgets\modals.dart:2707`, `test\iap_adult_gate_test.dart:32`, `test\iap_delivery_test.dart:30`, `test\iap_restore_native_safety_test.dart:30` | VERIFIED / Frozen for local IAP behavior; device QA pending | Confirmed | Codex | Unit / Widget / Device / Play Console | Yes | RT-052A / RT-052B/C / RT-052D/E | Local BPT-001 behavior is verified: adult gate before real-money purchase entry; exact product IDs and purchase option IDs; delivery amounts and ad-removal entitlement; duplicate transaction protection; `completePurchase` on successful and duplicate approved purchases; manual restore and launch auto-restore of `ads_remove` only; consumables never restored as coins; already-owned remove-ads maps to restore/success; typed purchase errors grant nothing; unavailable native store grants nothing; dev simulation is blocked from native release. Manual release QA still remains for real `in_app_purchase` adapter wiring, Android internal-test purchase/restore, and Play Console/device proof. Repo note: the repository contains pre-existing modified and untracked port work outside this BPT-001 slice, so this verification claim applies only to the files and behavior touched for BPT-001, not to unrelated pending changes. |
| BPT-001A | IAP adult gate / purchase entry | Ported behavior | `index.html:12049`, `index.html:12165` | `lib\services\iap.dart:25`, `lib\engine\game_state.dart:2308`, `lib\widgets\modals.dart:2399`, `lib\widgets\modals.dart:2707`, `test\iap_adult_gate_test.dart:32` | VERIFIED / Frozen for scoped purchase-entry gate slice | Confirmed | Codex | Unit / Widget | Yes | RT-052A | Required behavior verified: the four real-money products (`100_coins`, `500_coins`, `1200_coins`, `ads_remove`) open Adult Gate before any IAP adapter call; wrong answer and cancel/close do not call the adapter; correct answer calls the adapter exactly once for the selected product; a new purchase attempt gets a fresh question; gate success grants no coins and does not set `adsRemoved`; local coin purchases do not show the gate. Validation passed on 2026-06-28: `flutter test test\iap_adult_gate_test.dart`, `flutter test`, and `flutter analyze`. Repo note: the repository contains pre-existing modified and untracked port work outside this BPT-001A slice, so this verification claim applies only to the files and behavior touched for BPT-001A, not to unrelated pending changes. |
| BPT-002 | AdMob banner/interstitial/rewarded | Missing | `index.html:11444`, `index.html:11542`, `index.html:11675`, `index.html:11727` | `pubspec.yaml:9` | COULD NOT REPLICATE | Confirmed | Unassigned | Device | Yes | RT-050 / RT-051 | Original has full Capacitor AdMob lifecycle and screen gating. Flutter has no `google_mobile_ads` dependency or ad service yet. Rewarded-ad commercial actions may need their own child-safe / ad-policy handling, but the real-money purchase adult gate belongs in BPT-001. |
| BPT-003 | Adaptive difficulty formulas | Ported behavior | `index.html:9778`, `index.html:9875` | `lib\engine\game_state.dart:964`, `lib\engine\game_state.dart:1511`, `lib\engine\game_state.dart:1525`, `lib\models\game_data.dart:134` | VERIFIED | Confirmed | Codex | Unit | Yes | RT-001 | Source formulas ported: mastery gains/penalties, confidence EMA, thresholds, per-skill nudge, expert/insane counters, and global adaptive mean. RT-001 passed on 2026-06-26. |
| BPT-004 | Timer source parity | Ported behavior | `index.html:6566`, `index.html:9036`, `index.html:9071`, `index.html:9738` | `lib\engine\game_state.dart:810`, `lib\engine\game_state.dart:977`, `lib\engine\game_state.dart:998`, `lib\engine\game_state.dart:1017`, `lib\models\player.dart:4` | VERIFIED | Confirmed | Codex | Unit | Yes | RT-002 | Source timer order ported: Blitz/Combo use global timers, Master/Daily Boss use stage/boss time, Survival uses phase time, normal per-question timers use adaptive generated `q.diff` only when adaptive is on, and existing `qTimerLimit` is reused. Master contract is verified for every `EXTENDED_MASTER_LEVELS` stage: `stage.goal`, `stage.time`, `stage.type`, `stage.diff`, `stage.boss`, and `stage.numType`. RT-002 passed on 2026-06-27. |
| BPT-005 | Survival boss reward/event | Ported behavior | `index.html:9362`, `index.html:9367`, `index.html:9377`, `index.html:9381` | `lib\engine\game_state.dart:1095`, `lib\game_config.dart:90`, `test\survival_boss_event_test.dart:60` | VERIFIED | Confirmed | Codex | Unit | Yes | RT-003 | Source behavior ported: Survival still grants +1 coin per correct, still advances phase every 5 correct answers, and now triggers the original every-10-correct boss-style event with random boss emoji, `BOSS DOWN! +5🪙` feedback, boss-clear celebration/confetti path, and +5 coin reward. RT-003 passed on 2026-06-27. |
| BPT-006 | Achievement trigger parity | Ported behavior | `index.html:6586`, `index.html:9998`, `index.html:10413`, `index.html:10423` | `lib\engine\game_state.dart:1248`, `lib\engine\game_state.dart:1416`, `lib\engine\game_state.dart:1429`, `lib\engine\game_state.dart:1731`, `test\achievement_trigger_test.dart:74`, `docs\achievement-trigger-audit.md` | VERIFIED | Confirmed | Codex | Unit | Yes | RT-004 | All original achievement definitions and trigger conditions were audited. Achievement rewards are `None` in the original `_unlock` path. Fixed confirmed divergences for `first_win` and `skill_master`, and added a high-score persistence mutability regression discovered by RT-004. `flutter test test\achievement_trigger_test.dart`, `flutter test`, and `flutter analyze` passed on 2026-06-27. |
| BPT-007 | Persistence schema parity | Ported behavior | `index.html:6607`, `index.html:6726`, `index.html:6744`, `index.html:10402`, `index.html:10685` | `lib\services\storage.dart:22`, `lib\engine\game_state.dart:364`, `lib\engine\game_state.dart:447`, `lib\engine\game_state.dart:492`, `lib\services\settings.dart:49`, `test\persistence_schema_test.dart:52`, `docs\persistence-schema-audit.md` | VERIFIED | Confirmed | Codex | Unit | Yes | RT-005 | Active schema decisions are source-mapped and tested. RT-005 covers original legacy achievements, skills, number-type unlocks, player data, shop ownership, settings persistence, same-key JSON primitives, avatar custom fallback, daily date/challenge normalization, login streak date migration, and raw `mc_lowPerf`. Service-only IAP/AdMob keys are documented as inactive until BPT-001/BPT-002. `flutter test test\persistence_schema_test.dart`, `flutter test`, and `flutter analyze` passed on 2026-06-27. |
| BPT-008 | Reset parity | Ported behavior | `index.html:10661`, `index.html:10685`, `index.html:10692`; `C:\Users\Strik\Downloads\flutter-game-data-reference.md:534` | `lib\engine\game_state.dart:161`, `lib\engine\game_state.dart:2183`, `test\reset_parity_test.dart:30` | VERIFIED | Confirmed | Codex | Unit | Yes | RT-006 | Reset now uses a canonical key list cross-checked against the BPT-007 schema audit, the exact-value appendix, and live Flutter storage grep. It removes current Flutter keys, original legacy keys, settings, daily/date keys, shop/economy keys, player/avatar keys, achievement/skill/high-score keys, AdMob/IAP placeholder keys, and Flutter-only runtime keys such as `mc_lastLoginDay`, then rebuilds in-memory defaults without re-saving daily/login state. `flutter test test\reset_parity_test.dart`, `flutter test`, and `flutter analyze` passed on 2026-06-27. |
| BPT-009 | Storage migration from original app | Ported behavior | `index.html:6726`, `index.html:6744`, `index.html:10402`, `index.html:12501`, `index.html:12738`, `index.html:12739`, `index.html:12740`; `C:\Users\Strik\Downloads\flutter-game-data-reference.md:534` | `lib\engine\game_state.dart:386`, `lib\engine\game_state.dart:407`, `lib\engine\game_state.dart:455`, `lib\engine\game_state.dart:761`, `test\storage_migration_test.dart:78` | VERIFIED | Confirmed | Codex | Unit | Yes | RT-007 | Original-app data now upgrades on `load()`: `mc_achs` writes `mc_achievements`, `mc_skills` writes `mc_skillMap`, `mc_numTypeUnlocked` writes split unlock flags, `mc_p1Data`/`mc_p2Data` write split player fields, legacy shop ownership writes Flutter ownership/string-list state, and legacy daily/login dates normalize to Flutter keys. Migration is idempotent and separate legacy keys remain harmless unless they share the final key being intentionally rewritten to the Flutter shape. `flutter test test\storage_migration_test.dart`, `flutter test`, and `flutter analyze` passed on 2026-06-27. |
| BPT-010 | Shop ownership and unlock rules | Ported behavior | `index.html:6539`, `index.html:11251`, `index.html:11335`, `index.html:11387` | `lib\engine\game_state.dart:2187`, `lib\widgets\common.dart:687`, `lib\widgets\modals.dart:2136`, `test\shop_ownership_test.dart:58` | VERIFIED / Frozen for scoped local shop-ownership slice | Confirmed | Codex | Unit | Yes | RT-011 | Scope verified: permanent avatar/hat unlock behavior; consumable pack repeat-purchase behavior; coin deduction and insufficient coin protection; locked avatar visibility in the Tap-to-change flow; owned item persistence; and RT-011 coverage. Validation passed on 2026-06-27: `flutter test test\shop_ownership_test.dart`, `flutter test`, and `flutter analyze`. Repo note: the repository contains pre-existing modified and untracked port work outside this BPT-010 slice, so this verification claim applies only to the files and behavior touched for BPT-010, not to unrelated pending changes. |
| BPT-011 | Number type unlock prices | Ported behavior | `index.html:6744`, `index.html:6921` | `lib\engine\game_state.dart:1013`, `lib\screens\numtype_screen.dart:39`, `test\num_type_unlock_test.dart:52` | VERIFIED / Frozen for scoped number-type unlock slice | Confirmed | Codex | Unit | Yes | RT-012 | Required behavior verified: Natural numbers are unlocked by default; Integers cost exactly 500 coins; Rationals/decimals cost exactly 1200 coins; insufficient coins do not unlock and never make balance negative; successful unlock deducts the exact price once; owned number types are not charged again; unlock state persists across reload; migration/reset compatibility remains intact. `selectNumType` now completes after durable save. Validation passed on 2026-06-27: `flutter test test\num_type_unlock_test.dart`, `flutter test`, and `flutter analyze`. Repo note: the repository contains pre-existing modified and untracked port work outside this BPT-011 slice, so this verification claim applies only to the files and behavior touched for BPT-011, not to unrelated pending changes. |
| BPT-012 | Daily Boss deterministic identity with fresh questions | Ported behavior | `index.html:6574`, `index.html:7900`, `index.html:7968`, `index.html:8483`, `index.html:10040` | `lib\game_config.dart:202`, `lib\engine\game_state.dart:916`, `lib\engine\game_state.dart:924`, `lib\engine\game_state.dart:1593`, `test\daily_boss_test.dart:80` | VERIFIED / Frozen for scoped Daily Boss identity/retry/reward slice | Confirmed | Codex | Unit / Widget | Yes | RT-008 | Required behavior verified: the six-boss roster matches the original source list; same date produces the same boss; known source-hash dates rotate to the expected bosses; boss identity remains fixed across retries; retry questions are fresh/randomized; Daily Boss starts with 3 hearts; and the boss reward can be claimed only once per local day. Fixed confirmed divergence where same-day replays could pay the Daily Boss reward again. Validation passed on 2026-06-27: `flutter test test\daily_boss_test.dart`, `flutter test`, and `flutter analyze`. Repo note: the repository contains pre-existing modified and untracked port work outside this BPT-012 slice, so this verification claim applies only to the files and behavior touched for BPT-012, not to unrelated pending changes. |
| BPT-013 | Question generation core | Ported behavior | `index.html:8499`, `index.html:8585`, `index.html:8618`, `index.html:8631`, `index.html:8751`, `index.html:9291` | `lib\engine\question_generator.dart:10`, `lib\engine\game_state.dart:1234`, `lib\engine\game_state.dart:1379`, `test\question_generator_test.dart:87` | VERIFIED / Frozen for scoped question-generation slice | Confirmed | Codex | Unit / Widget | Yes | RT-009 | Required behavior verified: natural addition/subtraction/multiplication/division source ranges; integer negative support; rational decimal precision for transformed rational questions; clean division generation; mixed runtime operation set; unique distractors with one correct answer; shuffled answer positions; finite/NaN guards; epsilon answer comparison; and all five internal difficulties (`easy`, `medium`, `hard`, `expert`, `insane`). Added optional RNG injection for deterministic generator tests without changing production behavior. Validation passed on 2026-06-27: `flutter test test\question_generator_test.dart`, `flutter test`, and `flutter analyze`. Repo note: the repository contains pre-existing modified and untracked port work outside this BPT-013 slice, so this verification claim applies only to the files and behavior touched for BPT-013, not to unrelated pending changes. |
| BPT-014 | Power-up rules | Ported behavior | `index.html:6521`, `index.html:9457`, `index.html:9581`, `index.html:10263`, `index.html:10284`, `index.html:10295`, `index.html:10307`, `index.html:10313`, `index.html:10319`, `index.html:10327`, `index.html:11377` | `lib\engine\game_state.dart:1470`, `lib\engine\game_state.dart:1624`, `lib\engine\game_state.dart:2077`, `lib\engine\game_state.dart:2136`, `test\power_up_rules_test.dart:33` | VERIFIED / Frozen for scoped power-up rules slice | Confirmed | Codex | Unit / Widget | Yes | RT-010 | Required behavior verified: power-ups are granted every 3 correct answers; power-ups are available only in eligible single-player non-Master non-Daily-Boss games; time/freeze are rejected before inventory consumption in Blitz/Combo; `time` adds 5000ms and 5 seconds to `qTimerLimit`; `fifty` leaves exactly 1 correct and 1 wrong answer; `double` doubles one question's total points once; `shield` absorbs a non-timeout wrong answer before Survival lives change; `freeze` stops the timer and marks `rt.frozen`; `switch` replaces the question after the original 500ms delay; and Power Pack remains repeatable and grants +5 of every power-up type per purchase. Validation passed on 2026-06-27: `flutter test test\power_up_rules_test.dart`, `flutter test`, and `flutter analyze`. Repo note: the repository contains pre-existing modified and untracked port work outside this BPT-014 slice, so this verification claim applies only to the files and behavior touched for BPT-014, not to unrelated pending changes. |
| BPT-015 | Confetti, emoji, audio, haptics | Ported behavior | `index.html:6034`, `index.html:9312`, `index.html:9535`, `index.html:9564`, `index.html:10467`, `index.html:10789` | `lib\engine\game_state.dart:278`, `lib\engine\game_state.dart:947`, `lib\engine\game_state.dart:1544`, `lib\engine\game_state.dart:1645`, `lib\screens\game_screen.dart:1373`, `lib\widgets\celebration_overlay.dart:44`, `lib\services\audio.dart:20`, `test\feedback_layer_test.dart:35` | VERIFIED / Frozen for scoped local feedback slice | Confirmed | Codex | Unit / Widget | Yes | RT-020 | Required behavior verified: correct and wrong answer feedback triggers; win, Master stage, Daily Boss, and Survival boss celebration triggers; big emoji is owned by the answers grid, not the question card; reduce motion and low-performance settings skip confetti paths; sound and vibration toggles gate service calls; and UI-observed achievement/reward feedback queues instead of stacking. Real rewarded-ad feedback remains under BPT-002. Validation passed on 2026-06-27: `flutter test test\feedback_layer_test.dart`, `flutter test`, and `flutter analyze`. Repo note: the repository contains pre-existing modified and untracked port work outside this BPT-015 slice, so this verification claim applies only to the files and behavior touched for BPT-015, not to unrelated pending changes. |
| BPT-016 | Modal behavioral content | Ported behavior | `index.html:6134`, `index.html:6155`, `index.html:6163`, `index.html:6235`, `index.html:6309`, `index.html:7938`, `index.html:9980`, `index.html:10007`, `index.html:10135`, `index.html:10974`, `index.html:11253` | `lib\widgets\modals.dart:651`, `lib\widgets\modals.dart:823`, `lib\widgets\modals.dart:852`, `lib\widgets\modals.dart:1272`, `lib\widgets\modals.dart:2087`, `lib\engine\game_state.dart:1614`, `lib\engine\game_state.dart:1818`, `test\modal_behavior_test.dart:36` | VERIFIED / Frozen for scoped modal behavioral content slice | Confirmed | Codex | Widget | Yes | RT-030 | Required behavior verified: Daily Boss modal renders source-style boss identity, operation, difficulty, number type, reward, claimed state, and 3-heart rules while still allowing claimed-day replay; Stage Cleared modal uses exact stage story and next-stage action; Win/results modal shows source-style single-player and two-player report content and correct Daily Boss first-claim/replay reward status; Avatar Builder saves/equips base, hat, accessory, and color to the targeted player while cancel leaves the player unchanged; Coin Shop modal covers local tabs/content and Google Play placeholder copy only; close/cancel actions do not mutate unrelated state; compact modal layout remains scrollable. Real IAP, rewarded-ad, and AdMob behavior remains outside this BPT-016 slice. Validation passed on 2026-06-27: `flutter test test\modal_behavior_test.dart`, `flutter test`, and `flutter analyze`. Repo note: the repository contains pre-existing modified and untracked port work outside this BPT-016 slice, so this verification claim applies only to the files and behavior touched for BPT-016, not to unrelated pending changes. |
| BPT-017A | Mode/player eligibility | Ported behavior | `index.html` (implied/restricted modes rule) | `lib\models\enums.dart:155`, `lib\engine\game_state.dart:1058`, `lib\engine\game_state.dart:1125`, `lib\screens\config_screen.dart:45`, `lib\screens\config_screen.dart:348` | VERIFIED / Frozen for scoped mode/player eligibility slice | Confirmed | Codex | Unit / Widget | Yes | RT-041 | Blitz, Death, Combo, and Survival are available only for 1P games. In 2P config they remain visible but greyed/disabled, not hidden. Switching 1P restricted mode to 2P resets mode to Standard. `setOption` and `startGame` enforce this rule even if state is mutated directly. Master and Daily Boss remain governed by campaign/boss entry flows. Verification refreshed on 2026-06-28: `flutter test test\mode_player_eligibility_test.dart`. |
| BPT-017 | Visual identity / responsive layout | Ported behavior | `index.html:5732`, `index.html:5838`, `index.html:5977`, `index.html:6309` | `lib\screens`, `lib\widgets` | VERIFIED / Frozen for scoped visual/responsive layout slice | Confirmed | Unassigned | Golden / Device | Yes | RT-040 | Confirmed visual parity of phone and tablet viewports, compact coin-balance pill, scrollable TabBar, and non-clipping Skill Dashboard. Verification passed on 2026-06-27: `visual_parity_test.dart` (deterministic goldens), `mode_player_eligibility_test.dart`, `flutter test`, and `flutter analyze`. |

## BPT-001 Purchase Contract

BPT-001 is behavior parity, not API parity. The original uses `capacitor-plugin-cdv-purchase`; the Flutter port should use the official `in_app_purchase` package, matching rules and outcomes rather than literal Capacitor APIs. RevenueCat and subscriptions are out of scope.

Policy note: Google Play Families policy applies to apps with children in the target audience and explicitly makes developers responsible for ads, in-app purchases, and commercial content. The adult gate below is a hard purchase precondition for this app, not optional polish.

Source references:

- Google Play Families Policies: `https://support.google.com/googleplay/android-developer/answer/9893335?hl=en`
- Flutter `in_app_purchase`: `https://pub.dev/packages/in_app_purchase`
- Play Billing one-time purchase lifecycle: `https://developer.android.com/google/play/billing/lifecycle/one-time`

### BPT-001A: Adult Gate / Purchase Entry

Before initiating any real-money IAP flow, the app must show an adult gate using a simple math challenge.

Implementation status: `VERIFIED / Frozen for scoped purchase-entry gate slice` as of 2026-06-28. This covers only the modal, purchase-entry coordinator, product constants, and adapter call/no-call contract. It does not freeze full IAP delivery, duplicate transaction protection, acknowledgement, restore, error handling, native-only enforcement, or Play Console/device behavior.

Applies to:

- `100_coins`
- `500_coins`
- `1200_coins`
- `ads_remove`
- any future real-money purchase product

Does not apply to:

- spending earned virtual coins inside the local shop
- avatar/hat unlocks bought with coins
- consumable Power Pack / Extra Life bought with coins

Implementation contract:

- User taps a real-money purchase button.
- App shows Adult Gate modal first.
- Modal displays randomized two-digit addition, for example `47 + 18`.
- User must enter the exact answer.
- If correct: only then call the real IAP purchase adapter.
- If wrong: do not start purchase flow.
- If cancelled/closed: do not start purchase flow.
- Gate must regenerate a fresh question per attempt.
- Gate success must not persist globally; it authorizes only the current purchase attempt.
- Successful gate must not grant coins or remove ads by itself. Entitlements are granted only after verified purchase delivery.

### BPT-001B: Product Constants / Purchase Launch

Exact source-confirmed products:

| Pack | Product ID | Purchase option ID | Delivery | Type |
| --- | --- | --- | --- | --- |
| small | `100_coins` | `100-coins-buy` | grants 100 coins | consumable |
| medium | `500_coins` | `500-coins-buy` | grants 550 coins | consumable |
| large | `1200_coins` | `1200-coins-buy` | grants 1400 coins | consumable |
| removeads | `ads_remove` | `ads-remove-buy` | removes ads | non-consumable |

These IDs are case-sensitive and must match Play Console. Do not rename product IDs to `550_coins` or `1400_coins`; the product ID names the base pack while delivery includes the bonus.

The purchase launcher must select the exact purchase option / offer by option ID rather than assuming the first available offer is correct.

### BPT-001C: Delivery / Duplicate Protection / Acknowledgement

Duplicate transaction protection must match the original source intent:

- derive a stable transaction key
- if the key is already delivered/remembered: do not grant again
- remember/persist the key before entitlement mutation
- then grant coins or set `adsRemoved`
- still call `completePurchase` / finish for already-delivered approved transactions so recovered consumables do not keep reappearing

Delivery rules:

- process purchases only after the platform reports an approved / purchased state
- `100_coins` grants exactly 100 coins
- `500_coins` grants exactly 550 coins
- `1200_coins` grants exactly 1400 coins
- `ads_remove` sets `adsRemoved = true` / `mc_adsRemoved`
- failed, cancelled, pending, unknown, or developer-error purchases grant nothing
- every approved purchase must be acknowledged/finished through the platform within the required window
- delivered transaction IDs must persist
- ad-removal entitlement must persist

RT-052B/C now cover the verified delivery and acknowledgement slice in `lib\engine\game_state.dart` and `test\iap_delivery_test.dart`. RT-052D/E cover restore, auto-restore, error handling, and native-only safety in `lib\engine\game_state.dart`, `lib\services\iap.dart`, and `test\iap_restore_native_safety_test.dart`.

Important separation:

- Adult gate protects entry into the billing flow.
- IAP delivery logic protects coin/ad-removal entitlement after a verified purchase result.
- Do not combine those into one method that grants rewards immediately after solving the math gate.

### BPT-001D: Restore / Auto-Restore / Error Handling

Implementation status: `VERIFIED / Frozen for scoped restore and error-handling slice` as of 2026-06-28.

Restore rules:

- manual restore restores only the non-consumable `ads_remove`
- auto-restore on app launch also applies `ads_remove`
- consumable coin packs are never restored as new coins
- already-owned `ads_remove` maps to restore, not a scary purchase error

Minimum error handling:

- user-cancelled: no error toast
- already-owned: auto-restore
- billing-unavailable: show a clear device/store error
- network-error: show connection retry feedback
- unknown/developer error: generic failure to user, detailed log for debugging

### BPT-001E: Native-Only Enforcement / Dev Simulation Guard

Implementation status: `VERIFIED / Frozen for scoped native-safety slice` as of 2026-06-28.

On native Android, if the store or purchase plugin is unavailable, show an error and grant nothing. There must be no fallback path that silently grants coins or removes ads on a native build.

A simulated purchase flow is acceptable only in non-native browser/dev context, clearly gated so it cannot reach a real device release build.

Freeze bar:

This tracker keeps IAP regression coverage under `RT-052` because `RT-050` and `RT-051` are already reserved for AdMob banner/rewarded/interstitial behavior.

```powershell
flutter test test\iap_adult_gate_test.dart
flutter test test\iap_delivery_test.dart
flutter test test\iap_restore_native_safety_test.dart
flutter test
flutter analyze
```

Manual release QA remains separate from local freeze:

- Play Console products exist with exact IDs and purchase option IDs.
- Android internal-test purchase succeeds.
- Consumable purchase is consumed/finished.
- `ads_remove` restores after reinstall.
- cancellation shows no scary error.
- native unavailable store grants nothing.

## Persistence Sub-Audits

### BPT-007A: Schema Parity

Track every persisted key by source name, Flutter name, shape, migration rule, and owner. A key is verified only when read, write, and restore behavior are proven.

The complete key table now lives in `docs\persistence-schema-audit.md`. Initial confirmed migration gaps:

| Original key | Flutter key | Current concern |
| --- | --- | --- |
| `mc_achs` | `mc_achievements` | Different key name and encoded shape. |
| `mc_skills` | `mc_skillMap` | Different key name and expanded Flutter skill fields. |
| `mc_numTypeUnlocked` | `mc_numTypeUnlocked_integers`, `mc_numTypeUnlocked_rationals` | Original stores one object; Flutter stores split integer flags. |
| `mc_p1Data`, `mc_p2Data` | `mc_p1_name`, `mc_p1_avatar`, `mc_p2_name`, `mc_p2_avatar` | Original stores player objects; Flutter stores split fields. |
| `mc_shopOwned` | `mc_shopOwned` | Original stores an object map; Flutter stores a string list. |
| Settings keys | Same key names | Flutter reads settings keys and settings toggles now persist them through `SettingsService`. |
| `mc_adsRemoved`, `mc_iapDeliveredTxs`, `mc_lastRewardedAt`, `mc_adGameCount` | Partial or absent | Monetization/ad keys are blocked until BPT-001/BPT-002. |

### BPT-008A: Reset Parity

Reset must remove both current Flutter keys and any original/legacy keys that can affect runtime. This is separate from migration because a correct migration can still leave reset incomplete. BPT-008 is now verified by RT-006.

Keys to explicitly decide on include:

- Original gameplay keys: `mc_scores`, `mc_achs`, `mc_achievements`, `mc_gamesPlayed`, `mc_adaptLvl`, `mc_skills`, `mc_skillMap`.
- Original settings keys: `mc_sound`, `mc_dark`, `mc_vibration`, `mc_dyslexia`, `mc_colorblind`, `mc_animSpeed`, `mc_reduceMotion`, `mc_lowPerf`.
- Original economy keys: `mc_coins`, `mc_shopOwned`, `mc_unlockedAvatars`, `mc_unlockedHats`, `mc_adsRemoved`, `mc_puBonus`, `mc_livesBonus`.
- Original daily keys: `mc_dailyChallenges`, `mc_dailyProgress`, `mc_dailyCoinsDate`, `mc_dailyBossClaimed`, `mc_loginStreak`, `mc_streakLastDay`.
- Original player/avatar keys: `mc_avatarCustom`, `mc_avatarCustom1`, `mc_avatarCustom2`, `mc_p1Data`, `mc_p2Data`.
- Original monetization keys: `mc_lastRewardedAt`, `mc_adGameCount`, `mc_iapDeliveredTxs`.
- Flutter/fallback cleanup keys: `mc_achievements_raw`, `mc_skillMap_raw`, `mc_dailyProgress_raw`, `mc_lastLoginDay`, `mc_lastDailyBossClaimDay`, `mc_numTypeUnlocked_integers`, `mc_numTypeUnlocked_rationals`, `mc_unlocked_integers`, `mc_unlocked_rationals`, `mc_p1_name`, `mc_p1_avatar`, `mc_p2_name`, `mc_p2_avatar`.

## Regression Queue

Work these in order. Each item should update the relevant BPT row before moving on.

1. BPT-003: Port or justify adaptive difficulty formulas.
2. BPT-004: Port timer source parity.
3. BPT-005: Restore survival boss reward/event behavior.
4. BPT-006: Audit and fix achievement parity.
5. BPT-007: Map persistence schema parity.
6. BPT-008: Fix reset parity.
7. BPT-009: Add or explicitly reject storage migration.
8. BPT-017: Finish visual identity and responsive layout parity.
9. BPT-001 / BPT-002: Implement IAP and AdMob services after local game-loop parity is stable.

## Regression Test Matrix

Every fixed behavior should eventually point to one regression ID. A row can stay `IMPLEMENTED NOT VERIFIED` while its regression test is missing or still manual-only.

| Regression ID | BPT row | System | Test type | Required proof |
| --- | --- | --- | --- | --- |
| RT-001 | BPT-003 | Adaptive difficulty formulas | Unit | Mastery, confidence, speed gains, penalties, and thresholds match the original formulas. |
| RT-002 | BPT-004 | Timer source parity | Unit | Blitz/Combo global timers, per-question timers, Survival phase time, Daily Boss time, adaptive `q.diff`, fallback setup difficulty, qTimerLimit reuse, and every Master stage's `goal`, `time`, `type`, `diff`, `boss`, and `numType` from `EXTENDED_MASTER_LEVELS` match source rules. |
| RT-003 | BPT-005 | Survival boss reward/event | Unit | Every 10 survival correct answers triggers the original boss reward/event feedback, grants +5 coins, and preserves normal every-5-correct phase progression. |
| RT-004 | BPT-006 | Achievements | Unit | Achievement triggers match original conditions for `skill_master`, `speed_demon`, `daily_grind`, `math_wizard`, `math_legend`, `daily_boss`, `survivor`, and `perfect_score`; also covers high-score working-list mutability, sorting, trimming, saving, and reload. |
| RT-005 | BPT-007 | Persistence schema | Unit | Active persisted keys are read/written with documented shape and compatibility behavior: legacy achievements, skills, number types, player data, shop ownership, settings toggles, JSON primitive compatibility, avatar custom fallback, daily dates/challenge objects, login streak date, and raw `mc_lowPerf`. |
| RT-006 | BPT-008 | Reset parity | Unit | Reset removes current Flutter keys, original/legacy keys, settings, daily/date, shop/economy, player/avatar, achievement/skill/high-score, AdMob/IAP placeholder, and Flutter-only runtime keys, then returns in-memory state/settings to defaults without recreating wiped daily/login keys. |
| RT-007 | BPT-009 | Storage migration | Unit | Original HTML key shapes migrate on app load, write final Flutter keys, preserve separate legacy keys, intentionally rewrite same-key legacy shapes to Flutter shape, and remain idempotent when `load()` runs more than once. |
| RT-008 | BPT-012 | Daily Boss | Unit / Widget | Original six-boss roster, deterministic date hash rotation, same-date identity stability, retry freshness, 3-heart start, and once-per-local-day reward claim behavior match source intent. |
| RT-009 | BPT-013 | Question generation | Unit / Widget | Natural operation ranges, integer negatives, rational precision, clean division, mixed operation set, unique distractors, shuffled answer positions, finite/NaN guards, epsilon answer comparison, and all five internal difficulties match source behavior. |
| RT-010 | BPT-014 | Power-ups | Unit / Widget | Every-3-correct grants, eligibility restrictions, Blitz/Combo pre-consumption rejection, 50/50, time, double, shield, freeze, switch delay, and repeatable Power Pack behavior match source behavior. |
| RT-011 | BPT-010 | Shop ownership | Unit | Permanent avatar/hat unlocks, repeatable Power Pack and Extra Life consumables, rewarded +100 coin placeholder blocking, locked avatar visibility, insufficient coins, durable save, and reload persistence match the local shop contract. |
| RT-012 | BPT-011 | Number type unlocks | Unit | Natural default unlock, integer 500-coin unlock, rational/decimal 1200-coin unlock, insufficient-coin protection, exact one-time deduction, durable save, reload persistence, and migration/reset compatibility match target behavior. |
| RT-020 | BPT-015 | Confetti / emoji / audio / haptics | Unit / Widget | Correct/wrong feedback triggers, win/stage/daily-boss/survival-boss celebration triggers, answer-grid big emoji placement, reduce-motion and low-performance confetti gates, sound/vibration service gates, and UI-observed achievement/reward feedback queueing match source intent. |
| RT-030 | BPT-016 | Modal behavior | Widget | Daily Boss modal content and claimed-day replay, Stage Cleared story/action, Win/results report rows and Daily Boss first-claim/replay status, Avatar Builder save/equip/player targeting/cancel behavior, Coin Shop local tabs/placeholders, close/cancel non-mutation, and compact scrollability match source-scoped behavior. |
| RT-040 | BPT-017 | Visual identity | Golden / Device | Phone and tablet screenshots match approved clone visual spec and preserve approved additions. |
| RT-041 | BPT-017A | Mode/player eligibility | Unit / Widget | 1P allows all five modes; 2P shows all five mode labels but greys/disables Blitz, Death, Survival, and Combo; disabled modes are non-selectable; switching 1P restricted mode to 2P resets to Standard; `setOption` rejects restricted modes on 2P; and `startGame` blocks corrupted 2P + restricted state. |
| RT-050 | BPT-002 | AdMob banner gating | Device | Banner appears only on approved screens and never during gameplay or modal overlays. |
| RT-051 | BPT-002 | Rewarded/interstitial ads | Device | Rewarded grant, cooldown, no-fill handling, interstitial preload/show/retry behavior match release rules. |
| RT-052A | BPT-001A | IAP adult gate / purchase entry | Unit / Widget | Tapping `100_coins`, `500_coins`, `1200_coins`, or `ads_remove` opens Adult Gate before adapter calls; wrong/cancelled gates start no purchase; correct gate calls the adapter exactly once for the selected product; gate success grants no coins and does not remove ads; new attempts regenerate the question; local coin purchases do not show the gate. |
| RT-052B/C | BPT-001B/C | IAP delivery / duplicate transaction handling | Unit | `100_coins`, `500_coins`, `1200_coins`, and `ads_remove` deliver exact entitlements only after an approved purchase; unknown, failed, cancelled, and pending purchases grant nothing; stable transaction keys are persisted before/with delivery; duplicate transaction IDs do not double-grant; duplicate approved purchases still call `completePurchase`; delivered IDs, coins, and `adsRemoved` survive reload. |
| RT-052D/E | BPT-001D/E | IAP restore / native safety | Unit | Manual restore and launch auto-restore restore only `ads_remove`; consumable coin products never restore as coins; mixed restore restores only ad removal; already-owned ad removal maps to restore/success; user-cancelled, billing-unavailable, network, developer/unknown, unavailable store, and native-release simulation paths grant nothing and show calm source-appropriate feedback. |
| RT-052 | BPT-001 | IAP adult gate / delivery / restore | Unit / Widget / Device / Play Console | Adult gate opens before purchase adapter calls; wrong/cancelled gate starts no purchase; correct gate calls purchase exactly once for selected product; gate regenerates per attempt; gate success grants nothing by itself; source product IDs and option IDs match exactly; `100_coins`, `500_coins`, `1200_coins`, and `ads_remove` deliver exact entitlements only after approved purchase; duplicate transaction keys do not double-grant; already-delivered approved transactions are still finished; failed/cancelled/pending/unknown purchases grant nothing; manual and launch auto-restore restore `ads_remove` only; consumables are never restored as new coins; already-owned remove-ads maps to restore; native unavailable store grants nothing; browser/dev simulation cannot run on native release. |

## Behavior Freeze

A system can move to `Frozen` only after its BPT row is `VERIFIED`, source verification is `Yes`, and the regression ID has passing proof. Once frozen, do not refactor, clean up, optimize, or redesign it unless a verified bug is found.

| System | BPT row | Freeze status | Regression ID | Notes |
| --- | --- | --- | --- | --- |
| Question generation | BPT-013 | Frozen for scoped question-generation slice | RT-009 | Source ranges, number-type transforms, clean division, choices, mixed runtime operation selection, epsilon answer comparison, and five internal difficulties are covered by RT-009. Do not refactor unless BPT-013 is reopened with a verified bug. |
| Power-up rules | BPT-014 | Frozen for scoped power-up rules slice | RT-010 | Grant cadence, eligibility, use effects, blocked time/freeze modes, one-use double/shield, switch delay, and repeatable Power Pack behavior are covered by RT-010. Do not refactor unless BPT-014 is reopened with a verified bug. |
| Feedback layer | BPT-015 | Frozen for scoped local feedback slice | RT-020 | Answer reactions, celebration triggers, answer-grid big emoji origin, reduce-motion/low-performance confetti gates, sound/vibration gates, and UI-observed feedback queueing are covered by RT-020. Real rewarded-ad feedback remains under BPT-002. Do not refactor unless BPT-015 is reopened with a verified bug. |
| Modal behavior | BPT-016 | Frozen for scoped modal behavioral content slice | RT-030 | Daily Boss, Stage Cleared, Win/results, Avatar Builder, and local Coin Shop modal content/actions are covered by RT-030. Real IAP, rewarded-ad, and AdMob behavior remains under BPT-001/BPT-002. Do not refactor unless BPT-016 is reopened with a verified bug. |
| Scoring core | BPT-003 / BPT-005 / BPT-006 | Not frozen | RT-001 / RT-003 / RT-004 | Scoring depends on adaptive, survival, and achievement parity. |
| Adaptive difficulty | BPT-003 | Frozen | RT-001 | Source formulas ported and RT-001 passes. Do not refactor unless BPT-003 is reopened with a verified bug. |
| Timer behavior | BPT-004 | Frozen | RT-002 | Timer source rules and all Master stage contracts are ported and RT-002 passes. Do not refactor unless BPT-004 is reopened with a verified bug. |
| Survival boss event | BPT-005 | Frozen | RT-003 | Every-10-correct boss reward/event behavior is ported and RT-003 passes. Do not refactor unless BPT-005 is reopened with a verified bug. |
| Achievement triggers | BPT-006 | Frozen | RT-004 | Source achievement triggers are audited, fixed, and covered by RT-004. Do not refactor unless BPT-006 is reopened with a verified bug. |
| Persistence schema | BPT-007 | Frozen | RT-005 | Active storage schema and legacy migration decisions are covered by RT-005. Do not refactor unless BPT-007 is reopened with a verified bug. |
| Reset parity | BPT-008 | Frozen | RT-006 | Current, original legacy, settings, daily, shop/economy, player/avatar, fallback, AdMob/IAP placeholder, and Flutter-only runtime keys are removed and in-memory defaults are restored. Do not refactor unless BPT-008 is reopened with a verified bug. |
| Storage migration | BPT-009 | Frozen | RT-007 | Original-app persisted data upgrades to final Flutter keys on load, is idempotent, and does not silently delete separate legacy keys. Do not refactor unless BPT-009 is reopened with a verified bug. |
| Master Mode | BPT-004 / BPT-006 / BPT-016 | Frozen for scoped timer/achievement/modal slices | RT-002 / RT-004 / RT-030 | Stage runtime contract, achievements, Stage Cleared modal story/action, and Master result content are covered by RT-002, RT-004, and RT-030. Visual layout remains under BPT-017. |
| Daily Boss | BPT-012 | Frozen for scoped Daily Boss identity/retry/reward slice | RT-008 | Roster, deterministic date rotation, retry freshness, 3-heart start, and once-per-day reward claim are verified. Do not refactor unless BPT-012 is reopened with a verified bug. |
| Shop / local economy | BPT-010 | Frozen for scoped local shop-ownership slice | RT-011 | Permanent unlocks, repeatable consumables, rewarded-ad placeholder blocking, avatar picker gating, insufficient-coin handling, and persistence are verified for the BPT-010 files/behavior only. Do not refactor unless BPT-010 is reopened with a verified bug. |
| Number type unlocks | BPT-011 | Frozen for scoped number-type unlock slice | RT-012 | Natural default, integer 500-coin unlock, rational/decimal 1200-coin unlock, insufficient-coin handling, one-time deduction, persistence, and migration/reset compatibility are verified. |
| Mode/player eligibility | BPT-017A | Frozen for scoped mode/player eligibility slice | RT-041 | Blitz, Death, Combo, and Survival are restricted to 1P and remain visible but greyed/disabled in 2P. Handled in enums, state setters, startGame, and config tabs. |
| Paid purchase adult gate | BPT-001A | Frozen for scoped purchase-entry gate slice | RT-052A | Adult Gate modal, purchase-entry coordinator, product constants, and fake-adapter call/no-call behavior are covered by RT-052A. Gate success intentionally grants no entitlement. Do not refactor unless BPT-001A is reopened with a verified bug. |
| Paid purchases / local IAP behavior | BPT-001 | Frozen for local IAP behavior; device QA pending | RT-052A / RT-052B/C / RT-052D/E | Adult gate, delivery, duplicate protection, acknowledgement calls, restore, error handling, and native-safety simulation guard are covered locally. Real Play Console/internal-test purchase and restore remain release QA. Do not refactor unless BPT-001 is reopened with a verified bug. |
| AdMob | BPT-002 | Not frozen | RT-050 / RT-051 | Flutter still needs AdMob service implementation and device proof for banner gating, rewarded grants, cooldowns, no-fill handling, and interstitial behavior. |
| Visual identity | BPT-017 | Frozen for scoped visual/responsive layout slice | RT-040 | Phone and tablet layouts, coin shop, and skill dashboard layouts are verified. Do not refactor unless BPT-017 is reopened with a verified bug. |

## Dependency Graph

Use this before choosing implementation order.

| BPT row | Depends on | Reason |
| --- | --- | --- |
| BPT-004 | BPT-003 | Adaptive `q.diff` affects only the eligible per-question timer path. |
| BPT-006 | BPT-003, BPT-005, BPT-012 | Achievements depend on adaptive mastery, survival events, and boss/master outcomes. |
| BPT-007 | BPT-003, BPT-006, BPT-010, BPT-011, BPT-012 | Persistence must store the final shapes used by gameplay, achievements, shop, number types, and daily boss. |
| BPT-008 | BPT-007 | Reset can only be complete after the full schema is known. |
| BPT-009 | BPT-007 | Migration maps original keys into the chosen Flutter schema. |
| BPT-010 | BPT-007 | Shop ownership needs stable persistence. |
| BPT-001 | BPT-010, BPT-007 | IAP delivery affects shop/economy state and persistent entitlements. |
| BPT-002 | BPT-001, BPT-017 | AdMob depends on remove-ads entitlement and final screen/modal gating. |
| BPT-015 | BPT-003, BPT-005, BPT-006, BPT-012, BPT-014 | Feedback triggers come from scoring, survival, achievements, boss, and power-up behavior. |
| BPT-016 | BPT-006, BPT-010, BPT-012 | Modal content depends on final achievement, shop, and boss state. |
| BPT-017 | BPT-003 through BPT-017A | Visual freeze should happen after behavior surfaces are stable. |

## Update Rules

- Do not mark a row `VERIFIED` from screenshots alone.
- Do not mark a missing platform feature `COULD NOT REPLICATE` without documenting why it is intentionally absent or blocked.
- Separate missing behavior from behavioral divergence.
- Keep approved Flutter-only additions listed here so future parity passes do not remove them by accident.
- Every fix should add or update a test when the behavior can be tested without a device.
- Once a system is frozen, do not refactor it unless the BPT row is reopened with a verified bug.
