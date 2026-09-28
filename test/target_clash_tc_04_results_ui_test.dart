import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/screens/game_screen.dart' as screen;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameState> makeState({
    AdMobService? adService,
    QuestionGenerator? generator,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final state = GameState(
      settings: SettingsService()
        ..load(
          dark: false,
          sound: false,
          vibration: false,
          dyslexia: false,
          colorblind: false,
          lowPerf: true,
          reduceMotion: true,
          animSpeed: 1,
        ),
      audio: _NoOpAudioService(),
      questionGenerator: generator ?? _Generator(),
      adService: adService,
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  final config = TargetClashRunConfig.tryCreate(
    operation: Operation.addition,
    difficulty: Difficulty.easy,
    numberType: NumberType.integers,
  )!;

  void complete(GameState state) {
    while (state.rt.gameActive) {
      final question = state.targetClashQuestion!;
      state.onTargetClashAnswer(question.correctAnswer);
      state.debugCompleteTargetClashRevealForTest();
    }
  }

  Widget host(GameState state) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: state.settings),
          ChangeNotifierProvider<GameState>.value(value: state),
        ],
        child: const MaterialApp(home: Scaffold(body: screen.GameScreen())),
      );

  testWidgets('successful results show canonical metrics, config and actions',
      (tester) async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config);
    complete(state);
    final summary = state.targetClashResultSummary!;
    await tester.pumpWidget(host(state));

    for (final text in const [
      'Score',
      'Correct',
      'Accuracy',
      'Best Combo',
      'Perfect Hits',
      'Bosses Defeated',
      'Final Target Completed',
      'Final Target Cleared',
      'Triple Clashes Completed',
      'Operation',
      'Difficulty',
      'Number Type',
      'Question Target',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.byKey(const Key('target-clash-results')), findsOneWidget);
    final correctRow = find.ancestor(
      of: find.text('Correct'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(
        of: correctRow,
        matching: find.text('${summary.correct}'),
      ),
      findsOneWidget,
    );
    expect(
        find.text('${summary.accuracyPercent.round()}%'),
        findsOneWidget);
    expect(
        find.byKey(const Key('target-clash-results-replay')), findsOneWidget);
    expect(find.byKey(const Key('target-clash-results-menu')), findsOneWidget);
    expect(find.text('Hall of Fame'), findsNothing);
    expect(find.text('VIEW RESULTS'), findsNothing);

    final replay = find.byKey(const Key('target-clash-results-replay'));
    await tester.ensureVisible(replay);
    await tester.tap(replay);
    await tester.pump();
    expect(state.targetClashResultSummary, isNull);
    expect(state.targetClashRuntime!.finished, isFalse);
    await state.quitToMenu();
  });

  testWidgets('blocking replay disables both actions exactly once',
      (tester) async {
    final started = Completer<void>();
    final dismissed = Completer<bool>();
    final ads = _BlockingAdMobService()
      ..onShow = () async {
        started.complete();
        return dismissed.future;
      };
    final state = await makeState(adService: ads);
    state.adGameCount = 2;
    state.debugStartTargetClashForTest(config);
    complete(state);
    await tester.pumpWidget(host(state));
    await tester.pump();

    final replay = find.byKey(const Key('target-clash-results-replay'));
    tester.widget<FilledButton>(replay).onPressed!();
    await tester.pump();
    await started.future;
    expect(tester.widget<FilledButton>(replay).onPressed, isNull);
    final menu = find.byKey(const Key('target-clash-results-menu'));
    expect(tester.widget<OutlinedButton>(menu).onPressed, isNull);
    expect(ads.shows, 1);

    dismissed.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(ads.shows, 1);
    await state.quitToMenu();
  });

  testWidgets('GameScreen gates results to successful post-reveal completion',
      (tester) async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config);
    await tester.pumpWidget(host(state));
    expect(find.byKey(const Key('target-clash-results')), findsNothing);
    for (var i = 0; i < 11; i++) {
      final question = state.targetClashQuestion!;
      state.onTargetClashAnswer(question.correctAnswer);
      state.debugCompleteTargetClashRevealForTest();
    }
    state.onTargetClashAnswer(state.targetClashQuestion!.correctAnswer);
    await tester.pump();
    expect(state.targetClashReveal, isNotNull);
    expect(find.byKey(const Key('target-clash-results')), findsNothing);
    state.debugCompleteTargetClashRevealForTest();
    await tester.pump();
    expect(find.byKey(const Key('target-clash-results')), findsOneWidget);
    await state.quitToMenu();
  });

  testWidgets('menu action, technical failure, compact and ordinary routes',
      (tester) async {
    final completed = await makeState();
    completed.debugStartTargetClashForTest(config);
    complete(completed);
    await tester.pumpWidget(host(completed));
    final menu = find.byKey(const Key('target-clash-results-menu'));
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pump();
    expect(completed.currentScreen, GameScreen.menu);

    final technical = await makeState(generator: _FailGenerator());
    technical.debugStartTargetClashForTest(config);
    await tester.pumpWidget(host(technical));
    expect(find.byKey(const Key('target-clash-results')), findsNothing);
    expect(find.byKey(const Key('target-clash-technical-failure')),
        findsOneWidget);
    expect(find.byKey(const Key('target-clash-results-replay')), findsNothing);

    final responsive = await makeState();
    responsive.debugStartTargetClashForTest(config);
    complete(responsive);
    expect(responsive.targetClashResultSummary, isNotNull);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(360, 640), const Size(844, 390)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(host(responsive));
      await tester.pump();
      expect(find.byKey(const Key('target-clash-results')), findsOneWidget);
      expect(
          find.byKey(const Key('target-clash-results-replay')), findsOneWidget);
      expect(
          find.byKey(const Key('target-clash-results-menu')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    final ordinary = await makeState();
    ordinary.debugStartGameFromSnapshot(const GameRunSnapshot(
      runType: GameRunType.normal,
      mode: GameMode.standard,
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      answerStyle: AnswerStyle.choice4,
      players: 1,
      questionTarget: 1,
    ));
    await tester.pumpWidget(host(ordinary));
    await tester.pump();
    expect(find.byKey(const Key('target-clash-results')), findsNothing);
    expect(tester.takeException(), isNull);
    await ordinary.quitToMenu();
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
          Operation type, Difficulty diff, NumberType numType, num result) =>
      Question(
        type: type,
        key: '$type:$result',
        text: '$result + 0',
        ans: result,
        choices: [result],
        diff: diff,
        numType: numType,
        fact: MathFact(
          operation: type,
          left: result,
          right: 0,
          result: result,
          representation: FactRepresentation.direct,
          difficulty: diff,
          numberType: numType,
        ),
      );
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
          choices: const [0]);
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

final class _BlockingAdMobService implements AdMobService {
  Future<bool> Function()? onShow;
  int shows = 0;

  @override
  AdMobRequestPolicy get requestPolicy => AdMobRequestPolicy.familiesSafe;
  @override
  Widget? bannerWidget({bool forceHidden = false}) => null;
  @override
  Future<void> hideBanner() async {}
  @override
  Future<void> initialize() async {}
  @override
  Future<void> showBanner() async {}
  @override
  Future<bool> showRewarded() async => false;
  @override
  Future<bool> showInterstitialIfReady() {
    shows++;
    return onShow!();
  }
}
