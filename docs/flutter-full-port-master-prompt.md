# Math Challenge — Full 1:1 Behavioral Port Master Prompt (Flutter)

## Ground rule before anything else

The ONLY acceptable source of truth is the actual original source file
(the Capacitor/HTML `index.html`, ~12,800 lines). Do not infer behavior
from the README, from the existing Flutter scaffold's comments, or from
general "how math games usually work" assumptions. If a rule, threshold,
formula, or condition isn't explicitly visible in the original source,
say "I could not find this in the source" rather than inventing a
plausible-sounding value.

This port has a 102-item documented fix history in the original. Many
of those fixes encode non-obvious, hard-won behavior (race conditions,
off-by-one errors, policy compliance details). Treat every fix as a
REQUIREMENT, not a historical curiosity — if a fix exists, the bug it
prevented must not be reintroduced in the Flutter port.

### How to actually find these fixes in the source

Every fix referenced in this document (e.g., "Fix #178") corresponds to
a real inline comment in the original `index.html`, directly above or
beside the line(s) it touches. The format is one of:
```
/* Fix #169: darkened from #8B5CF6 for WCAG AA 4.5:1 with white */
/* Fix #169 */
/* Fix #166→#173: match the web cover color so there's no flash ... */
// Fix #28: mc_p2Data was saved by flushSaves but never loaded
```

To locate every fix mentioned in this document, search the source for
the literal string `Fix #` — this returns 263 matches across the file,
each one anchoring a real, specific change to a real line of code. For
example:
```
grep -n "Fix #178" index.html
grep -n "Fix #" index.html   # full list, all 263
```

When this document says "see Fix #N", your job is to:
1. Grep the original source for that exact fix number
2. Read the comment AND the surrounding code it annotates (the comment
   alone is often a one-line summary; the actual logic is in the code
   immediately around it)
3. Replicate the resulting behavior in Flutter

**If you grep for a fix number cited in this document and find nothing**,
do not invent what it might have meant. Report it as: "Fix #N cited in
the spec but not found in source — flagging for clarification" rather
than guessing or silently skipping it. It's possible a fix number was
mistyped in this document, or refers to a sub-fix (e.g., #171a/b/c/d
are sub-labels of #171 and may appear as `Fix #171a` in the comment, not
just `Fix #171`) — check for lettered variants before concluding it's
missing.

**Hard constraint on reporting**: at the end of every section below, you
must produce a verification note in one of these three forms — no other
phrasing is acceptable:
- "VERIFIED: ran on device, observed [specific behavior], matches source"
- "IMPLEMENTED, NOT YET VERIFIED ON DEVICE: [what you wrote, and why you
  believe it matches, with a citation to the exact original code/line]"
- "COULD NOT REPLICATE: [specific platform limitation], proposed Flutter
  equivalent: [X], behavioral difference: [Y]"

Do not write "Done" or "Fully implemented" as a standalone claim.

---

## 0. Locked architectural decisions — do not revisit these

Two technology choices have already been made deliberately, after
explicit consideration of alternatives. Do not second-guess them, do
not suggest swapping them "for better results," and do not pull in any
of the rejected options as a dependency, even for a small isolated
piece of the app. If you believe one of these decisions is wrong,
say so explicitly and explain why — do not silently substitute a
different approach.

### Game engine: vanilla Flutter — NOT Flame, NOT Bonfire

This app is a form-based quiz/UI app: text, buttons, modals, timers,
a HUD, and some particle/confetti effects on win states. There is no
sprite movement, no physics, no camera, no tilemap, and no continuous
60fps render loop driving gameplay. The original Capacitor/HTML version
proves this architecture works fine — it's DOM elements and CSS
animations, the direct equivalent of Flutter's widget tree plus
`AnimationController`.

- Do NOT add `flame` or `bonfire` as dependencies.
- Build all screens as normal Flutter widgets (`StatefulWidget` /
  state management of your choice, consistent with whatever the
  existing Flutter scaffold already uses — check before introducing a
  new state management approach).
- Particle/confetti effects: use `CustomPainter`, `AnimationController`,
  or a lightweight existing package built for exactly this (e.g.
  confetti-style packages) — not a game engine.
- If a future feature genuinely needs sprite-like animation (e.g., an
  animated boss creature), prefer a small embedded animation solution
  (Rive, Lottie, or a hand-rolled `CustomPainter`) scoped to that one
  widget — do not adopt a game engine for the whole app to serve one
  animated element.

### In-app purchases: vanilla `in_app_purchase` — NOT RevenueCat

