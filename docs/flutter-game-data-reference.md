# Math Challenge — Complete Game Data & Behavior Reference

Every value in this document was extracted directly from the live,
published app's actual source code (`index.html`), by grep/read against
the real file — not written from memory or description. Where a fix
number is cited, it's the exact inline comment found in source. This
document is the data appendix to `flutter-full-port-master-prompt.md`
and `flutter-visual-identity-spec.md` — read all three together.

If anything here ever conflicts with the live source (e.g., after a
future update to the original app), the source wins — re-extract,
don't trust this document blindly forever.

---

## 1. Operations & number ranges (exact, per difficulty)

Each operation generates two random operands per the ranges below, for
the **Natural** number type. (Integers/Rationals apply a transform on
top — see Section 2.)

### Addition
| Difficulty | Operand range (each) |
|---|---|
| easy | 1–10 |
| medium | 11–49 |
| hard | 25–99 |
| expert | 50–199 |
| insane | 100–499 |

### Subtraction
Generated as `b` + `ans` = `a` (so subtraction never goes negative in
natural mode), where `b` and `ans` are both drawn from:
| Difficulty | Range for b and ans |
|---|---|
| easy | 1–9 |
| medium | 5–44 |
| hard | 15–79 |
| expert | 50–149 |
| insane | 100–399 |

### Multiplication
| Difficulty | Operand range (each) |
|---|---|
| easy | 2–5 |
| medium | 2–10 |
| hard | 3–12 |
| expert | 11–20 |
| insane | 15–25 |
| (adaptive fallback) | 3–(12 + floor(adaptLvl/2)) |

### Division
Generated as `a = b × ans` (always divides evenly), where `b` and `ans`
are drawn from:
| Difficulty | Range for b and ans |
|---|---|
| easy | 2–5 |
| medium | 2–10 |
| hard | 3–12 |
| expert | 11–15 |
| insane | 12–20 |
| (adaptive fallback) | 3–(12 + floor(adaptLvl/2)) |

### Fill-in-the-blank variant
For every operation except `easy` difficulty, there's a 1-in-3 chance
the question is rendered as "? + 5 = 12" (solve for a missing operand)
instead of "7 + 5 = ?". Easy difficulty is always solve-for-result.

---

## 2. Number type transforms (applied after base generation)

`natural` → no transform.

`integers` → allows negative operands/answers (`allowNeg = true` in
distractor generation). Question text and answer can be negative.

`rationals` → converts to decimals. Decimal places by difficulty:
| Difficulty | Decimal places |
|---|---|
| easy | 1 |
| medium | 1 |
| hard | 2 |
| expert | 2 |
| insane | 3 |

Rationals answers are always rounded to the question's own decimal
precision before comparison (`ratDP`), and **answer comparison uses
epsilon tolerance, never strict equality** — this is Fix #11, directly
caused by IEEE-754 float behavior (`0.1 + 0.2 !== 0.3`). Use a tolerance
of `1e-9` in Dart (`(a - b).abs() < 1e-9`), not `==`.

---

## 3. Timer system

### Base timer by difficulty (Standard mode and similar)
```
easy:    10000 ms
medium:   8000 ms
hard:     6000 ms
expert:   5000 ms
insane:   4000 ms
```

### Adaptive penalty
```
penalty = floor(adaptLvl / 3) * 1000 ms
finalTimer = max(3000 ms, base - penalty)
```
`TIMER_MIN_MS = 3000` — the timer never drops below 3 seconds regardless
of adaptive difficulty.

### Blitz / Combo modes
Single global timer: `BLITZ_TIMER_DEFAULT = 60000 ms` (60 seconds total
for the whole run, not per-question).

### Survival mode — per-phase timer
```
Phase 0: 15000 ms
Phase 1: 12000 ms
Phase 2: 10000 ms
Phase 3:  8000 ms
Phase 4:  6000 ms
```
(Survival escalates through these 5 phases as the player progresses.)

### Master mode
Timer = `MASTER_LEVELS[stage].time * 1000` — see Section 6 for the
exact per-stage value (ranges 6–10 seconds across the 5 stages).

### Daily Boss
Timer = `(dailyBoss.time || 9) * 1000` — see Section 7 for the exact
per-boss value (ranges 7–9 seconds across the 6 bosses).

