# Math Challenge — Visual Identity Spec for Flutter Implementation

This is the authoritative design reference for "Math Challenge: Boss Battle
Edition," extracted directly from the live, published app's source code
(not from memory or screenshots). Every value below is copied from the
actual CSS — do not invent alternative colors, spacing, or styles. When
implementing or reviewing Flutter UI, this document is the source of truth.

If anything in the Flutter app's current UI conflicts with this spec, the
spec wins. The goal is pixel-philosophy parity: a player switching from
the live app to this version should feel like it's the same game, not a
redesign.

---

## 1. Overall theme

A warm, energetic, kid-friendly "neo-glassmorphism" aesthetic — soft cream
background, frosted-glass white cards with subtle transparency, bold
rounded typography, and a coral/orange primary action color. Think
"friendly mobile game for 7-12 year olds doing math practice," not
"corporate edtech dashboard."

The launch/splash color is a deep purple (#5426af) — this is intentionally
DIFFERENT from the in-app cream background; it's only used for the splash
screen and app icon background, never inside the actual game UI.

---

## 2. Color tokens (exact hex/rgba values)

### Core palette
```
coral:  #FF5757   — primary brand color, CTAs, primary buttons
mango:  #FF9B21   — secondary accent, warm highlights
sky:    #00C2FF   — secondary brand color, info/cool accents
mint:   #00D68F   — success states, positive feedback
grape:  #8457E9   — tertiary accent (WCAG-AA adjusted from #8B5CF6)
lemon:  #FFE135   — coins, rewards, highlights
punch:  #FF3D71   — danger/wrong-answer states
coin:   #FFD700   — currency icon color specifically
```

### Semantic mapping
```
primary:   coral   (#FF5757)
secondary: sky     (#00C2FF)
accent:    mango   (#FF9B21)
success:   mint    (#00D68F)
danger:    punch   (#FF3D71)
```

### Surfaces (the active theme — glassmorphism pass)
```
background:      #FDF8F3   (warm cream, NOT pure white)
surface (cards): rgba(255,255,255,0.75)   — frosted glass, 75% opacity white
surface2:        rgba(255,255,255,0.45)   — lighter frosted variant
border:          rgba(255,255,255,0.85)
border-md:       rgba(255,200,150,0.4)    — warm peachy border tint
text (primary):  #1E1B18   (near-black, warm tint)
text-2:          #3D3530
muted:           #7A6B5E   (WCAG-AA adjusted for 4.5:1 contrast)
```

### Splash/launch only (NOT used in-app)
```
splash background: #5426af  (deep purple)
```

### Dark mode
A dark variant exists (toggle-based). If implementing dark mode, mirror
the same token structure with dark-appropriate values — don't guess;
flag this as a follow-up rather than inventing dark colors not in the
original source.

---

## 3. Typography

```
Headings/display: 'Baloo 2' — a bold, rounded, friendly display font.
                   Weights used: 700 (bold), 800 (extrabold), 900 (black)
Body/UI text:      'Plus Jakarta Sans' — clean, modern sans-serif.
                   Weights used: 500, 600, 700, 800
Accessibility font: 'OpenDyslexic' (toggle-based alternative for body text)
```

Buttons specifically use **Baloo 2 at weight 800** with `letter-spacing: 0.5px`
— this gives the bold, chunky, game-like button label feel. Don't use a
generic system font for primary CTAs.

In Flutter: bundle both font families (you already have the .ttf files in
`assets/fonts/`), set Baloo2 for headlines/titles/buttons, Plus Jakarta Sans
for body text and labels.

---

## 4. Border radius scale (use these exact tokens, not arbitrary values)

```
r-sm:  12px   — small elements (chips, badges, small buttons)
r-md:  18px   — standard buttons, inputs
r-lg:  24px   — primary action buttons, prominent cards
r-xl:  28px   — main content cards, modals
```

Never use a radius outside this 4-step scale. If something needs to look
"more rounded" than r-xl, that's a sign it should be a different component
shape (e.g., a circle/pill), not a bigger arbitrary radius.

---

## 5. Shadows

```
shadow-sm:   0 2px 12px rgba(0,0,0,0.07)   — subtle lift
shadow-md:   0 6px 24px rgba(0,0,0,0.10)   — standard card elevation
shadow-lg:   0 16px 48px rgba(0,0,0,0.13)  — modals, prominent overlays
shadow-card: 0 4px 20px rgba(0,0,0,0.08)   — default card shadow
```

Primary buttons get a colored shadow that matches their fill, e.g. the
coral primary button casts:
```
0 6px 20px rgba(255,87,87,0.35), 0 3px 0 rgba(180,40,20,0.2)
```
That second shadow value (`0 3px 0 ...`) creates a subtle "3D pressed
edge" look at the bottom of the button — replicate this two-layer shadow
pattern on primary CTAs in Flutter, not a single flat shadow.

---

## 6. Button styles

**Base button (`.btn`):**
- Padding: 13px vertical, 28px horizontal
- Border radius: r-md (18px)
- Font: Plus Jakarta Sans, weight 700, size ~15px
- No border
- Press feedback: scale down to 0.95 + translateY(2px) — a satisfying
  "pushed in" tactile effect, not just a color change

**Primary button (`.btn-primary`):**
- Background: linear-gradient(135deg, #FF5757 → #D4681A) — coral to
  burnt-orange diagonal gradient, NOT a flat color
- Border radius: r-lg (24px)
- Thin white border at 30% opacity (`1px solid rgba(255,255,255,0.3)`)
- Font: Baloo 2, weight 800, letter-spacing 0.5px
- Two-layer shadow as described above

In Flutter terms: this is a `Container` with `BoxDecoration.gradient`
(LinearGradient, begin/end roughly topLeft→bottomRight to approximate
135deg), not a flat `ElevatedButton` color.

---

## 7. Card entrance animation

Every card/modal that appears uses this entrance:
```
from: opacity 0, translateY(16px), scale(0.97)
to:   opacity 1, translateY(0), scale(1)
```
Duration ~0.2s, easing `cubic-bezier(0.4, 0, 0.2, 1)` (this is the
Material "standard" ease curve — in Flutter, `Curves.easeOutCubic` or a
custom Cubic(0.4, 0, 0.2, 1) is the right match).

This should be the default appearance animation for: game mode cards,
question cards, modals, achievement toasts, results screens. Consistency
matters more than cleverness here — don't give different screens different
entrance animations.

---

## 8. General transition speed

The global transition timing token is `0.18s cubic-bezier(0.4, 0, 0.2, 1)`
— used for hovers, toggles, small state changes (not the card entrance
above, which is slightly different/slower at 0.2s). Keep UI transitions
snappy — this app should feel responsive and energetic, not slow or
heavily eased. Avoid anything longer than ~300ms for routine UI feedback.

---

## 9. Background treatment

The app background is a warm cream (#FDF8F3), not pure white and not a
flat single color in the original concept (there are decorative mesh
gradient elements in some versions) — but the cream base is the most
important, consistent element. Avoid stark white (#FFFFFF) backgrounds;
they read as cold/clinical compared to the original's warm tone.

Cards/surfaces are NOT solid white either — they use ~75% opacity white
over the cream background, creating a soft frosted-glass effect. In
Flutter, approximate this with `Colors.white.withOpacity(0.75)` containers,
optionally with a `BackdropFilter` blur if performance allows (the original
uses `backdrop-filter: blur()` on some cards, but disables it on low-end
devices for performance — mirror that conditional behavior if you
implement blur).

---

## 10. What this spec does NOT cover (intentionally)

- Exact per-screen layouts (menu structure, game screen HUD arrangement) —
  reference the actual screen widget files for structural layout; this
  doc is about color/type/shape/motion tokens only
- Icon/emoji choices — these are already ported in game_config.dart and
  should stay as-is unless explicitly changed
- Sound design — out of scope for this visual spec
- Dark mode exact values — flagged above as a follow-up, not guessed here

---

## 11. How to use this spec

When implementing or fixing any UI element in the Flutter app:

1. Check this doc first for the relevant token (color, radius, shadow, font)
2. Use the Flutter equivalent of the exact value — don't approximate or
   pick "something close"
3. If a screen currently uses a value NOT in this spec (e.g., a random
   hex color, a non-scale border radius), treat that as a bug to fix,
   not a design decision to preserve
4. If you're unsure whether something should match this spec or was a
   deliberate Flutter-specific adaptation, ask rather than guessing

The standing principle: **if a Flutter screen doesn't look like it was
designed by the same person who designed the rest of the app, it's wrong.**