This app has exactly 4 one-time products (3 consumable coin packs +
1 non-consumable ad-removal) and NO subscriptions, now or planned. This
was a deliberate decision, not an oversight.

- Do NOT add `purchases_flutter` (RevenueCat) as a dependency.
- Use the official `in_app_purchase` Flutter package directly against
  Google Play Billing.
- Do NOT build subscription-shaped abstractions "for future
  flexibility" — no entitlement tiers, no trial/grace-period handling,
  no renewal logic. Build exactly what 4 one-time products need: query
  products, initiate purchase, verify/acknowledge, deliver, restore
  non-consumables only. Keep it as simple as the actual requirement.
- If subscriptions are ever added in a future version, that is the
  correct time to re-evaluate RevenueCat — not now, and not
  speculatively.

---

## 1. Core game loop & question generation (per mode)

Port the exact logic for all 7 modes: Standard, Blitz, Death, Survival,
Combo, Master, Daily Boss.

For EACH mode, replicate exactly:
- Timer behavior (per-question vs global; exact durations per difficulty)
- Win/lose conditions
- Score formula, including streak/combo multipliers
- How questions are generated per operation (+, −, ×, ÷, mixed) and per
  number type (natural, integers, rationals) — including the exact
  difficulty-to-number-range mapping
- Answer comparison: use epsilon tolerance (1e-9) for float comparison,
  NEVER strict `==` on doubles (this was Fix #11 in the original —
  reintroducing strict equality will silently mark correct rational
  answers as wrong)
- Distractor (wrong answer choice) generation — must produce plausible,
  not random, wrong answers
