# Math Challenge: Boss Battle Edition

![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter\&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android\&logoColor=white)
![Version](https://img.shields.io/badge/version-1.0.8%2B37-blue)
![CI](https://github.com/Strike87/math-challenge-flutter/actions/workflows/ci.yml/badge.svg)

**Math Challenge** is a fast-paced educational mathematics game built with **Flutter + Dart**.

It combines arithmetic practice with game modes, boss battles, adaptive learning, progression systems, quests, daily challenges, accessibility features, and optional Google Play Games cloud services.

The project began as a native Flutter recreation of the original HTML5 Math Challenge game and has since grown into a significantly larger educational game platform.

---

## 🎮 Current Release

**Version:** `1.0.8+37`
**Platform:** Android
**Package:** `com.mohamedk.mathchallenge`
**Framework:** Flutter / Dart

---

## ✨ Highlights

* 🎮 Multiple game modes with different scoring and survival rules
* 🧠 Adaptive difficulty and per-skill mastery tracking
* 🎯 Weak Skills Practice
* 🗺️ Operation Quest with **10 trails and 30 stages**
* 🐲 Boss battles and Daily Boss challenges
* 👥 Local two-player support
* ✅ 4-choice and True / False answer styles
* 🔢 Natural numbers, integers, decimals, and mixed mathematics
* 🏆 Achievements, Hall of Fame, coins, streaks, and progression
* 🛒 Coin shop, avatars, cosmetics, and power-ups
* ☁️ Google Play Games Services and Saved Games cloud synchronization
* 👨‍👩‍👧 Family-aware age-range handling
* ♿ Accessibility, reduced-motion, dyslexia, and color-vision options
* ⌨️ Keyboard and directional-focus navigation
* 📱 Offline-capable core gameplay
* 📺 AdMob and Google Play Billing integration

---

# 🎮 Game Modes

Math Challenge provides several different ways to play.

### ⭐ Standard

The classic Math Challenge experience.

Choose an operation, difficulty, question count, number type, and answer style, then complete the round while building the highest score possible.

Standard mode supports both **single-player and local two-player gameplay**.

---

### ⚡ Blitz

A race against the clock.

You have **60 seconds** to solve as many questions as possible.

Speed and accuracy both matter.

---

### 💀 Death

One mistake ends the run.

Death mode rewards careful thinking while maintaining pressure.

---

### 🔥 Combo

Build consecutive correct answers to increase your score multiplier.

Long streaks can produce:

* ×2
* ×3
* ×5

multipliers.

---

### 💪 Survival

Start with **3 hearts** and survive as long as possible.

Difficulty increases as the player progresses, with increasingly challenging questions and regular boss encounters.

---

### 🏆 Master

A staged challenge mode with dedicated progression and boss battles.

Each stage can define its own:

* difficulty
* operation
* number type
* timer
* objective
* boss configuration

---

### 🐲 Daily Boss

A deterministic boss challenge generated from the current date.

Players receive a new boss challenge each day.

---

# 🗺️ Operation Quest

Operation Quest turns mathematics practice into a structured progression campaign.

The current campaign contains:

**10 trails • 30 stages**

Each trail contains:

* Easy
* Medium
* Hard

stages.

Every stage contains **10 questions** and awards up to **3 stars**.

### ⭐ Star System

* **10 correct:** ★★★
* **8–9 correct:** ★★
* **6–7 correct:** ★
* **0–5 correct:** no star

Earning at least **1 star** unlocks the next stage.

The player's best result is preserved and cannot be reduced by replaying a stage.

---

## Operation Quest Trails

### 1. ➕ Addition

Learn and master addition from basic sums to harder challenges.

### 2. ➖ Subtraction

Progress from simple differences to advanced subtraction.

### 3. ✖️ Multiplication

Develop multiplication skills and times-table fluency.

### 4. ➗ Division

Practice division and quotient reasoning.

### 5. 🔀 Mixed Operations

Switch between Addition, Subtraction, Multiplication, and Division.

### 6. ❓ Missing Operation

Determine which mathematical operator makes an equation correct.

Example:

```text
8 ? 4 = 12
```

### 7. 🔎 Missing Number

Find the missing value inside an equation.

Examples:

```text
? + 7 = 15
9 × ? = 27
```

### 8. ✅ True / False

Judge whether mathematical statements are correct.

### 9. ➕➖ Integers

Practice signed numbers using positive and negative values.

### 10. 🔢 Decimals

Work with decimal Addition, Subtraction, Multiplication, and Division.

---

# 🧠 Adaptive Learning

Math Challenge includes an adaptive learning system designed to respond to player performance.

The game tracks skill mastery across mathematical operations and uses performance evidence to help select an appropriate level of challenge.

The internal difficulty ladder is:

```text
Easy → Medium → Hard → Expert → Insane
```

The normal Game Setup interface intentionally exposes only:

```text
Easy
Medium
Hard
```

**Expert** and **Insane** remain internal progression tiers used by adaptive and advanced gameplay systems.

---

# 🎯 Weak Skills Practice

Weak Skills Practice uses existing mastery information to identify areas where additional practice may be useful.

The system is designed to avoid immediately labeling a skill as weak after only a small number of questions.

Practice rounds focus on a selected skill instead of constantly changing the operation mix while the player is answering.

This keeps the experience understandable and avoids turning adaptive learning into a hidden black box.

---

# 🔢 Mathematics

## Operations

The main game supports:

* ➕ Addition
* ➖ Subtraction
* ✖️ Multiplication
* ➗ Division
* 🔀 Mixed Operations

Special gameplay mechanics additionally support:

* Missing Operation
* Missing Number
* True / False

---

## Number Types

### Natural Numbers

Standard positive-number arithmetic.

### Integers

Positive and negative values.

### Rationals / Decimals

Decimal-number mathematics.

### Mixed

Advanced gameplay can combine multiple number domains.

---

# ✅ Answer Styles

Math Challenge supports multiple ways to answer questions.

### 4 Choices

Traditional multiple-choice gameplay with four possible answers.

### True / False

Determine whether the displayed equation is mathematically correct.

Scoring is adjusted for the lower number of available choices.

---

# 🪙 Progression

Math Challenge includes several long-term progression systems.

### Coins

Coins are earned through gameplay and can be spent inside the Coin Shop.

### Achievements

The game contains **14 achievements**, including milestones based on:

* games played
* accuracy
* speed
* streaks
* scores
* skill mastery
* progression

### Hall of Fame

Stores the player's best high scores.

### Daily Challenges

Daily objectives provide additional reasons to return and practice.

### Login Streak

Repeated play contributes to the player's ongoing progression.

---

# 🛒 Coin Shop

Coins can be used to unlock and purchase gameplay content such as:

* avatars
* cosmetic items
* hats
* power-up resources

The shop supports both touch and keyboard interaction.

---

# ⚡ Power-Ups

Power-ups are available in supported single-player gameplay.

### ⏱️ +5 Seconds

Adds five seconds to the current question timer.

### ✂️ 50/50

Removes two incorrect answers from a four-choice question.

### ✨ ×2

Doubles the score from the next correct answer.

### 🛡️ Shield

Protects the player from one incorrect answer.

### ❄️ Freeze

Temporarily pauses the question timer.

### 🔀 Swap

Replaces the current question with a new one.

---

# ☁️ Google Play Games & Cloud Save

Math Challenge contains a Google Play Games Services foundation with Saved Games synchronization.

The cloud-save system includes support for:

* local progress snapshots
* Google Play Saved Games transport
* cloud revision metadata
* synchronization
* merge lineage
* conflict handling
* conflict review
* synchronized settings
* reset-everywhere workflows

Cloud synchronization is designed to remain non-blocking so core gameplay can continue even when online services are unavailable.

---

# 👨‍👩‍👧 Family-Aware Experience

Math Challenge uses a neutral **age-range selector** rather than requesting a player's exact date of birth.

Family eligibility influences access to online and purchasing-related features.

The goal is to maintain a child-appropriate experience while keeping core mathematics gameplay locally available.

Advertising requests use family-oriented safeguards, including child-directed and non-personalized ad policies where required.

---

# ♿ Accessibility

Math Challenge includes several accessibility and comfort options.

* 🌓 Dark mode
* 🔊 Sound controls
* 📳 Vibration controls
* ♿ OpenDyslexic font option
* 🎨 Color-vision-friendly palette option
* 📉 Reduce Motion
* ⏩ Adjustable animation speed
* 🚀 Low-performance mode
* ⌨️ Keyboard-operable controls
* 🧭 Directional focus navigation
* ⎋ Modal keyboard / Escape handling

The application also respects platform reduced-motion preferences.

---

# ⌨️ Keyboard & Large-Screen Input

The Flutter version is designed to work beyond touch-only phones.

Keyboard support has been expanded across:

* shared buttons
* Game Setup
* Player Setup
* gameplay controls
* power-ups
* Coin Shop controls
* modal dialogs
* directional focus movement

This also improves compatibility with larger Android devices and Google Play Games on PC-style input environments.

---

# 📱 Offline Gameplay

The core game is designed to remain playable without a continuous internet connection.

Features that depend on external platform services—including ads, cloud synchronization, purchases, or Play Games—may require network connectivity.

Core question generation and normal gameplay remain local.

---

# 🏗️ Project Architecture

The project has evolved from its original flat Flutter-port structure into a progressively modularized architecture.

```text
lib/
├── constants/
├── engine/
│   ├── game_state.dart
│   └── question_generator.dart
│
├── features/
│   ├── adaptive/
│   ├── cloud_save/
│   ├── economy/
│   ├── family/
│   ├── gameplay/
│   ├── modals/
│   ├── operation_quest/
│   └── weak_skills/
│
├── models/
├── screens/
├── services/
├── widgets/
│
├── game_config.dart
├── main.dart
└── theme.dart
```

Feature modules are increasingly separated into domain, application, data, and presentation responsibilities where appropriate.

The project still retains a central `GameState` for compatibility with the existing gameplay system while feature logic is progressively extracted behind focused policies and services.

---

# 🧪 Testing & Quality

The repository contains an extensive automated test suite covering gameplay behavior and regressions.

Testing includes areas such as:

* question generation
* adaptive difficulty
* gameplay scoring
* Survival progression
* Master mode
* Operation Quest
* persistence
* achievements
* cloud save
* economy
* family eligibility
* input behavior
* responsive UI behavior
* visual parity / golden tests
* production-safety configuration

GitHub Actions CI is included in:

```text
.github/workflows/ci.yml
```

Run the main local checks with:

```bash
flutter analyze
flutter test
```

For integration tests:

```bash
flutter test integration_test
```

---

# 🚀 Getting Started

## Requirements

Install:

* Flutter SDK with Dart 3 support
* Android Studio / Android SDK
* Java 17
* Git

Verify the Flutter environment:

```bash
flutter doctor
```

---

## Clone the Repository

```bash
git clone https://github.com/Strike87/math-challenge-flutter.git
cd math-challenge-flutter
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

# 📦 Android Builds

## Debug APK

```bash
flutter build apk --debug
```

Output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

---

## Release APK

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## Google Play AAB

```bash
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

---

# 🔐 Release Signing

Google Play updates must use the existing application upload key associated with:

```text
com.mohamedk.mathchallenge
```

Do **not** commit keystores, passwords, or `key.properties` files.

Example local configuration:

```properties
storePassword=*****
keyPassword=*****
keyAlias=mathchallenge
storeFile=C:/path/to/mathchallenge.keystore
```

Signing files and keystores should remain outside version control.

---

# 📺 AdMob

Math Challenge integrates Google Mobile Ads for:

* banner ads
* interstitial ads
* rewarded ads

Development builds can use Google's official test ad units.

Test-ad behavior can be explicitly enabled with:

```bash
flutter run --dart-define=ADMOB_USE_TEST_ADS=true
```

Production ad IDs may also be overridden at build time:

```bash
flutter build appbundle --release \
  --dart-define=ADMOB_USE_TEST_ADS=false \
  --dart-define=ADMOB_BANNER_ID=YOUR_BANNER_ID \
  --dart-define=ADMOB_INTERSTITIAL_ID=YOUR_INTERSTITIAL_ID \
  --dart-define=ADMOB_REWARDED_ID=YOUR_REWARDED_ID
```

Production builds should never intentionally ship using Google's test ad units.

---

# 💳 In-App Purchases

The application integrates Google Play Billing through Flutter's `in_app_purchase` package.

Purchase availability is connected to the application's family eligibility rules.

Purchase and restore flows are kept separate from core gameplay so the mathematics experience does not depend on billing availability.

---

# 🛠️ Main Technologies

* **Flutter**
* **Dart**
* **Provider / ChangeNotifier**
* **SharedPreferences**
* **Google Mobile Ads**
* **Google Play Billing**
* **Google Play Games Services**
* **Google Play Saved Games**
* **Audioplayers**
* **Vibration**
* **Flutter integration testing**
* **Golden / visual regression testing**
* **GitHub Actions**

---

# 🎯 Project Direction

Math Challenge is evolving beyond a simple arithmetic quiz into a broader educational mathematics game.

Current development focuses on:

* engaging mathematics practice
* adaptive learning
* meaningful skill progression
* structured educational quests
* accessibility
* family-friendly design
* reliable Android performance
* cross-device progression
* controller / keyboard-friendly interaction
* strong automated regression protection

The guiding principle is simple:

> **Make mathematics practice feel like a game without losing the educational value.**

---

# 👨‍🏫 Creator

**Mohamed Khairy**
Mathematics Supervisor

Math Challenge was designed from an educator's perspective with the goal of combining mathematics practice, progression, challenge, and game mechanics in a format students actually want to play.

---

# 📄 License

Personal / educational use.

The original Math Challenge game's licensing terms apply to the underlying game design and content.

The Flutter application is provided as-is for the original author's use.
