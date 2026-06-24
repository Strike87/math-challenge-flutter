# Math Challenge: Boss Battle Edition — Flutter Port

A native Android port of the original HTML5 math game, rebuilt from the ground up
in Flutter + Dart. Preserves every gameplay feature from the web version while
running at native performance.

---

## Features (Full Clone)

### Game Modes
- **Standard** — classic timed quiz, 1 or 2 players
- **⚡ Blitz** — 60 seconds, answer as many as possible
- **💀 Death** — one wrong answer ends the run
- **💪 Survival** — 3 hearts, difficulty ramps every 5 correct, boss every 10
- **🔥 Combo** — build streaks for ×2 / ×3 / ×5 multipliers
- **🏆 Master** — 5-stage story mode with boss battles
- **🐲 Daily Boss** — fresh boss every day, deterministic per date

### Operations
- Addition, Subtraction, Multiplication, Division, Mixed
- Three number types: Natural, Integers (±), Rationals (decimals)
- Five difficulty tiers: Easy → Medium → Hard → Expert → INSANE
- Adaptive difficulty that tracks per-skill mastery

### Progression Systems
- 🪙 Coin economy (earned via correct answers + streaks)
- 🎯 14 achievements (first_win, speed_demon, perfect_score, streak_master, …)
- 🏆 Hall of Fame (top-10 high scores)
- 📊 Skill dashboard (per-operation mastery %)
- 📅 6 daily challenges (reset every 24h)
- 🛒 Coin shop (avatars, hats, power-up packs)
- 🔥 Login streak

### Power-Ups (single-player Standard only)
- ⏱️ +5s — adds 5 seconds to the current question
- ✂️ 50/50 — removes two wrong answers
- ✨ ×2 — doubles next correct answer's points
- 🛡️ Shield — absorbs one wrong answer
- ❄️ Freeze — pauses the timer
- 🔀 Swap — skips to a new question

### Accessibility
- 🌓 Dark mode toggle
- 🔊 Sound toggle
- 📳 Vibration toggle
- ♿ Dyslexia-friendly font option
- 🎨 Color-blind safe palette (Okabe-Ito based)
- 🚀 Performance mode (low-end devices)
- 📉 Reduce motion option
- ⏩ Adjustable animation speed (0.3× – 2.0×)

---

## Project Structure

```
math_challenge_flutter/
├── android/                      Native Android shell
│   ├── app/
│   │   ├── build.gradle          App-level Gradle config
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/com/example/math_challenge/MainActivity.kt
│   │       └── res/values/styles.xml
│   ├── build.gradle              Root Gradle config
│   ├── settings.gradle           Gradle settings + plugin management
│   └── gradle.properties         Gradle + AndroidX flags
├── lib/
│   ├── main.dart                 Entry point + MultiProvider setup
│   ├── theme.dart                Material theme derivation
│   ├── game_config.dart          Static content + tunable constants
│   ├── models/
│   │   ├── enums.dart            Operation / Difficulty / GameMode / PowerUp
│   │   ├── player.dart           PlayerState, Question, AvatarCustom
│   │   └── game_data.dart        MasterLevel, DailyBoss, Achievement, ShopItem
│   ├── services/
│   │   ├── storage.dart          SharedPreferences wrapper (LS-equivalent)
│   │   ├── settings.dart         Theme + a11y preferences (ChangeNotifier)
│   │   └── audio.dart            Audio + vibration service
│   ├── engine/
│   │   ├── game_state.dart       Central ChangeNotifier (≈ original `Game` class)
│   │   └── question_generator.dart  Question factory (≈ _buildQ + _applyNumType)
│   ├── screens/
│   │   ├── menu_screen.dart      Home screen with campaign + nav
│   │   ├── numtype_screen.dart   Number type selection
│   │   ├── config_screen.dart    Game setup (players, mode, diff, q count)
│   │   ├── player_screen.dart    Avatar + name setup
│   │   └── game_screen.dart      In-game HUD + question card + answer grid
│   └── widgets/
│       ├── common.dart           NeoButton, AvatarWidget, CoinPill, etc.
│       └── modals.dart           All modal dialogs (settings, win, shop, …)
├── pubspec.yaml                  Flutter dependencies
└── README.md                     This file
```

---

## Build Instructions (Android APK / AAB)

