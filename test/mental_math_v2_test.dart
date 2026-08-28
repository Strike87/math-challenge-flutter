import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/gameplay/domain/question_mechanic.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameState> makeState() async {
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
      questionGenerator: QuestionGenerator(rng: Random(2002)),
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  GameRunSnapshot snapshot({
    Operation operation = Operation.addition,
    QuestionMechanic mechanic = QuestionMechanic.standard,
  }) =>
      GameRunSnapshot(
        runType: GameRunType.normal,
        mode: GameMode.standard,
        operation: operation,
        difficulty: Difficulty.medium,
        numberType: NumberType.natural,
        answerStyle: AnswerStyle.choice4,
        players: 1,
        questionTarget: 40,
        questionMechanic: mechanic,
        mentalMathEntry: MentalMathEntry.freePractice,
      );

  Future<void> advance(WidgetTester tester, GameState state) async {
    await tester.pump(const Duration(milliseconds: 1301));
    state.rt.timer?.cancel();
  }

  testWidgets('Number Type starts one cancellable Mental Math countdown',
      (tester) async {
    final state = await makeState();
    state.goToPracticeStyle('addition');
    state.startMentalMathFreePractice();
    await state.selectNumType(NumberType.natural.name);

    expect(state.currentScreen, GameScreen.game);
    expect(state.isMentalMathCountdown, isTrue);
    expect(state.mentalMathCountdownLabel, '3');
    expect(state.rt.q, isNull);
    expect(state.rt.timer, isNull);
    expect((
      state.rt.momentum,
      state.rt.currentStreak,
      state.rt.completedQuestions
    ), (
      0,
      0,
      0
    ));

    await tester.pump(const Duration(seconds: 1));
    expect(state.mentalMathCountdownLabel, '2');
    state.handleAppLifecycleChange(resumed: false);
    await tester.pump(const Duration(seconds: 2));
    expect(state.mentalMathCountdownLabel, '2');
    expect(state.rt.q, isNull);

    state.handleAppLifecycleChange(resumed: true);
    state.handleAppLifecycleChange(resumed: true);
    await tester.pump(const Duration(seconds: 1));
    expect(state.mentalMathCountdownLabel, '1');
    await tester.pump(const Duration(seconds: 1));
    expect(state.mentalMathCountdownLabel, 'GO!');
    await tester.pump(const Duration(seconds: 1));
    expect(state.isMentalMathGameplay, isTrue);
    expect(state.rt.q, isNotNull);
    expect(state.debugQuestionTimerDurationMs(), 10000);
    state.rt.timer?.cancel();

    await state.replayGame();
    expect(state.isMentalMathCountdown, isTrue);
    expect(state.mentalMathCountdownLabel, '3');
    await state.quitToMenu();
    await tester.pump(const Duration(seconds: 5));
    expect(state.activeRunSnapshot, isNull);
    expect(state.rt.q, isNull);
    expect(state.rt.timer, isNull);
  });

  testWidgets('tracks each canonical outcome once without warm-up',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot());
    state.rt.timer?.cancel();

    expect(state.rt.isWarmUp, isFalse);
    expect(
      (
        state.rt.momentum,
        state.rt.peakMomentum,
        state.rt.currentStreak,
        state.rt.bestStreak,
        state.rt.completedQuestions,
        state.rt.terminalReason,
      ),
      (0, 0, 0, 0, 0, null),
    );
    expect(state.rt.q!.diff, Difficulty.medium);

    state.onAnswer(state.rt.q!.ans);
    expect((
      state.rt.momentum,
      state.rt.currentStreak,
      state.rt.completedQuestions
    ), (
      1,
      1,
      1
    ));
    state.onAnswer(state.rt.q!.ans);
    expect(state.rt.completedQuestions, 1);

    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    expect((
      state.rt.momentum,
      state.rt.peakMomentum,
      state.rt.currentStreak,
      state.rt.bestStreak
    ), (
      2,
      2,
      2,
      2
    ));

    await advance(tester, state);
    final wrong = state.rt.q!.choices.firstWhere((v) => v != state.rt.q!.ans);
    state.onAnswer(wrong);
    expect((
      state.rt.momentum,
      state.rt.currentStreak,
      state.rt.completedQuestions
    ), (
      1,
      0,
      3
    ));

    await advance(tester, state);
    state.debugTimeoutForTest();
    expect((
      state.rt.momentum,
      state.rt.currentStreak,
      state.rt.completedQuestions
    ), (
      0,
      0,
      4
    ));
    await advance(tester, state);
  });

  testWidgets('uses fixed zones without Adaptive and preserves run context',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(
      snapshot(
        operation: Operation.multiplication,
        mechanic: QuestionMechanic.missingOperation,
      ),
    );
    state.rt.timer?.cancel();

    for (final zone in const [
      (momentum: -4, difficulty: Difficulty.easy),
      (momentum: -3, difficulty: Difficulty.medium),
      (momentum: 3, difficulty: Difficulty.medium),
      (momentum: 4, difficulty: Difficulty.hard),
      (momentum: 9, difficulty: Difficulty.hard),
    ]) {
      state.rt.momentum = zone.momentum - 1;
      state.onAnswer(state.rt.q!.ans);
      await advance(tester, state);
      expect(state.rt.q!.diff, zone.difficulty);
      expect(state.rt.q!.type, Operation.multiplication);
      expect(state.activeRunSnapshot!.numberType, NumberType.natural);
      expect(state.activeRunSnapshot!.questionMechanic,
          QuestionMechanic.missingOperation);
      expect(state.activeAdaptive, isFalse);
    }
  });

  testWidgets('uses the Mental Math millisecond timer budget and clamps it',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot());

    expect(state.rt.nextQuestionTimerBudgetMs, 10000);
    expect(state.debugQuestionTimerDurationMs(), 10000);

    state.onAnswer(state.rt.q!.ans);
    expect(state.rt.nextQuestionTimerBudgetMs, 9500);
    await advance(tester, state);
    expect(state.debugQuestionTimerDurationMs(), 9500);

    final wrong = state.rt.q!.choices.firstWhere((v) => v != state.rt.q!.ans);
    state.onAnswer(wrong);
    expect(state.rt.nextQuestionTimerBudgetMs, 10500);
    await advance(tester, state);

    state.debugTimeoutForTest();
    expect(state.rt.nextQuestionTimerBudgetMs, 11500);
    await advance(tester, state);

    state.rt.nextQuestionTimerBudgetMs = 6000;
    state.onAnswer(state.rt.q!.ans);
    expect(state.rt.nextQuestionTimerBudgetMs, 6000);
    await advance(tester, state);

    state.rt.nextQuestionTimerBudgetMs = 12000;
    state.onAnswer(state.rt.q!.choices.firstWhere((v) => v != state.rt.q!.ans));
    expect(state.rt.nextQuestionTimerBudgetMs, 12000);
    await advance(tester, state);
  });

  testWidgets('pauses and resumes the same Mental Math question exactly once',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot());
    final question = state.rt.q;
    state.rt.timerStart = DateTime.now().millisecondsSinceEpoch - 1750;

    state.handleAppLifecycleChange(resumed: false);
    final pausedRemaining = state.rt.timerElapsedAtPause;
    expect(pausedRemaining, inInclusiveRange(8200, 8300));
    expect(state.rt.timer, isNull);

    state.handleAppLifecycleChange(resumed: false);
    await tester.pump(const Duration(seconds: 2));
    expect(state.rt.timerElapsedAtPause, pausedRemaining);
    expect(state.rt.completedQuestions, 0);

    state.handleAppLifecycleChange(resumed: true);
    final resumedTimer = state.rt.timer;
    expect(state.rt.q, same(question));
    expect(state.rt.timerDurationMs, pausedRemaining);
    expect(resumedTimer?.isActive, isTrue);

    state.handleAppLifecycleChange(resumed: true);
    expect(state.rt.timer, same(resumedTimer));
    expect(state.rt.completedQuestions, 0);
    state.rt.timer?.cancel();
  });

  testWidgets('expires once after Mental Math resume', (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot());
    final question = state.rt.q;

    state.handleAppLifecycleChange(resumed: false);
    state.handleAppLifecycleChange(resumed: true);
    expect(state.rt.q, same(question));

    state.rt.timerStart =
        DateTime.now().millisecondsSinceEpoch - state.rt.timerDurationMs;
    await tester.pump(const Duration(milliseconds: 101));

    expect((
      state.rt.momentum,
      state.rt.currentStreak,
      state.rt.completedQuestions,
      state.rt.nextQuestionTimerBudgetMs,
    ), (-1, 0, 1, 11000));

    state
      ..debugTimeoutForTest()
      ..onAnswer(state.rt.q!.ans);
    expect((
      state.rt.momentum,
      state.rt.currentStreak,
      state.rt.completedQuestions,
      state.rt.nextQuestionTimerBudgetMs,
    ), (-1, 0, 1, 11000));
    await advance(tester, state);
  });

  testWidgets('clears Mental Math timer state on Main Menu exit',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot());

    await state.quitToMenu();
    expect((
      state.rt.timer,
      state.rt.timerStart,
      state.rt.timerDurationMs,
      state.rt.timerElapsedAtPause,
      state.rt.nextQuestionTimerBudgetMs,
    ), (null, 0, 0, 0, 10000));
    state.debugTimeoutForTest();
    expect((
      state.rt.momentum,
      state.rt.currentStreak,
      state.rt.completedQuestions,
      state.rt.nextQuestionTimerBudgetMs,
      state.rt.terminalReason,
    ), (0, 0, 0, 10000, null));

    state.debugStartGameFromSnapshot(snapshot());
    state.handleAppLifecycleChange(resumed: false);
    expect(state.rt.timerElapsedAtPause, greaterThan(0));
    await state.quitToMenu();
    expect((
      state.rt.timer,
      state.rt.timerStart,
      state.rt.timerDurationMs,
      state.rt.timerElapsedAtPause,
      state.rt.nextQuestionTimerBudgetMs,
    ), (null, 0, 0, 0, 10000));

    state.debugStartGameFromSnapshot(snapshot());
    expect((
      state.rt.nextQuestionTimerBudgetMs,
      state.debugQuestionTimerDurationMs(),
    ), (10000, 10000));
    state.rt.timer?.cancel();
  });

  testWidgets('terminal ordering, replay, and menu exit reset runtime state',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot());
    state.rt.timer?.cancel();

    state
      ..rt.momentum = 9
      ..rt.completedQuestions = 39;
    state.onAnswer(state.rt.q!.ans);
    expect(state.rt.terminalReason, MentalMathTerminalReason.masteryReached);
    expect(state.rt.state, 'ending');

    await state.replayGame();
    expect(state.isMentalMathCountdown, isTrue);
    await tester.pump(const Duration(seconds: 4));
    state.rt.timer?.cancel();
    expect((
      state.rt.momentum,
      state.rt.peakMomentum,
      state.rt.currentStreak,
      state.rt.bestStreak,
      state.rt.completedQuestions,
      state.rt.terminalReason
    ), (
      0,
      0,
      0,
      0,
      0,
      null
    ));

    state
      ..rt.momentum = -9
      ..rt.completedQuestions = 39;
    state.onAnswer(state.rt.q!.choices.firstWhere((v) => v != state.rt.q!.ans));
    expect(state.rt.terminalReason, MentalMathTerminalReason.practiceComplete);

    await state.replayGame();
    expect(state.isMentalMathCountdown, isTrue);
    await tester.pump(const Duration(seconds: 4));
    state.rt.timer?.cancel();
    state.rt.completedQuestions = 39;
    state.onAnswer(state.rt.q!.ans);
    expect(state.rt.terminalReason, MentalMathTerminalReason.trainingComplete);

    await state.quitToMenu();
    await tester.pump(const Duration(milliseconds: 2500));
    expect(state.activeRunSnapshot, isNull);
    expect((
      state.rt.momentum,
      state.rt.completedQuestions,
      state.rt.terminalReason
    ), (
      0,
      0,
      null
    ));
  });

  testWidgets('freezes Mental Math result metrics after the terminal answer',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot());
    state.rt.timer?.cancel();
    state
      ..rt.momentum = 9
      ..rt.peakMomentum = 9
      ..rt.currentStreak = 4
      ..rt.bestStreak = 4
      ..rt.completedQuestions = 11
      ..rt.qStartTs = DateTime.now().millisecondsSinceEpoch - 2000;
    state.p[1]
      ..correct = 8
      ..total = 11;

    state.onAnswer(state.rt.q!.ans);
    await tester.pump(const Duration(milliseconds: 1301));

    final summary = state.mentalMathResultSummary!;
    expect(summary.terminalTitle, 'MASTERY REACHED');
    expect(summary.peakMomentum, 10);
    expect(summary.bestStreak, 5);
    expect(summary.accuracyPercent, 75);
    expect(summary.averageResponseMs, inInclusiveRange(1900, 2100));
    expect(summary.fastestAnswerMs, inInclusiveRange(1900, 2100));
    expect(MentalMathResultSummary.factsRecovered, 0);

    state.debugTimeoutForTest();
    expect(state.mentalMathResultSummary, same(summary));

    await state.quitToMenu();
    expect(state.mentalMathResultSummary, isNull);
    expect((
      state.rt.mentalMathAnsweredResponseTotalMs,
      state.rt.mentalMathAnsweredResponseCount,
    ), (0, 0));
  });

  testWidgets('records Mental Math answer time once and excludes timeouts',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot());
    state.rt.timer?.cancel();
    state.rt.qStartTs = DateTime.now().millisecondsSinceEpoch - 1000;
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);

    state.rt.qStartTs = DateTime.now().millisecondsSinceEpoch - 3000;
    state.onAnswer(state.rt.q!.choices.firstWhere((v) => v != state.rt.q!.ans));
    await advance(tester, state);

    state.debugTimeoutForTest();
    expect(state.rt.mentalMathAnsweredResponseCount, 2);
    expect(state.rt.mentalMathAnsweredResponseTotalMs,
        inInclusiveRange(3800, 4200));

    state.onAnswer(state.rt.q!.ans);
    expect(state.rt.mentalMathAnsweredResponseCount, 2);
    await advance(tester, state);
  });

  testWidgets('ordinary Timing Practice retains its configured behavior',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(
      GameRunSnapshot(
        runType: GameRunType.normal,
        mode: GameMode.standard,
        operation: Operation.addition,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
        answerStyle: AnswerStyle.choice4,
        players: 1,
        questionTarget: 10,
      ),
    );
    state.rt.timer?.cancel();

    expect(state.rt.completedQuestions, 0);
    expect(state.rt.terminalReason, isNull);
    expect(state.activeRunSnapshot!.difficulty, Difficulty.easy);
  });

  testWidgets('blocks skip, power-ups, and rewards while retaining learning',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot());
    state.rt.timer?.cancel();
    final question = state.rt.q!;
    final coinsBefore = state.coins;
    final gamesBefore = state.gamesPlayed;
    final historyBefore = state.p[1].history.length;
    final masteryBefore = state.skillMap[Operation.addition.name]!.count;

    state.p[1].pups.addAll(PowerUp.values);
    state.skip();
    state.usePowerUp(PowerUp.time);
    expect(state.rt.q, same(question));
    expect(state.rt.completedQuestions, 0);
    expect(state.p[1].pups, orderedEquals(PowerUp.values));
    expect(PowerUp.values.every(state.isPowerUpBlocked), isTrue);

    state.onAnswer(question.ans);
    expect(state.p[1].score, 0);
    expect(state.p[1].bonus, 0);
    expect(state.p[1].pups, orderedEquals(PowerUp.values));
    expect(state.coins, coinsBefore);
    expect(state.p[1].history.length, historyBefore + 1);
    expect(state.skillMap[Operation.addition.name]!.count, masteryBefore + 1);

    state
      ..rt.momentum = 9
      ..rt.completedQuestions = 39;
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await tester.pump(const Duration(milliseconds: 1301));
    expect(state.gamesPlayed, gamesBefore + 1);
    expect(state.highScores, isEmpty);
    expect(state.achievements.values.where((value) => value), isEmpty);
  });
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
  void vibrate(int ms) {}
  @override
  void vibrateCorrect() {}
  @override
  void vibratePattern(List<int> pattern) {}
  @override
  void vibratePowerUp() {}
  @override
  void vibrateWrong() {}
  @override
  Future<void> playWrong() async {}
}
