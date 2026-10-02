@Tags(<String>['golden'])
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/screens/game_screen.dart' as screen;
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _goldenRoot = ValueKey('tc05d-golden-root');

Future<void> _loadFonts() async {
  final baloo = FontLoader('Baloo2')
    ..addFont(rootBundle.load('assets/fonts/Baloo2-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Baloo2-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Baloo2-Black.ttf'));
  await baloo.load();

  final jakarta = FontLoader('PlusJakartaSans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-ExtraBold.ttf'));
  await jakarta.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  TargetClashRunConfig config([
    Difficulty difficulty = Difficulty.easy,
  ]) =>
      TargetClashRunConfig.tryCreate(
        operation: Operation.addition,
        difficulty: difficulty,
        numberType: NumberType.integers,
      )!;

  Future<GameState> makeState({
    bool dark = false,
    QuestionGenerator? generator,
  }) async {
    SharedPreferences.setMockInitialValues({
      'mc_dark': dark,
    });

    await Storage.init();

    final settings = SettingsService()
      ..load(
        dark: dark,
        sound: false,
        vibration: false,
        dyslexia: false,
        colorblind: false,
        lowPerf: true,
        reduceMotion: true,
        animSpeed: 1,
      );

    final state = GameState(
      settings: settings,
      audio: _NoOpAudioService(),
      questionGenerator: generator ?? _Generator(),
    );

    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  Widget host(GameState state) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(
            value: state.settings,
          ),
          ChangeNotifierProvider<GameState>.value(
            value: state,
          ),
        ],
        child: Consumer<SettingsService>(
          builder: (context, settings, _) => RepaintBoundary(
            key: _goldenRoot,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('en'),
              supportedLocales: const [
                Locale('en'),
              ],
              theme: AppTheme.light(settings),
              darkTheme: AppTheme.dark(settings),
              themeMode: settings.dark ? ThemeMode.dark : ThemeMode.light,
              home: const Scaffold(
                body: screen.GameScreen(),
              ),
            ),
          ),
        ),
      );

  void setViewport(
    WidgetTester tester,
    Size logicalSize, {
    double textScale = 1.0,
  }) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = logicalSize;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );
  }

  Future<void> capture(
    WidgetTester tester,
    String path,
  ) async {
    await tester.pump();

    expect(
      tester.takeException(),
      isNull,
    );

    await expectLater(
      find.byKey(_goldenRoot),
      matchesGoldenFile(path),
    );

    expect(
      tester.takeException(),
      isNull,
    );
  }

  void resolveAndOpen(GameState state) {
    state.onTargetClashAnswer(
      state.targetClashQuestion!.correctAnswer,
    );
    state.debugCompleteTargetClashRevealForTest();
  }

  void chargePowerShot(GameState state) {
    for (var i = 0; i < 5; i++) {
      resolveAndOpen(state);
    }
  }

  void completeTargetClash(GameState state) {
    while (state.rt.gameActive) {
      resolveAndOpen(state);
    }
  }

  testWidgets(
    'TC-05D 01 ordinary gameplay open light phone',
    (tester) async {
      final state = await makeState();
      state.debugStartTargetClashForTest(config());

      setViewport(
        tester,
        const Size(390, 844),
      );

      await tester.pumpWidget(host(state));

      expect(
        find.byKey(const Key('target-clash-gameplay')),
        findsOneWidget,
      );

      await capture(
        tester,
        'goldens/target_clash/tc05d_01_gameplay_open_light_390x844.png',
      );

      await state.quitToMenu();
      await tester.pump();
    },
  );

  testWidgets(
    'TC-05D 02 clash reveal light phone',
    (tester) async {
      final state = await makeState();
      state.debugStartTargetClashForTest(config());

      state.onTargetClashAnswer(
        state.targetClashQuestion!.correctAnswer,
      );

      setViewport(
        tester,
        const Size(390, 844),
      );

      await tester.pumpWidget(host(state));

      expect(
        find.byKey(const Key('target-clash-reveal-relation')),
        findsOneWidget,
      );

      await capture(
        tester,
        'goldens/target_clash/tc05d_02_clash_reveal_light_390x844.png',
      );

      await state.quitToMenu();
      await tester.pump();
    },
  );

  testWidgets(
    'TC-05D 03 gameplay open dark phone',
    (tester) async {
      final state = await makeState(dark: true);
      state.debugStartTargetClashForTest(config());

      setViewport(
        tester,
        const Size(390, 844),
      );

      await tester.pumpWidget(host(state));

      expect(
        state.settings.dark,
        isTrue,
      );

      await capture(
        tester,
        'goldens/target_clash/tc05d_03_gameplay_open_dark_390x844.png',
      );

      await state.quitToMenu();
      await tester.pump();
    },
  );

  testWidgets(
    'TC-05D 04 power shot ready reveal',
    (tester) async {
      final state = await makeState();
      state.debugStartTargetClashForTest(config());

      chargePowerShot(state);

      state.onTargetClashAnswer(
        state.targetClashQuestion!.correctAnswer,
      );

      setViewport(
        tester,
        const Size(390, 844),
      );

      await tester.pumpWidget(host(state));

      expect(
        find.text('POWER SHOT READY'),
        findsOneWidget,
      );

      await capture(
        tester,
        'goldens/target_clash/tc05d_04_power_shot_ready_390x844.png',
      );

      await state.quitToMenu();
      await tester.pump();
    },
  );

  testWidgets(
    'TC-05D 05 triple blocks ready power shot',
    (tester) async {
      final state = await makeState();
      state.debugStartTargetClashForTest(
        config(Difficulty.medium),
      );

      chargePowerShot(state);

      state.onTargetClashAnswer(
        state.targetClashQuestion!.correctAnswer,
      );

      setViewport(
        tester,
        const Size(390, 844),
      );

      await tester.pumpWidget(host(state));

      expect(
        state.targetClashRuntime!.isTriple,
        isTrue,
      );

      expect(
        find.text('POWER SHOT BLOCKED IN TRIPLE'),
        findsOneWidget,
      );

      await capture(
        tester,
        'goldens/target_clash/tc05d_05_triple_power_shot_blocked_390x844.png',
      );

      await state.quitToMenu();
      await tester.pump();
    },
  );

  testWidgets(
    'TC-05D 06 results light phone',
    (tester) async {
      final state = await makeState();
      state.debugStartTargetClashForTest(config());
      completeTargetClash(state);

      setViewport(
        tester,
        const Size(390, 844),
      );

      await tester.pumpWidget(host(state));

      expect(
        find.byKey(const Key('target-clash-results')),
        findsOneWidget,
      );

      await capture(
        tester,
        'goldens/target_clash/tc05d_06_results_light_390x844.png',
      );

      await state.quitToMenu();
      await tester.pump();
    },
  );

  testWidgets(
    'TC-05D 07 results dark phone',
    (tester) async {
      final state = await makeState(dark: true);
      state.debugStartTargetClashForTest(config());
      completeTargetClash(state);

      setViewport(
        tester,
        const Size(390, 844),
      );

      await tester.pumpWidget(host(state));

      expect(
        state.settings.dark,
        isTrue,
      );

      await capture(
        tester,
        'goldens/target_clash/tc05d_07_results_dark_390x844.png',
      );

      await state.quitToMenu();
      await tester.pump();
    },
  );

  testWidgets(
    'TC-05D 08 results landscape',
    (tester) async {
      final state = await makeState();
      state.debugStartTargetClashForTest(config());
      completeTargetClash(state);

      setViewport(
        tester,
        const Size(844, 390),
      );

      await tester.pumpWidget(host(state));

      expect(
        find.byKey(const Key('target-clash-results')),
        findsOneWidget,
      );

      await capture(
        tester,
        'goldens/target_clash/tc05d_08_results_landscape_844x390.png',
      );

      await state.quitToMenu();
      await tester.pump();
    },
  );

  testWidgets(
    'TC-05D 09 technical failure phone',
    (tester) async {
      final state = await makeState(
        generator: _FailGenerator(),
      );

      state.debugStartTargetClashForTest(config());

      setViewport(
        tester,
        const Size(390, 844),
      );

      await tester.pumpWidget(host(state));

      expect(
        find.byKey(const Key('target-clash-technical-failure')),
        findsOneWidget,
      );

      await capture(
        tester,
        'goldens/target_clash/tc05d_09_technical_failure_390x844.png',
      );

      await state.quitToMenu();
      await tester.pump();
    },
  );

  testWidgets(
    'TC-05D 10 ordinary gameplay tablet boundary',
    (tester) async {
      final state = await makeState();
      state.debugStartTargetClashForTest(config());

      setViewport(
        tester,
        const Size(834, 1194),
      );

      await tester.pumpWidget(host(state));

      expect(
        find.byKey(const Key('target-clash-gameplay')),
        findsOneWidget,
      );

      await capture(
        tester,
        'goldens/target_clash/tc05d_10_gameplay_tablet_834x1194.png',
      );

      await state.quitToMenu();
      await tester.pump();
    },
  );
}