### Prerequisites
- Flutter SDK ≥ 3.0.0 (https://docs.flutter.dev/get-started/install)
- Android SDK 34 (installed automatically by Flutter)
- Java 17 (bundled with Android Studio, or install separately)
- An Android device or emulator (optional — `flutter run` deploys to either)

### One-time Setup
```bash
cd math_challenge_flutter
flutter pub get
flutter create --platforms=android --org com.example --project-name math_challenge .
```

> The `flutter create` step fills in any missing native scaffolding
> (`android/gradle/wrapper/gradle-wrapper.properties`, etc.) without
> overwriting the files we provide.

### Add Custom Fonts (Optional but Recommended)
The original game uses Baloo 2 + Plus Jakarta Sans. To match the look:
1. Download both from Google Fonts (`.ttf` files).
2. Drop them into `assets/fonts/` with these exact names:
   - `Baloo2-Bold.ttf`
   - `Baloo2-ExtraBold.ttf`
   - `Baloo2-Black.ttf`
   - `PlusJakartaSans-Medium.ttf`
   - `PlusJakartaSans-SemiBold.ttf`
   - `PlusJakartaSans-Bold.ttf`
   - `PlusJakartaSans-ExtraBold.ttf`

Without the fonts, Flutter falls back to the system sans-serif — fully
playable, just slightly different visually.

### Build a Debug APK
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Build a Release APK (for sideloading)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build an AAB (for Google Play Store upload)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Generate a Release Keystore (one-time, before Play Store upload)
```bash
keytool -genkey -v -keystore ~/math-challenge.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias math-challenge
```
Then add to `android/key.properties`:
```
storePassword=*****
keyPassword=*****
keyAlias=math-challenge
storeFile=/Users/you/math-challenge.jks
```
And reference it in `android/app/build.gradle` under `signingConfigs`.

---

## Performance Notes

This Flutter port is **faster than the original HTML version** for these reasons:

1. **Compiled, not interpreted** — Dart is AOT-compiled to native ARM in
   release builds; JS in a WebView is JIT-compiled at runtime.
2. **Skia rendering** — Flutter uses the Skia graphics engine directly on
   the GPU, avoiding the HTML layout/paint/composite pipeline.
3. **No DOM** — the original spent real time on layout reflows when
   updating score, lives, and combo badges. Flutter's widget rebuilds are
   diffed in O(1) per state change via `ChangeNotifier` + `Provider`.
4. **No Capacitor bridge** — the original Capacitor-wrapped HTML had to
   hop native ↔ JS for every vibration, sound, and storage call. This
   port calls native APIs directly via FFI plugins.
5. **Efficient timers** — `Timer.periodic` at 100ms is far cheaper than
   `requestAnimationFrame` + Date.now diffing for the countdown bar.

---

## AdMob Setup

The manifest is pre-configured with Google's **test** AdMob App ID
(`ca-app-pub-3940256099942544~3347511713`). To enable ads in the v1.1 update:

1. Add `google_mobile_ads: ^5.0.0` to `pubspec.yaml` under `dependencies:`.
2. Run `flutter pub get`.
3. Create a real AdMob account and register the app.
4. Replace the test ID in `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-YOUR-PUB-ID~YOUR-APP-ID"/>
   ```
5. Create banner + rewarded ad units in AdMob and wire them via
   the `google_mobile_ads` plugin in `lib/services/`.

> The current build does NOT call `MobileAds.initialize()` on startup
> — the game is fully playable without ads. Add the call in `main.dart`
> when you're ready to monetize.

> **Note**: `google_mobile_ads` and `confetti` were intentionally
> removed from the initial `pubspec.yaml` to keep the dependency
> footprint small and the build fast. Add them back when wiring up
> the corresponding features.

---

## Known Limitations (Polish Queue for v1.1)

1. **LowPerf mode** — flag is stored + toggleable but not yet wired to
   disable specific effects. Currently cosmetic only.
2. **Colorblind palette** — applied to operation colours in the menu
   but not yet to every chart/badge across all screens.
3. **Banner ad widget placement** — AdMob not yet integrated into the
   UI; placeholder only.
4. **Haptic feedback granularity** — currently fires light/heavy impact
   only; not yet differentiated per interaction type.
5. **Audio ducking on interruption** — `audio_session` package not yet
   added; background music (if added) would not pause on incoming calls.
6. **Saved-game migration** — save schema has no version field; future
   schema changes will need a migration step on load.

---

## Credits

- **Original game design**: Mr. Mohamed Khairy, Mathematics Supervisor
- **Flutter port**: Generated as a faithful 1:1 conversion preserving
  every gameplay system, mode, and UI affordance from the original
  HTML5 game.

---

## License

Personal / educational use. The original HTML game's licence terms apply
to the underlying game design and content. The Flutter port itself is
provided as-is for the original author's use.
