import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
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

const _root = ValueKey('target-clash-v5-capture-root');

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

  TargetClashRunConfig config([Difficulty difficulty = Difficulty.easy]) =>
      TargetClashRunConfig.tryCreate(
        operation: Operation.addition,
        difficulty: difficulty,
        numberType: NumberType.integers,
      )!;

  Future<GameState> state({bool dark = false}) async {
    SharedPreferences.setMockInitialValues({'mc_dark': dark});
    await Storage.init();
    final result = GameState(
      settings: SettingsService()
        ..load(
          dark: dark,
          sound: false,
          vibration: false,
          dyslexia: false,
          colorblind: false,
          lowPerf: true,
          reduceMotion: true,
          animSpeed: 1,
        ),
      audio: _NoOpAudioService(),
      questionGenerator: _Generator(),
    );
    await result.load();
    addTearDown(result.dispose);
    return result;
  }

  Widget host(GameState state) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: state.settings),
          ChangeNotifierProvider<GameState>.value(value: state),
        ],
        child: RepaintBoundary(
          key: _root,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('en'),
            theme: AppTheme.light(state.settings),
            darkTheme: AppTheme.dark(state.settings),
            themeMode: state.settings.dark ? ThemeMode.dark : ThemeMode.light,
            home: const Scaffold(body: screen.GameScreen()),
          ),
        ),
      );

  void viewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name pump:before');
    await tester.pump();
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name pump:after');
    expect(tester.takeException(), isNull);
    final output = Platform.environment['TC_V5_CAPTURE_DIR'];
    expect(output, isNotNull,
        reason: 'The disposable CI capture directory must be supplied.');
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_root));
    final result = await tester.runAsync(() async {
      ui.Image? image;
      try {
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name toImage:before');
        image = await boundary.toImage(pixelRatio: 1.0);
        // ignore: avoid_print
        print(
            'TC_V5_CAPTURE $name toImage:after ${image.width}x${image.height}');
        if (image.width != 390 || image.height != 844) {
          throw StateError(
              'Expected 390x844, got ${image.width}x${image.height}.');
        }
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name toByteData:before');
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name toByteData:after');
        if (bytes == null) {
          throw StateError('PNG encoding returned no bytes.');
        }
        final png = List<int>.of(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final file = File('$output/$name');
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name file-create:before');
        await file.parent.create(recursive: true);
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name file-create:after');
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name file-write:before');
        await file.writeAsBytes(png, flush: true);
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name file-write:after');
        if (!await file.exists()) {
          throw StateError('Capture file was not written: ${file.path}');
        }
        return (width: image.width, height: image.height);
      } finally {
        image?.dispose();
        // ignore: avoid_print
        print('TC_V5_CAPTURE $name image-dispose:after');
      }
    });
    expect(result, isNotNull);
    // This is retained in the CI test log beside the artifact name.
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name complete ${result!.width}x${result.height}');
    expect(tester.takeException(), isNull);
  }

  void resolve(GameState state) {
    state.onTargetClashAnswer(state.targetClashQuestion!.correctAnswer);
    state.debugCompleteTargetClashRevealForTest();
  }

  Future<void> capturePhase(
    WidgetTester tester,
    String name, {
    required Difficulty difficulty,
    required int resolves,
    required TargetClashPhase expectedPhase,
    required bool expectedFever,
    bool dark = false,
  }) async {
    final current = await state(dark: dark);
    current.debugStartTargetClashForTest(config(difficulty));
    for (var i = 0; i < resolves; i++) {
      resolve(current);
    }
    expect(current.targetClashRuntime!.phase, expectedPhase);
    expect(current.targetClashRuntime!.isFeverActive, expectedFever);
    viewport(tester);
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name pumpWidget:before');
    await tester.pumpWidget(host(current));
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name pumpWidget:after');
    await capture(tester, name);
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name phase-cleanup:before');
    await current.quitToMenu();
    // ignore: avoid_print
    print('TC_V5_CAPTURE $name phase-cleanup:after');
  }

  testWidgets('captures ordinary light 390x844', (tester) async {
    await capturePhase(
      tester,
      'ordinary_light_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 0,
      expectedPhase: TargetClashPhase.ordinaryStage1,
      expectedFever: false,
    );
  });

  testWidgets('captures triple clash light 390x844', (tester) async {
    await capturePhase(
      tester,
      'triple_light_390x844.png',
      difficulty: Difficulty.medium,
      resolves: 6,
      expectedPhase: TargetClashPhase.triple,
      expectedFever: false,
    );
  });

  testWidgets('captures fever light 390x844', (tester) async {
    await capturePhase(
      tester,
      'fever_light_390x844.png',
      difficulty: Difficulty.hard,
      resolves: 9,
      expectedPhase: TargetClashPhase.boss,
      expectedFever: true,
    );
  });

  testWidgets('captures boss light 390x844', (tester) async {
    await capturePhase(
      tester,
      'boss_light_390x844.png',
      difficulty: Difficulty.medium,
      resolves: 9,
      expectedPhase: TargetClashPhase.boss,
      expectedFever: false,
    );
  });

  testWidgets('captures final target light 390x844', (tester) async {
    await capturePhase(
      tester,
      'final_target_light_390x844.png',
      difficulty: Difficulty.easy,
      resolves: 9,
      expectedPhase: TargetClashPhase.finalTarget,
      expectedFever: false,
    );
  });

  testWidgets('captures boss dark 390x844', (tester) async {
    await capturePhase(
      tester,
      'boss_dark_390x844.png',
      difficulty: Difficulty.medium,
      resolves: 9,
      expectedPhase: TargetClashPhase.boss,
      expectedFever: false,
      dark: true,
    );
  });

  testWidgets('captures fever dark 390x844', (tester) async {
    await capturePhase(
      tester,
      'fever_dark_390x844.png',
      difficulty: Difficulty.hard,
      resolves: 9,
      expectedPhase: TargetClashPhase.boss,
      expectedFever: true,
      dark: true,
    );
  });
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
      _question(type, diff, numType, 10 + ++_anchor);

  @override
  Question? buildDirectForResult({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    required num result,
  }) =>
      _question(type, diff, numType, result);

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
