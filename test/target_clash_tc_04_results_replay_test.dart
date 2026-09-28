import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_result_summary.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TargetClashRunConfig config(Difficulty difficulty) =>
      TargetClashRunConfig.tryCreate(
        operation: Operation.addition,
        difficulty: difficulty,
        numberType: NumberType.integers,
      )!;

  Future<GameState> makeState({
    QuestionGenerator? generator,
    Random? random,
    AdMobService? adService,
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
      questionGenerator: generator ?? _TargetClashQuestionGenerator(),
      runRandom: random,
      adService: adService,
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  void answer(GameState state, {bool correct = true}) {
    final question = state.targetClashQuestion!;
    state.onTargetClashAnswer(
      correct
          ? question.correctAnswer
          : PresentationAnswer.values.firstWhere(
              (answer) => answer != question.correctAnswer,
            ),
    );
  }

  void resolve(GameState state, {bool correct = true}) {
    answer(state, correct: correct);
    state.debugCompleteTargetClashRevealForTest();
  }

  void complete(GameState state) {
    while (state.rt.gameActive) {
      resolve(state);
    }
  }

  test('each genuine profile freezes canonical facts only after final reveal',
      () async {
    for (final difficulty in Difficulty.values.take(3)) {
      final state = await makeState();
      final before = (
        games: state.gamesPlayed,
        cloud: state.cloudDirty,
        coins: state.coins,
        highScores: List.of(state.highScores),
        achievements: Map.of(state.achievements),
        skills: Map.of(state.skillMap),
        ads: state.adGameCount,
      );
      state.debugStartTargetClashForTest(config(difficulty));
      expect(state.targetClashResultSummary, isNull);
      expect(
        () => TargetClashResultSummary.fromFinishedRuntime(
          state.targetClashRuntime!,
        ),
        throwsArgumentError,
      );

      while (!state.targetClashRuntime!.finished) {
        answer(state);
        if (state.targetClashRuntime!.finished) {
          expect(state.targetClashReveal, isNotNull);
          expect(state.targetClashResultSummary, isNull);
        }
        state.debugCompleteTargetClashRevealForTest();
      }

      final runtime = state.targetClashRuntime!;
      final summary = state.targetClashResultSummary!;
      expect(summary.score, runtime.score);
      expect(summary.correct, runtime.correctCount);
      expect(summary.resolved, runtime.resolvedCount);
      expect(summary.bestCombo, runtime.bestCombo);
      expect(summary.perfectHits, runtime.perfectHits);
      expect(summary.bossesDefeated, runtime.bossesDefeated);
      expect(summary.finalTargetCompleted, runtime.finalTargetCompleted);
      expect(summary.finalTargetCleared, runtime.finalTargetCleared);
      expect(summary.tripleClashesCompleted, runtime.tripleClashesCompleted);
      expect(summary.accuracyPercent, summary.correct * 100 / summary.resolved);
      expect(state.gamesPlayed, before.games);
      expect(state.cloudDirty, before.cloud);
      expect(state.coins, before.coins);
      expect(state.highScores, before.highScores);
      expect(state.achievements, before.achievements);
      expect(state.skillMap, before.skills);
      expect(state.adGameCount, before.ads + 1);
    }
  });

  test('wrong and timeout Final targets retain canonical completion facts',
      () async {
    for (final timeout in [false, true]) {
      final state = await makeState();
      state.debugStartTargetClashForTest(config(Difficulty.easy));
      while (state.targetClashRuntime!.phase != TargetClashPhase.finalTarget) {
        resolve(state);
      }
      if (timeout) {
        state.debugTimeoutForTest();
      } else {
        answer(state, correct: false);
      }
      state.debugCompleteTargetClashRevealForTest();
      resolve(state, correct: false);
      answer(state);
      expect(state.targetClashRuntime!.finished, isTrue);
      expect(state.targetClashResultSummary, isNull);
      state.debugCompleteTargetClashRevealForTest();

      final summary = state.targetClashResultSummary!;
      expect(summary.finalTargetCompleted, isTrue);
      expect(summary.finalTargetCleared, isFalse);
      expect(summary.resolved, state.targetClashRuntime!.resolvedCount);
    }
  });

  test('technical failure never creates a successful summary', () async {
    final state = await makeState(generator: _InitialFailureGenerator());
    state.debugStartTargetClashForTest(config(Difficulty.easy));

    expect(state.targetClashRuntime!.phase, TargetClashPhase.technicalFailure);
    expect(state.targetClashResultSummary, isNull);
    expect(state.adGameCount, 0);
    expect(state.hasSuccessfulTargetClashResultDismissal, isFalse);
  });

  test('successful replay keeps config and replaces Target Clash runtime',
      () async {
    final state = await makeState();
    final run = config(Difficulty.medium);
    state.debugStartTargetClashForTest(run);
    for (var i = 0; i < 6; i++) {
      resolve(state);
    }
    expect(state.targetClashRuntime!.phase, TargetClashPhase.triple);
    complete(state);
    final runtime = state.targetClashRuntime!;
    final ads = state.adGameCount;

    expect(state.hasSuccessfulTargetClashResultDismissal, isTrue);
    await state.replayGame();

    expect(state.activeRunSnapshot!.targetClashConfig, same(run));
    expect(state.targetClashRuntime, isNot(same(runtime)));
    expect(state.targetClashRuntime!.phase, TargetClashPhase.ordinaryStage1);
    expect(state.targetClashResultSummary, isNull);
    expect(state.adGameCount, ads);
  });

  test('replay reaches Triple through a fresh canonical RNG selection',
      () async {
    final random = _FixedRandom();
    final state = await makeState(random: random);
    state.debugStartTargetClashForTest(config(Difficulty.medium));
    for (var i = 0; i < 6; i++) {
      resolve(state);
    }
    expect(random.calls, 1);
    complete(state);
    await state.replayGame();
    for (var i = 0; i < 6; i++) {
      resolve(state);
    }
    expect(random.calls, 2);
  });

  test('blocking interstitial delays replay and menu result dismissal',
      () async {
    for (final menu in [false, true]) {
      final started = Completer<void>();
      final dismissed = Completer<bool>();
      final ads = _BlockingAdMobService()
        ..onShow = () async {
          started.complete();
          return dismissed.future;
        };
      final state = await makeState(adService: ads);
      state.adGameCount = 2;
      state.debugStartTargetClashForTest(config(Difficulty.easy));
      complete(state);
      await Future<void>.delayed(Duration.zero);
      final runtime = state.targetClashRuntime;
      var done = false;
      final action = (menu ? state.quitToMenu() : state.replayGame())
          .whenComplete(() => done = true);
      await started.future;
      expect(state.targetClashResultSummary, isNotNull);
      expect(state.targetClashRuntime, same(runtime));
      expect(done, isFalse);
      expect(ads.interstitialShows, 1);
      expect(state.adGameCount, 3);

      dismissed.complete(true);
      await action;
      expect(state.targetClashResultSummary, isNull);
      expect(state.adGameCount, 3);
      if (menu) {
        expect(state.currentScreen, GameScreen.menu);
      } else {
        expect(state.targetClashRuntime, isNot(same(runtime)));
      }
    }
  });

  test('ineligible success and technical menu do not show an interstitial',
      () async {
    final successAds = _BlockingAdMobService();
    final success = await makeState(adService: successAds);
    success.debugStartTargetClashForTest(config(Difficulty.easy));
    complete(success);
    await Future<void>.delayed(Duration.zero);
    final successCount = success.adGameCount;
    await success.replayGame();
    expect(successAds.interstitialShows, 0);
    expect(success.adGameCount, successCount);

    final menuAds = _BlockingAdMobService();
    final menu = await makeState(adService: menuAds);
    menu.debugStartTargetClashForTest(config(Difficulty.easy));
    complete(menu);
    await Future<void>.delayed(Duration.zero);
    final menuCount = menu.adGameCount;
    await menu.quitToMenu();
    expect(menu.currentScreen, GameScreen.menu);
    expect(menu.targetClashResultSummary, isNull);
    expect(menuAds.interstitialShows, 0);
    expect(menu.adGameCount, menuCount);

    final technicalAds = _BlockingAdMobService();
    final technical = await makeState(
      generator: _InitialFailureGenerator(),
      adService: technicalAds,
    );
    technical.debugStartTargetClashForTest(config(Difficulty.easy));
    await technical.quitToMenu();
    expect(technicalAds.interstitialShows, 0);
    expect(technical.adGameCount, 0);
  });

  test(
      'starts and menu cleanup clear history without mutating a captured value',
      () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    complete(state);
    final summary = state.targetClashResultSummary!;
    final score = summary.score;

    state.debugStartGameFromSnapshot(GameRunSnapshot(
      runType: GameRunType.normal,
      mode: GameMode.standard,
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      answerStyle: AnswerStyle.choice4,
      players: 1,
      questionTarget: 1,
    ));
    expect(state.targetClashResultSummary, isNull);
    expect(summary.score, score);

    state.debugStartTargetClashForTest(config(Difficulty.easy));
    complete(state);
    state.debugStartGameFromSnapshot(const GameRunSnapshot(
      runType: GameRunType.targetClash,
      mode: GameMode.standard,
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.integers,
      answerStyle: AnswerStyle.choice4,
      players: 1,
      questionTarget: 12,
    ));
    expect(state.targetClashResultSummary, isNull);

    state.debugStartTargetClashForTest(config(Difficulty.easy));
    complete(state);
    await state.quitToMenu();
    expect(state.targetClashResultSummary, isNull);
  });
}

final class _InitialFailureGenerator extends QuestionGenerator {
  _InitialFailureGenerator() : super(rng: Random(1));

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

final class _TargetClashQuestionGenerator extends QuestionGenerator {
  _TargetClashQuestionGenerator() : super(rng: Random(1));

  int _anchors = 0;

  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) =>
      _question(type, diff, numType, 10 + ++_anchors);

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
  ) =>
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
  int interstitialShows = 0;

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
    interstitialShows++;
    return onShow?.call() ?? Future.value(false);
  }
}

final class _FixedRandom implements Random {
  int calls = 0;

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) {
    expect(max, 6);
    calls++;
    return 0;
  }
}