- Adaptive difficulty: the per-skill mastery tracking system that nudges
  difficulty up/down based on performance (Fix #8, #9, #10 — these fixed
  real bugs in mastery score persistence; read the original's mastery
  update logic carefully, don't approximate it)

### Master mode specifically
- 5 story stages, each with its own operation/difficulty/numberType/goal/
  timer/boss-emoji/story-text — port the exact stage definitions
- Stage advancement logic and the "story" text shown between stages
- The `masterWin` flag and its exact trigger condition (Fix #23 — do not
  use a length-comparison condition that can never become true)

### Daily Boss specifically
- Deterministic boss-of-the-day selection from the date (so every player
  sees the same boss on the same day)
- 3 lives, fixed goal/timer/reward per boss
- Once-per-day reward claim, tracked by date key
- Note: the existing Flutter scaffold uses `day % bosses.length` for
  determinism with only 6 bosses defined, causing a 6-day repeat cycle.
  Confirm whether the original source has a larger boss roster or a
  different seeding approach, and match it — do not assume 6 is correct
  just because that's what currently exists in the Flutter code.

---

## 2. Power-ups

Port all power-up types with their exact mode-compatibility rules. The
original explicitly REJECTS certain power-ups in certain modes up-front
(Fix #21 — time/freeze power-ups rejected in blitz/combo before the
power-up slot is even consumed, not after). Replicate the rejection
point exactly, not just the end behavior.

---

## 3. Achievements

Port all achievement definitions with EXACT unlock conditions — not
approximated thresholds. Specific values that must match exactly:
- Mastery/skill thresholds (confirm exact percentage — original was
  corrected from 85% to 90% in Fix #39; verify which is the true current
  value in the source, don't guess)
- Streak/accuracy/speed thresholds
- The Math Wizard / Math Legend distinction if present in the source
  (these were deliberately differentiated to fire at different
  milestones — Stage 3 completion vs full 5-stage completion — do not
  collapse them back into firing at the same moment)

Achievement toasts must queue, not stack at the same screen position,
if multiple unlock simultaneously (Fix #54).

---

## 4. Daily challenges

Port all daily challenge definitions AND confirm every single one has
a real trigger call somewhere in the game loop. During the prior
analysis pass, one challenge (`master_stage`) was found defined but
never triggered in the Flutter scaffold — treat this as the type of
bug to actively hunt for: a challenge existing in a definition list is
NOT evidence it's wired up. For every challenge defined, find and cite
the exact line where its progress is updated.

The daily-progress write must be debounced, not fired on every single
correct answer (Fix #6 — a missing/broken debounce was a real
performance bug in the original).

---

## 5. Coin economy & shop

- Coins awarded on win/correct-answer/achievement — exact amounts per
  source
- Shop items: avatars, hats, accessories — with `consumable` vs
  permanent-ownership distinction. Consumable items must remain
  purchasable repeatedly; permanent items must lock after one purchase
  (Fix #26 — a missing consumable flag caused permanent re-lock bugs)
- Persist purchases and coin balance; survive app restart and the
  "Reset All Data" flow consistently — confirm the reset wipes EVERY
  relevant key, not a partial list (Fix #40, #177 in the original were
  both about keys missing from the reset-all-data wipe list — this is
  a recurring bug category, check the Flutter reset function against
  every single persisted key, not just the obvious ones)

---

## 6. Settings & accessibility

Port every toggle and confirm it actually affects behavior, not just
UI state:
- Dark mode — actually changes rendered colors throughout, not just one
  screen
- Sound / vibration toggles — actually gate all sound/vibration calls
  through a single central check (Fix #51 — originally vibration calls
  were scattered and not all gated; centralize this in Flutter too)
- Dyslexia font — actually swaps the font family app-wide
- Colorblind palette — must reach the actual game screen colors (answer
  buttons, feedback colors), not just settings/menu chrome. The current
  Flutter scaffold has this gap — fix it as part of this port, don't
  leave it partial.
- Reduce motion — must actually skip animations (confetti, transitions),
  checked against the OS-level `prefers-reduced-motion` equivalent in
  Flutter AND a manual in-app toggle (Fix #170, #108→#170 — the original
  had a bug where it checked the wrong condition and reduce-motion never
  actually activated; don't repeat that mistake)
- Performance/low-power mode — must ACTUALLY disable expensive effects
  (blur, particle counts, animation complexity), not just exist as a
  toggle with no effect. The current Flutter scaffold admits this is
  "cosmetic only" — this must be genuinely wired up as part of full
  parity, not left as a no-op.

---

## 7. AdMob — behavioral parity (NOT code parity — see note below)

**Platform note**: The original uses `@capacitor-community/admob`.
Flutter's equivalent is the official `google_mobile_ads` package (per
the locked decision in Section 0 — vanilla Flutter, no game-engine or
third-party purchase/ad abstraction layers). The API shapes differ. Your job is to replicate the RULES and BEHAVIOR
below exactly, using whatever `google_mobile_ads` calls achieve the
same outcome — not to find a literal API match.

Required behaviors, each one was a specific bug fix in the original —
do not treat any of these as optional polish:

- **Banner placement rule**: banner shows ONLY on the number-type-select
  and player-setup screens. It must NOT show on the menu, NOT during
  gameplay, NOT on results screens, NOT behind any open modal/dialog.
- **Banner + modal interaction**: if a modal or dialog opens while on a
  banner-eligible screen, HIDE the banner immediately, and re-show it
  only when the modal closes AND the screen is still banner-eligible
  (Fix #178, #189 — `_canShowBannerNow()` / `_hasBannerBlockingOverlay()`
  in the original is the exact logic to replicate: check screen state
  AND overlay state together, every time, not just on screen change)
- **Banner show/resume distinction**: register the banner once via the
  "show" call; for every subsequent show, use a "resume" pattern (not
  re-registering a brand new banner each time) (Fix #183). In
  `google_mobile_ads`, find the equivalent of "load once, show/hide
  without re-requesting" rather than creating a new BannerAd instance
  on every screen transition.
- **Concurrent-call protection**: prevent overlapping/duplicate banner
  show requests racing each other (Fix #189 — `_bannerShowPromise`
  dedup pattern in the original)
- **Banner load failure recovery**: on load failure, retry with
  exponential backoff (the original uses 5s → 60s cap), and reset the
  "registered" state on failure so a resume call isn't issued against a
  destroyed/non-existent ad view (Fix #187)
- **Interstitial cadence**: shown after every 3 completed games, with
  the counter PERSISTED across app restarts/force-quits, not reset to 0
  on every launch (Fix #88)
- **Rewarded ad cooldown**: 5-minute cooldown between rewarded ad
  watches, persisted across force-quits (Fix #89)
- **Rewarded ad reward delivery**: listen for the reward via the SDK's
  event/listener mechanism, not just a single return value from the
  show call — some plugin versions only fire reward confirmation via
  event (Fix #172). Confirm `google_mobile_ads`'s `onUserEarnedReward`
  callback is wired correctly and test it actually fires.
- **Rewarded ad early-exit handling**: if the user closes the ad before
  it completes, show clear feedback that they didn't earn the reward —
  do not silently grant or silently fail (Fix #171b)
- **Banner resume after rewarded ad**: after a rewarded ad closes
  (whether earned or not, and on error), the banner state must resume
  correctly on the underlying screen (Fix #171a)
- **COPPA / Families compliance — THIS IS NOT OPTIONAL**:
  - Tag all ad requests as child-directed
    (`tagForChildDirectedTreatment = true` equivalent)
  - Restrict ad content rating to General audiences only
    (`maxAdContentRating = General` — note the original had a bug using
    the wrong enum value `'G'` instead of the correct `'General'` string,
    Fix #188 — confirm whatever you set matches the CURRENT correct
    value expected by the SDK, don't copy a stale enum name)
  - This must be configured before the SDK initializes, not after first
    ad request
- **Production vs test ad unit IDs**: ad unit IDs must switch based on
  debug vs release build, the same way the original does — never ship
  test ad unit IDs in a release build, never ship production ad unit IDs
  in a debug build (this risks AdMob account penalties)

---

## 8. In-app purchases — behavioral parity (NOT code parity)

**Platform note**: The original uses `capacitor-plugin-cdv-purchase`.
Flutter's equivalent is the official `in_app_purchase` package (per
the locked decision in Section 0 — NOT RevenueCat; no subscriptions
exist or are planned). Again: replicate behavior and rules, not
literal API calls.

Required behaviors — each is a specific, previously-debugged requirement:

- **Products**: 3 consumable coin packs + 1 non-consumable ad-removal
  product. Confirm exact product IDs from the original source (these
  are case-sensitive and must match whatever is registered in the
  Play Console for this to ever work in production) — do not invent
  new IDs.
- **Adult gate before purchase**: show a simple math-question gate
  (e.g., a two-digit addition problem) BEFORE initiating any real
  purchase flow, required for Families/kids-app policy compliance. This
  is not optional UX polish — it is a Play Store policy requirement for
  this app's category.
- **Duplicate transaction protection**: track delivered transaction IDs
  and check BEFORE granting the product, then record the ID AFTER
  successful delivery — in that exact order. Reversing this order
  creates a race condition allowing double-delivery of coins on rapid
  duplicate purchase callbacks.
- **Transaction acknowledgement**: every approved purchase must be
  acknowledged/finished with the platform within the required window
  (Google enforces a 3-day auto-refund if not acknowledged) — confirm
  Flutter's `in_app_purchase` completePurchase equivalent is called on
  every successful delivery path, including retried/recovered ones.
- **Restore purchases — consumables vs non-consumables**: Restore must
  ONLY restore the non-consumable ad-removal product. Coin packs
  (consumables) must NEVER be restored — restoring a consumed
  consumable is both against policy and would let users get free coins
  repeatedly via uninstall/reinstall.
- **Auto-restore on launch**: check for and apply ad-removal ownership
  automatically on app start, in addition to a manual "Restore
  Purchases" button — don't rely on the user remembering to tap restore.
- **Error handling**: distinguish at minimum: user-cancelled (no error
  toast — this is an expected, calm outcome), already-owned (auto-
  restore instead of showing an error), billing-unavailable,
  network-error, and unknown/developer error (generic message + log).
  Do not show the same scary error message for a user simply backing
  out of the purchase dialog.
- **Native-only enforcement**: on native Android, if the purchase
  plugin/store is unavailable for any reason, show an error and grant
  NOTHING. There must be no fallback path that silently grants coins or
  ad-removal without a real verified purchase on a native build. (A
  demo/simulated purchase flow is acceptable ONLY when running in a
  non-native/browser/dev context, clearly gated so it can never reach
  a real device build.)

---

## 9. Persistence & data integrity

- All game state, settings, achievements, coins, purchases, and
  high-scores must persist across app restarts (not just backgrounding)
- The original wraps each individual persisted-key write in its own
  try/catch so a single storage quota error doesn't abort the entire
  save flow (Fix #50) — don't use one big try/catch around all writes
  combined
- The "Reset All Data" feature must clear EVERY persisted key the game
  uses — cross-reference every `Storage.get`/`Storage.set` call site
  against the reset function's wipe list and confirm nothing is missed

---

## 10. What "done" means for this task

This port is NOT complete when the code compiles and the menu renders.
It is complete only when, for every section above, you have either a
VERIFIED note (you ran it and watched it happen) or an honestly-labeled
IMPLEMENTED-NOT-VERIFIED or COULD-NOT-REPLICATE note. Submit your final
report organized by the 10 section numbers above, in that order, with
one status line per bullet point — not a single paragraph claiming
overall success.

If you find a behavior in the original source that contradicts something
written in this document, the SOURCE wins — flag the discrepancy and
follow the source, then tell me about it so this spec can be corrected.