### Important — timer resume correctness (Fix #9)
When resuming from a pause, reuse the SAME `qTimerLimit` value that was
already set for the current question — do not recompute via the timer
function again, since adaptive difficulty could have shifted mid-pause
and would silently change the question's time limit. Store the limit
once per question, reuse it on resume.

---

## 4. Scoring system

### Base points
`SCORE_BASE = 10` points per correct answer.
`SCORE_FAST_BONUS = 2` (referenced constant; actual per-mode speed
bonus logic below supersedes this in most modes).

### Per-mode speed bonus (added to base before multipliers)
**Blitz mode:**
```
< 1500ms: +8
< 2500ms: +5
< 4000ms: +2
else:     +0
```

**Survival mode:**
```
phase bonus by current phase: [0, 2, 4, 7, 10]  (indexed by phase, capped at phase 4)
plus +3 additional if answered in < 2000ms
```

**Other modes:** no extra speed bonus beyond base (Standard, Death,
Master, Daily Boss use base points + combo multiplier only — verify
against source if a specific mode seems to be missing a bonus you
expected; don't assume parity with Blitz/Survival).

### Double points power-up interaction
If the "double" power-up is active: `points = (base + bonus) * 2`, and
the speed bonus is zeroed out afterward (it's already folded into the
doubled total, not added again).

### Combo multiplier — TWO DIFFERENT SYSTEMS (don't conflate them)

**System A — dedicated "Combo" game mode:**
```
streak ≥ 10 → multiplier ×5  (COMBO_THRESHOLDS[2], COMBO_MULTIPLIERS[2])
streak ≥ 5  → multiplier ×3  (COMBO_THRESHOLDS[1], COMBO_MULTIPLIERS[1])
streak ≥ 3  → multiplier ×2  (COMBO_THRESHOLDS[0], COMBO_MULTIPLIERS[0])
```
At streak === 10: triggers screen shake + confetti + "🔥 COMBO ×5!" pill.
At streak === 5: "⚡ COMBO ×3!" pill.
At streak === 3: "✨ COMBO ×2!" pill.

**System B — standard combo (used in all OTHER modes, not Combo mode):**
```
combo ≥ 10 → multiplier ×2    (shows "x2" badge)
combo ≥ 5  → multiplier ×1.5  (shows "x1.5" badge)
combo ≥ 3  → multiplier ×1.2  (shows "x1.2" badge)
```

Final points: `round(rawPoints * comboMultiplier)`. Guard against
`comboMultiplier` ever being `undefined`/`null` — default to `1` (Fix
#64 — a missing guard here causes `NaN` to propagate through the
player's score permanently, since `NaN + anything === NaN`).

---

## 5. Game modes — mode-specific rules summary

| Mode | Timer type | Speed bonus | Combo system | Notes |
|---|---|---|---|---|
| Standard | Per-question, difficulty-based | None | System B | Baseline mode |
| Blitz | Global 60s | Yes (tiered) | System B | Time-pressure mode |
| Death | Per-question | None | System B | Likely ends run on first wrong answer — verify exact lose condition against source `_endGame` logic for this mode specifically |
| Survival | Per-question, phase-based | Yes (phase + speed) | System B | 5 escalating phases |
| Combo | Global 60s (same as Blitz) | None | System A (dedicated) | The only mode using System A combo multipliers |
| Master | Per-stage (5 stages) | None | System B | Story progression, see Section 6 |
| Daily Boss | Per-boss (6 bosses) | None | System B | 3 lives, deterministic per date, see Section 7 |

**Note on Death mode**: this reference doesn't have a verified exact
lose-condition citation from this extraction pass. Before implementing,
grep the source for how Death mode specifically ends a run (likely
"any wrong answer ends the game" given the name, but confirm against
`_endGame` / `_checkAnswer` logic rather than assuming from the name).

---

## 6. Master mode — exact 5 stages

```
Stage 1 — "The Jungle"
  type: addition | diff: easy | goal: 5 | time: 10s | boss: 🦍 | numType: natural
  victory story: "You defeated the Gorilla! The path is clear —
                  but a wide river blocks your way."

Stage 2 — "River Crossing"
  type: subtraction | diff: medium | goal: 10 | time: 9s | boss: 🐊 | numType: natural
  victory story: "You crossed safely! Ahead, ancient stone ruins
                  rise from the mist."

Stage 3 — "Ancient Ruins"
  type: multiplication | diff: medium | goal: 15 | time: 8s | boss: 🗿 | numType: integers
  victory story: "The Stone Guardian crumbles! You enter a dark
                  tunnel. It's getting warmer..."
  ★ Completing this stage unlocks the "Math Wizard" achievement

Stage 4 — "Dragon's Cave"
  type: mixed | diff: hard | goal: 20 | time: 7s | boss: 🐲 | numType: rationals
  victory story: "The Dragon bows in defeat! The Treasure Vault
                  stands before you."

Stage 5 — "Treasure Vault"
  type: mixed | diff: hard | goal: 25 | time: 6s | boss: 🧞 | numType: mixed
  victory story: (none — this is the final stage)
  ★ Completing this stage unlocks the "Math Legend" achievement
    AND sets the masterWin flag (Fix #23 — use this flag directly,
    do NOT check `master.level >= MASTER_LEVELS.length`, which the
    original had as a bug that could never evaluate true)
```

`numType: 'mixed'` on Stage 5 means the question generator should vary
number type per-question within that stage — confirm exact mixed-mode
behavior against source `_buildQ`/`_applyNumType` call pattern when
`numType === 'mixed'` rather than assuming it means "random every time"
without checking.

---

## 7. Daily Boss — exact 6 bosses

```
Lava Dragon       🐲  mixed          medium  goal:12  time:9s  integers   reward:50  theme:atm-cave
                  "Hot integer problems with no mercy."

Clockwork Sphinx  🦁  multiplication hard    goal:10  time:8s  natural    reward:45  theme:atm-ruins
                  "Fast multiplication in ancient gears."

Frost Kraken      🐙  division       medium  goal:10  time:9s  rationals  reward:55  theme:atm-ocean
                  "Decimal division from the deep."

Storm Golem       🗿  subtraction    hard    goal:12  time:8s  integers   reward:50  theme:atm-mountain
                  "Negative numbers under pressure."

Solar Phoenix     🔥  addition       hard    goal:14  time:7s  rationals  reward:60  theme:atm-vault
                  "Decimal addition at sunrise."

Nebula Hydra      🐉  mixed          hard    goal:15  time:7s  mixed      reward:65  theme:atm-space
                  "A mixed-operation boss from the stars."
```

Boss-of-the-day is selected deterministically from the date (so all
players see the same boss on the same day), cycling through this list
of 6 — **this 6-boss list is exact source ground truth**, not a
limitation specific to the existing Flutter scaffold. A future version
could expand this roster, but for 1:1 parity with the live app, 6 is
correct.

Daily Boss gives the player exactly 3 lives. Reward is coins, granted
once per calendar day (tracked by date key) regardless of how many
attempts it takes within that day. Defeating a boss for the first time
ever unlocks the "Boss Breaker" achievement.

---

## 8. Adaptive difficulty / mastery system — exact constants

```
Mastery gain/penalty (per skill category: addition, subtraction,
multiplication, division — tracked independently)
FAST_MS:         1500   // answers under this = "very fast"
NORMAL_MS:       3000   // answers under this = "normal" speed
GAIN_FAST:       +7     // mastery change for very-fast correct answer
GAIN_NORMAL:     +5     // mastery change for normal-speed correct answer
GAIN_SLOW:       +3     // mastery change for slow-but-correct answer
PENALTY:         -4     // mastery change for wrong answer
PENALTY_TIMEOUT: -2     // mastery change for timeout (gentler than wrong)
MAX:             100    // mastery ceiling per skill
DEFAULT:         20     // starting mastery for a new/unseen skill category

Confidence (EMA of recent answer speed, 0-100, per skill)
SPEED_DIVISOR:   120    // normalizes ms → 0-100: score = max(0, 100 - ms/120)
EMA_ALPHA:       0.25   // exponential moving average weight (25% new, 75% old)
DEFAULT:         50     // starting confidence
DEFAULT_MS:      5000   // fallback if timeTaken is somehow undefined
```

### How `adaptLvl` (the 0–10 difficulty dial) is derived
```
mean = (sum of all 4 skills' mastery) / 4
adaptLvl    = min(10, round((mean / 100) * 10))     // integer, used for display/branching
adaptLvlRaw = (mean / 100) * 10                      // fractional, never rounded, used as source of truth
```

`adaptLvl` and `adaptLvlRaw` must be stored under **separate** keys
(Fix #8 — the original had a bug writing both to the same key, so the
second write always clobbered the first). In a Flutter port, use two
distinct fields/keys for these, not one.

### Running-sum optimization (Fix #30)
Don't recompute the mean by summing all 4 skills on every single
answer. Maintain a running sum, and adjust it by the delta
(`newMastery - oldMastery`) of only the one skill that just changed.
Recompute the full sum from scratch only once, on first load after a
fresh skillMap (`_masterySumDirty` flag pattern).

### Secondary fine-grained nudge (Fix #10)
A second, smaller adjustment (`_updateAdapt`) also nudges the relevant
skill's mastery directly — `+0.6` for a correct answer under 2000ms,
`+0.2` otherwise; `-0.5` for wrong — and must update the running sum
in the same call (Fix #162), not rely solely on the next full
`_updateMastery` pass to catch up.

---

## 9. Achievements — exact full list (14 total)

| ID | Name | Unlock condition | Icon |
|---|---|---|---|
| `first_win` | First Victory | Win your first game | 🏆 |
| `speed_demon` | Speed Demon | Answer 5 questions under 2s each | ⚡ |
| `perfect_score` | Perfect Score | 100% accuracy in a game | 💯 |
| `streak_master` | Streak Master | Get a 10-question streak | 🔥 |
| `power_upper` | Power Upper | Use 5 power-ups in one game | ✨ |
| `math_wizard` | Math Wizard | Complete Master Stage 3 | 🧙 |
| `persistent` | Persistent | Play 10 games total | 🔄 |
| `quick_learner` | Quick Learner | Reach adaptive difficulty level 8 | 🚀 |
| `survivor` | Survivor | Score 250+ in Sudden Death mode | 💀 |
| `avatar_artist` | Avatar Artist | Create a custom avatar | 🎨 |
| `skill_master` | Skill Master | Reach 90% in any skill category | 📈 |
| `daily_grind` | Daily Grind | Complete 3 daily challenges | 🎁 |
| `daily_boss` | Boss Breaker | Defeat a Daily Boss | 🐲 |
| `math_legend` | Math Legend | Beat all 5 Master mode stages | 👑 |

The 90% threshold for `skill_master` is exact and confirmed directly
in source (this was previously corrected from an inconsistent 85% in
Fix #39 — the value above is the current, correct one).

`math_wizard` and `math_legend` are deliberately differentiated to
unlock at different milestones (Stage 3 vs full 5-stage completion) —
do not collapse them to fire at the same moment.

Multiple achievements unlocking simultaneously must queue as separate
toasts, not stack at the same screen position (Fix #54).

---

## 10. Daily challenges — exact full list (6 total)

| ID | Title | Condition | Target | Reward |
|---|---|---|---|---|
| `blitz_15` | Blitz Master | Answer questions in Blitz mode | 15 | 50 coins |
| `streak_7` | Streak Star | Get a question streak | 7 | 30 coins |
| `division_10` | Division Pro | Answer division questions correctly | 10 | 40 coins |
| `master_stage` | Stage Clear | Clear any Master mode stage | 1 | 100 coins |
| `daily_boss` | Boss Breaker | Defeat today's Daily Boss | 1 | 75 coins |
| `perfect_5` | Perfect Round | Get questions in a row with 100% accuracy | 5 | 60 coins |

**Known gap from prior Flutter-scaffold analysis**: `master_stage` was
found defined but never actually triggered in the existing Flutter
scaffold's code. When implementing, explicitly wire a progress-update
call at the point where any Master stage is cleared (`advanceStage()`
or equivalent) — do not assume the definition alone means it works.

Daily challenge progress writes must be debounced, not fired on every
single correct answer (Fix #6 — this was a real performance bug from
a broken debounce in the original).

---

## 11. Power-ups — exact 6 types

| Key | Display | Effect |
|---|---|---|
| `time` | ⏱️ +5s | Adds 5000ms directly to the active timer's remaining duration (and `qTimerLimit` if set) — extends the running timer in place, does not reset/rebuild it |
| `fifty` | ✂️ 50/50 | Removes 2 of the 3 incorrect answer choices (disables those buttons), leaving 2 choices total (1 correct + 1 wrong) |
| `double` | ✨ ×2 | Sets a flag that doubles this question's total points (base + bonus), consumed after one use |
| `shield` | 🛡️ | Sets a flag — implementation detail of what shield protects against (likely "ignore next wrong answer" for streak/lives purposes) should be confirmed against source `_checkAnswer`/`_onWrong` logic for exact protective behavior before porting, rather than assumed from the name alone |
| `freeze` | ⏸️ Freeze | Stops the timer entirely (`_stopTimer()`), sets a frozen flag, changes timer-bar color to `#29C8E8` |
| `switch` | 🔀 Swap | Discards the current question and generates + renders a brand new one after a 500ms delay |

### Power-up rules
- Granted every 3 correct answers (`PU_REWARD_INTERVAL = 3`), one
  random power-up from the 6 types each time
- Only available in single-player, non-Master, non-Daily-Boss games
  (`opts.players === 1 && !isMaster && !isDailyBoss`)
- `time` and `freeze` are explicitly **rejected up-front** (before
  consuming the power-up from the player's inventory) in Blitz and
  Combo modes — Fix #21. The rejection must happen before the
  inventory slot is consumed, not after attempting and failing to
  apply the effect.
- Power-up packs can also be purchased in the shop (see Section 12)
  and granted via a "watch ad" bonus pathway that adds +5 to every
  power-up type's bonus pool at once — confirm exact bonus-granting
  trigger against source before assuming it's identical to the shop
  pack purchase.

---

## 12. Coin shop — exact items and prices

### Avatars (permanent unlock, 200–400 coins)
```
🐉 Dragon   — 300
🤖 Robot    — 200
👽 Alien    — 200
🥷 Ninja    — 400
🧙 Wizard   — 400
🦄 Unicorn  — 350
```

### Hats (permanent unlock, 100–300 coins)
```
👑 Crown      — 150
🧙‍♂️ Wizard   — 180
🎩 Top Hat    — 100
😇 Halo       — 250
🔥 Fire       — 300
⭐ Star       — 120
```

### Packs (special handling — NOT simple permanent unlocks)
```
🎒 Power Pack   — 500 coins — CONSUMABLE (can buy repeatedly; grants
                  ×5 of each power-up type per purchase)
💎 +100 Coins   — FREE (price: 0) — "watch" special type, granted via
                  watching a rewarded ad, not a coin purchase
❤️ Extra Life   — 450 coins — CONSUMABLE (can buy repeatedly; grants
                  +1 life, usable in Master mode)
```

**Critical**: the Power Pack and Extra Life packs MUST be flagged as
repeatable/consumable in the data model — Fix #26 specifically fixed a
bug where these were incorrectly treated as one-time permanent unlocks
(locking forever after first purchase) despite granting a repeatable,
consumable benefit. Do not let this regress in the port.

---

## 13. Avatar customization options

```
Base avatars (11):       🐶 🐱 🦁 🐸 🐼 🦊 🐯 🦋 🐙 🦉 🐧
Hat overlays (7, incl. none): (none) 🎓 🧢 🪖 👒 🎀 🌸
Accessories (15, incl. none): (none) 👓 🕶️ 🧣 🧤 👑 💍 📿 🎀 🪭 ⌚ 🧸 💎 🏅 🪆
Color tints (9, incl. none): (none) #FF6B6B #4ECDC4 #45B7D1 #96CEB4
                              #FECA57 #FF9FF3 #A29BFE #54A0FF
```

Note: the shop's purchasable avatars (Section 12) are a SEPARATE,
smaller list from these 11 free base avatars — purchased avatars unlock
additional options beyond the free base set, they don't replace it.
Confirm the exact merge logic (`allAvatars = [...AVATAR_BASES,
...unlockedAvatars not already in bases]`) when porting the avatar
picker UI.

---

## 14. In-app purchase products — exact 4 products

| Internal key | Product ID | Purchase Option ID | Coins granted | Display label | Kind |
|---|---|---|---|---|---|
| small | `100_coins` | `100-coins-buy` | 100 | "100 Coins" | consumable |
| medium | `500_coins` | `500-coins-buy` | 550 | "550 Coins" | consumable |
| large | `1200_coins` | `1200-coins-buy` | 1400 | "1400 Coins" | consumable |
| removeads | `ads_remove` | `ads-remove-buy` | 0 | "Remove Ads" | non_consumable |

Note the intentional bonus structure: the product ID names the BASE
coin count (e.g. `500_coins`), but the actual coins granted include a
bonus (550, not 500) — this is a deliberate marketing pattern in the
original, not a bug. Preserve the same product-ID-vs-actual-coins gap
when porting (don't "fix" it by renaming products or changing amounts).

These product IDs and purchase option IDs are **fixed and external** —
they must match exactly what's registered in the Google Play Console
for purchases to ever succeed in production. Do not invent new IDs.

---

## 15. AdMob — exact cadence numbers

```
Interstitial ad: shown after every 3 completed games.
                 Counter persisted to storage (survives force-quit/
                 restart) — Fix #88.

Rewarded ad cooldown: 5 minutes (300,000 ms) between watches.
                       Timestamp of last watch persisted to storage
                       (survives force-quit/restart) — Fix #89.

Banner: shown ONLY on the number-type-select and player-setup screens.
        See flutter-full-port-master-prompt.md Section 7 for the full
        behavioral ruleset (hide-on-modal, resume-vs-show pattern,
        retry/backoff on load failure, COPPA/Families tagging — all
        of that detail lives in the master prompt, not duplicated here).
```

---

## 16. Persisted storage keys (partial list, 34+ confirmed)

This is every key found via direct grep of `LS.set`/`LS.get` calls in
the source. When implementing the Flutter port's "Reset All Data"
function, cross-reference against this list — and re-run the grep
yourself against the live source before shipping, since this list may
not be 100% exhaustive (some keys may be referenced via a dynamic/
constructed string this grep pattern wouldn't catch).

```
mc_achs              — unlocked achievement IDs
mc_adGameCount       — interstitial cadence counter (Fix #88)
mc_adaptLvl          — integer adaptive difficulty (0-10)
mc_adsRemoved        — bool, true if ads_remove IAP owned
mc_animSpeed         — animation speed multiplier setting
mc_avatarCustom      — player 1 custom avatar config
mc_avatarCustom1     — (likely player slot variant — confirm exact
                        purpose against source rather than assuming
                        from name alone)
mc_avatarCustom2     — (as above)
mc_coins             — current coin balance
mc_colorblind        — bool/mode, colorblind palette setting
mc_dailyBossClaimed  — date key of last-claimed daily boss reward
mc_dailyChallenges   — daily challenge progress state
mc_dailyCoinsDate    — date key for daily coin bonus tracking
mc_dailyProgress     — daily challenge progress (may overlap with
                        mc_dailyChallenges — confirm distinct purpose
                        of each against source before assuming
                        duplication is a bug)
mc_dark              — dark mode toggle
mc_dyslexia          — dyslexia font toggle
mc_gamesPlayed       — lifetime games-played counter
mc_iapDeliveredTxs   — set of delivered IAP transaction IDs (dedup)
mc_lastRewardedAt    — timestamp of last rewarded ad watch (Fix #89)
mc_livesBonus        — extra lives purchased/granted count
mc_lowPerf           — low-performance mode toggle
mc_p2Data            — player 2 name/avatar data (Fix #28, #40 — must
                        be included in BOTH load-on-startup AND the
                        reset-all-data wipe list)
mc_puBonus           — power-up bonus pool per type (object keyed by
                        time/fifty/double/shield/freeze/switch)
... (additional keys exist for adaptLvlRaw, sound/vibration toggles,
    high scores, skill map, shop-owned items, settings not yet
    individually re-confirmed in this extraction pass — re-grep
    `LS\.(get|set)\('` against the live source for the complete,
    current list before finalizing the reset-all-data function)
```

This list is intentionally marked partial/honest rather than
presented as exhaustive — re-run the extraction yourself
(`grep -oE "(LS|Storage)\.(set|get)\('[a-zA-Z_0-9]+'" index.html | sort -u`)
against the current source before treating any persisted-key list as
final, since this is exactly the kind of detail that drifts as fixes
get added over time.

---

## 17. How this document relates to the other two

- **`flutter-visual-identity-spec.md`** — colors, fonts, border-radius,
  shadows, animation curves. Use for ANY UI/visual decision.
- **`flutter-full-port-master-prompt.md`** — methodology, AdMob/IAP
  *behavioral* rules (not the raw numbers — those are here), how to
  find fix comments in source, verification/reporting requirements,
  locked architecture decisions (vanilla Flutter, no RevenueCat).
- **This document** — the actual numbers: exact ranges, thresholds,
  formulas, lists, IDs, prices. Use for ANY "what's the exact value"
  question.

Read all three before starting implementation. None of them alone is
the complete spec — together, they close the gap between "read the
12,800-line source yourself" and "here's a guess at what it probably
does."