final class _Generator extends QuestionGenerator {
  _Generator() : super(rng: Random(1));

  int _anchor = 0;

  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) =>
      _question(
        type,
        diff,
        numType,
        10 + ++_anchor,
      );

  @override
  Question? buildDirectForResult({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    required num result,
  }) =>
      _question(
        type,
        diff,
        numType,
        result,
      );

  Question _question(
    Operation type,
    Difficulty diff,
    NumberType numType,
    num result,
  ) {
    final fact = MathFact(
      operation: type,
      left: result,
      right: 0,
      result: result,
      representation: FactRepresentation.direct,
      difficulty: diff,
      numberType: numType,
    );

    return Question(
      type: type,
      key: '$type:$result',
      text: '$result + 0',
      ans: result,
      choices: [result],
      diff: diff,
      numType: numType,
      fact: fact,
    );
  }
}

final class _FailGenerator extends QuestionGenerator {
  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) =>
      Question(
        type: type,
        key: 'invalid',
        text: 'invalid',
        ans: 0,
        choices: const [0],
      );
}

final class _NoOpAudioService implements AudioService {
  @override
  int get debugTonePlayCount => 0;

  @override
  int get debugVibrationCount => 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> playCorrect() async {}

  @override
  Future<void> playPowerUp() async {}

  @override
  Future<void> playStart() async {}

  @override
  Future<void> playTones(List<List<double>> tones) async {}

  @override
  Future<void> playWrong() async {}

  @override
  void vibrate(int ms) {}

  @override
  void vibrateCorrect() {}

  @override
  void vibratePattern(List<int> pattern) {}

  @override
  void vibratePowerUp() {}

  @override
  void vibrateWrong() {}
}
