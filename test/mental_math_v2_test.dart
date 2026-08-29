import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/gameplay/domain/question_mechanic.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameState> makeState({QuestionGenerator? questionGenerator}) async {
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
      questionGenerator:
          questionGenerator ?? QuestionGenerator(rng: Random(2002)),
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
    ), (
      -1,
      0,
      1,
      11000
    ));

    state
      ..debugTimeoutForTest()
      ..onAnswer(state.rt.q!.ans);
    expect((
      state.rt.momentum,
      state.rt.currentStreak,
      state.rt.completedQuestions,
      state.rt.nextQuestionTimerBudgetMs,
    ), (
      -1,
      0,
      1,
      11000
    ));
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
    ), (
      null,
      0,
      0,
      0,
      10000
    ));
    state.debugTimeoutForTest();
    expect((
      state.rt.momentum,
      state.rt.currentStreak,
      state.rt.completedQuestions,
      state.rt.nextQuestionTimerBudgetMs,
      state.rt.terminalReason,
    ), (
      0,
      0,
      0,
      10000,
      null
    ));

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
    ), (
      null,
      0,
      0,
      0,
      10000
    ));

    state.debugStartGameFromSnapshot(snapshot());
    expect((
      state.rt.nextQuestionTimerBudgetMs,
      state.debugQuestionTimerDurationMs(),
    ), (
      10000,
      10000
    ));
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
    expect(summary.factsRecovered, 0);

    state.debugTimeoutForTest();
    expect(state.mentalMathResultSummary, same(summary));

    await state.quitToMenu();
    expect(state.mentalMathResultSummary, isNull);
    expect((
      state.rt.mentalMathAnsweredResponseTotalMs,
      state.rt.mentalMathAnsweredResponseCount,
    ), (
      0,
      0
    ));
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

  testWidgets('schedules wrong and timeout facts after two normal completions',
      (tester) async {
    for (final timeout in [false, true]) {
      final state = await makeState();
      state.debugStartGameFromSnapshot(
          snapshot(operation: Operation.multiplication));
      state.rt.timer?.cancel();

      if (timeout) {
        state.debugTimeoutForTest();
      } else {
        state.onAnswer(state.rt.q!.choices
            .firstWhere((value) => value != state.rt.q!.ans));
      }
      expect(state.debugMentalMathPendingFactCount, 1);
      await advance(tester, state);
      expect(state.debugCurrentMentalMathQuestionIsTargeted, isFalse);

      state.onAnswer(state.rt.q!.ans);
      await advance(tester, state);
      expect(state.debugCurrentMentalMathQuestionIsTargeted, isFalse);

      state.onAnswer(state.rt.q!.ans);
      await advance(tester, state);
      expect(state.debugCurrentMentalMathQuestionIsTargeted, isTrue);
      expect(state.rt.q!.fact, isNotNull);
      expect(
        state.debugCurrentMentalMathTargetedRepresentationKey,
        contains(state.rt.q!.fact!.representation.name),
      );
    }
  });

  testWidgets('skips the failed source representation for its first follow-up',
      (tester) async {
    final generator = _SourceThenDistinctRelatedQuestionGenerator();
    final state = await makeState(questionGenerator: generator);
    state.debugStartGameFromSnapshot(
        snapshot(operation: Operation.multiplication));
    state.rt.timer?.cancel();
    final sourceFact = state.rt.q!.fact!;

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);

    expect(state.debugCurrentMentalMathQuestionIsTargeted, isTrue);
    expect(generator.relatedBuildCount, 2);
    expect(state.rt.q!.fact!.representation, isNot(sourceFact.representation));
  });

  testWidgets(
      'correct and stale terminals do not alter pending eligibility or enqueue',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(
        snapshot(operation: Operation.multiplication));
    state.rt.timer?.cancel();

    state.onAnswer(state.rt.q!.ans);
    expect(state.debugMentalMathPendingFactCount, 0);
    await advance(tester, state);

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    expect(state.debugMentalMathPendingFactCount, 1);
    state
      ..onAnswer(state.rt.q!.ans)
      ..debugTimeoutForTest();
    expect((state.debugMentalMathPendingFactCount, state.rt.completedQuestions),
        (1, 2));

    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    expect(state.debugCurrentMentalMathQuestionIsTargeted, isTrue);
  });

  testWidgets('targeted recovery resolves once and separates the next question',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(
        snapshot(operation: Operation.multiplication));
    state.rt.timer?.cancel();

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);

    expect(state.debugCurrentMentalMathQuestionIsTargeted, isTrue);
    final recoveredFact = state.rt.q!.fact!;
    expect(state.debugCurrentMentalMathTargetedRepresentationKey, isNotNull);
    state.onAnswer(state.rt.q!.ans);
    expect((state.debugMentalMathPendingFactCount, state.rt.factsRecovered),
        (0, 1));
    expect(state.debugCurrentMentalMathTargetedRepresentationKey, isNull);
    state.onAnswer(state.rt.q!.ans);
    expect(state.rt.factsRecovered, 1);

    await advance(tester, state);
    expect(state.debugCurrentMentalMathQuestionIsTargeted, isFalse);
    state.rt.q = _withFact(state.rt.q!, recoveredFact);
    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    expect((
      state.debugMentalMathPendingFactCount,
      state.debugMentalMathClosedFactCount
    ), (
      0,
      1
    ));
    await advance(tester, state);
  });

  testWidgets('uses a distinct final target and closes it after two attempts',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(
        snapshot(operation: Operation.multiplication));
    state.rt.timer?.cancel();

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    final firstTarget = state.rt.q!.fact!;

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    await advance(tester, state);
    expect(state.debugCurrentMentalMathQuestionIsTargeted, isFalse);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    final finalTarget = state.rt.q!.fact!;
    expect(state.debugCurrentMentalMathQuestionIsTargeted, isTrue);
    expect(
      '${finalTarget.operation}:${finalTarget.left}:${finalTarget.right}:'
      '${finalTarget.result}:${finalTarget.representation}',
      isNot(
        '${firstTarget.operation}:${firstTarget.left}:${firstTarget.right}:'
        '${firstTarget.result}:${firstTarget.representation}',
      ),
    );

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    expect((state.debugMentalMathPendingFactCount, state.rt.factsRecovered),
        (0, 0));
    expect(state.debugMentalMathClosedFactCount, 1);
    await advance(tester, state);
    expect(state.debugCurrentMentalMathQuestionIsTargeted, isFalse);
    state.rt.q = _withFact(state.rt.q!, finalTarget);
    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    expect((
      state.debugMentalMathPendingFactCount,
      state.debugMentalMathClosedFactCount
    ), (
      0,
      1
    ));
    await advance(tester, state);
  });

  testWidgets(
      'keeps at most three pending facts and includes terminal recovery',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(
        snapshot(operation: Operation.multiplication));
    state.rt.timer?.cancel();

    for (var i = 0; i < 3; i++) {
      state.onAnswer(
          state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
      await advance(tester, state);
    }
    expect(state.debugMentalMathPendingFactCount, 3);
    expect(state.debugCurrentMentalMathQuestionIsTargeted, isTrue);

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    await advance(tester, state);
    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    expect(state.debugMentalMathPendingFactCount, 3);

    await state.replayGame();
    await tester.pump(const Duration(seconds: 4));
    state.rt.timer?.cancel();
    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    state.rt.completedQuestions = 3;
    await advance(tester, state);
    expect(state.debugCurrentMentalMathQuestionIsTargeted, isTrue);
    state
      ..rt.momentum = 9
      ..rt.completedQuestions = 39;
    state.onAnswer(state.rt.q!.ans);
    await tester.pump(const Duration(milliseconds: 1301));
    expect(state.mentalMathResultSummary!.factsRecovered, 1);
    expect(state.debugMentalMathPendingFactCount, 0);
  });

  testWidgets('uses normal generation when related generation is unavailable',
      (tester) async {
    final state =
        await makeState(questionGenerator: _NoRelatedQuestionGenerator());
    state.debugStartGameFromSnapshot(
        snapshot(operation: Operation.multiplication));
    state.rt.timer?.cancel();

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);

    expect(state.debugCurrentMentalMathQuestionIsTargeted, isFalse);
    expect((
      state.debugMentalMathPendingFactCount,
      state.debugMentalMathClosedFactCount
    ), (
      0,
      1
    ));
    expect(state.rt.q, isNotNull);
  });

  testWidgets('closes a pending fact after bounded repeated related attempts',
      (tester) async {
    final state =
        await makeState(questionGenerator: _RepeatedRelatedQuestionGenerator());
    state.debugStartGameFromSnapshot(
        snapshot(operation: Operation.multiplication));
    state.rt.timer?.cancel();

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    expect(state.debugCurrentMentalMathQuestionIsTargeted, isTrue);

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);

    expect(state.debugCurrentMentalMathQuestionIsTargeted, isFalse);
    expect((
      state.debugMentalMathPendingFactCount,
      state.debugMentalMathClosedFactCount
    ), (
      0,
      1
    ));
  });

  testWidgets('targeted Missing Operation retains its fact and operator blank',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot(
      operation: Operation.multiplication,
      mechanic: QuestionMechanic.missingOperation,
    ));
    state.rt.timer?.cancel();

    state.onAnswer(
        state.rt.q!.choices.firstWhere((value) => value != state.rt.q!.ans));
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);
    state.onAnswer(state.rt.q!.ans);
    await advance(tester, state);

    final targeted = state.rt.q!;
    expect(state.debugCurrentMentalMathQuestionIsTargeted, isTrue);
    expect(targeted.text, matches(RegExp(r'^-?\d+ \? -?\d+ = -?\d+$')));
    expect(targeted.choices, unorderedEquals(operatorAnswerChoices));
    expect(targeted.fact, isNotNull);
    expect(targeted.fact!.representation, FactRepresentation.direct);
  });

  testWidgets('stops at question forty without generating question forty-one',
      (tester) async {
    final state = await makeState();
    state.debugStartGameFromSnapshot(snapshot());
    state
      ..rt.timer?.cancel()
      ..rt.completedQuestions = 39;
    final questionForty = state.rt.q!;

    state.onAnswer(questionForty.ans);
    expect(state.rt.completedQuestions, 40);
    expect(state.rt.q, same(questionForty));
    await tester.pump(const Duration(seconds: 4));
    expect(state.rt.q, same(questionForty));
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

Question _withFact(Question question, MathFact fact) => Question(
      type: question.type,
      key: question.key,
      text: question.text,
      ans: question.ans,
      choices: question.choices,
      boss: question.boss,
      diff: question.diff,
      numType: question.numType,
      ratDP: question.ratDP,
      fact: fact,
    );

final class _NoRelatedQuestionGenerator extends QuestionGenerator {
  _NoRelatedQuestionGenerator() : super(rng: Random(4100));

  @override
  Question? buildRelated({
    required MathFact fact,
    required Difficulty diff,
    required NumberType numType,
    required Set<Operation> allowedOperations,
    Set<FactRepresentation> excludedRepresentations = const {},
  }) =>
      null;
}

final class _RepeatedRelatedQuestionGenerator extends QuestionGenerator {
  _RepeatedRelatedQuestionGenerator() : super(rng: Random(4200));

  @override
  Question? buildRelated({
    required MathFact fact,
    required Difficulty diff,
    required NumberType numType,
    required Set<Operation> allowedOperations,
    Set<FactRepresentation> excludedRepresentations = const {},
  }) {
    final related = fact.copyWith(
      representation: switch (fact.representation) {
        FactRepresentation.direct => FactRepresentation.missingLeft,
        FactRepresentation.missingLeft => FactRepresentation.missingRight,
        FactRepresentation.missingRight => FactRepresentation.direct,
      },
    );
    return Question(
      type: related.operation,
      key: 'repeated-related',
      text: '? × ${related.right} = ${related.result}',
      ans: related.left,
      choices: [related.left, related.left + 1],
      diff: diff,
      numType: numType,
      fact: related,
    );
  }
}

final class _SourceThenDistinctRelatedQuestionGenerator
    extends QuestionGenerator {
  _SourceThenDistinctRelatedQuestionGenerator() : super(rng: Random(4300));

  int relatedBuildCount = 0;

  @override
  Question? buildRelated({
    required MathFact fact,
    required Difficulty diff,
    required NumberType numType,
    required Set<Operation> allowedOperations,
    Set<FactRepresentation> excludedRepresentations = const {},
  }) {
    relatedBuildCount++;
    final related = fact.copyWith(
      representation: relatedBuildCount == 1
          ? fact.representation
          : switch (fact.representation) {
              FactRepresentation.direct => FactRepresentation.missingLeft,
              FactRepresentation.missingLeft => FactRepresentation.missingRight,
              FactRepresentation.missingRight => FactRepresentation.direct,
            },
    );
    final answer = switch (related.representation) {
      FactRepresentation.direct => related.result,
      FactRepresentation.missingLeft => related.left,
      FactRepresentation.missingRight => related.right,
    };
    return Question(
      type: related.operation,
      key: 'source-then-distinct-$relatedBuildCount',
      text: 'related',
      ans: answer,
      choices: [answer, answer + 1],
      diff: diff,
      numType: numType,
      fact: related,
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
