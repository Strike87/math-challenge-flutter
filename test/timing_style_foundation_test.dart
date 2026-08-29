import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/gameplay/domain/question_mechanic.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:math_challenge/screens/game_screen.dart' as gameplay;
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:provider/provider.dart';
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
      questionGenerator: QuestionGenerator(rng: Random(1408)),
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  Future<void> enableGameBrain(GameState state) async {
    await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
    await state.setGameBrainPreference(true);
    expect(state.effectiveGameBrainEnabled, isTrue);
  }

  GameRunSnapshot supportedSnapshot({
    TimingStyle timingStyle = TimingStyle.perQuestion,
    int players = 1,
    GameMode mode = GameMode.standard,
    QuestionMechanic questionMechanic = QuestionMechanic.standard,
    Difficulty difficulty = Difficulty.easy,
  }) =>
      GameRunSnapshot(
        runType: GameRunType.normal,
        mode: mode,
        operation: Operation.addition,
        difficulty: difficulty,
        numberType: NumberType.natural,
        answerStyle: AnswerStyle.choice4,
        players: players,
        questionTarget: 10,
        questionMechanic: questionMechanic,
        timingStyle: timingStyle,
      );

  Future<GameState> startSupportedSnapshot(TimingStyle timingStyle) async {
    final state = await makeState();
    await enableGameBrain(state);
    state.debugStartGameFromSnapshot(supportedSnapshot(
      timingStyle: timingStyle,
    ));
    state.rt.timer?.cancel();
    return state;
  }

  Future<GameState> startConfiguredRun({
    TimingStyle timingStyle = TimingStyle.perQuestion,
    int questionCount = 10,
    Difficulty difficulty = Difficulty.easy,
  }) async {
    final state = await makeState();
    state
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = false
      ..diff = difficulty
      ..questionCount = questionCount
      ..rt.challenge = Operation.addition;
    state.setTimingStyle(timingStyle);
    state.startGame();
    return state;
  }

  Future<void> pumpWithState(
    WidgetTester tester,
    GameState state,
    Widget child,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameState>.value(value: state),
          ChangeNotifierProvider<SettingsService>.value(value: state.settings),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  bool inkWellEnabled(WidgetTester tester, String label) {
    final inkWell = find.ancestor(
      of: find.text(label, skipOffstage: false),
      matching: find.byType(InkWell),
    );
    expect(inkWell, findsOneWidget);
    return tester.widget<InkWell>(inkWell).onTap != null;
  }

  Future<void> tapVisibleText(WidgetTester tester, String label) async {
    final text = find.text(label, skipOffstage: false);
    await tester.ensureVisible(text);
    await tester.tap(text, warnIfMissed: false);
    await tester.pump();
  }

  Future<void> answerCorrectAndSettle(
    WidgetTester tester,
    GameState state,
  ) async {
    state.onAnswer(state.rt.q!.ans);
    await tester.pump(const Duration(seconds: 4));
  }

  Finder timerCircleFinder() => find.byWidgetPredicate((widget) {
        if (widget is! Container ||
            widget.constraints !=
                const BoxConstraints.tightFor(width: 56, height: 56) ||
            widget.child is! Text) {
          return false;
        }
        final decoration = widget.decoration;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle;
      });

  test('snapshot defaults to per-question timing', () {
    expect(supportedSnapshot().timingStyle, TimingStyle.perQuestion);
  });

  test('snapshot accepts future timing styles without gameplay wiring', () {
    expect(supportedSnapshot(timingStyle: TimingStyle.untimed).timingStyle,
        TimingStyle.untimed);
    expect(supportedSnapshot(timingStyle: TimingStyle.timeBank).timingStyle,
        TimingStyle.timeBank);
  });

  test('default active run keeps existing per-question timer behavior',
      () async {
    final state = await makeState();
    state
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = false
      ..diff = Difficulty.easy
      ..rt.challenge = Operation.addition
      ..startGame();

    expect(state.activeRunSnapshot?.timingStyle, TimingStyle.perQuestion);
    expect(state.debugQuestionTimerDurationMs(), 10000);
    expect(state.rt.timer?.isActive, isTrue);
    state.rt.timer?.cancel();
  });

  testWidgets('config timing choices stay visible and enforce eligibility',
      (tester) async {
    final state = await makeState();
    state
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = false;
    state.goToConfig(Operation.addition.name);
    state.showScreen(GameScreen.config);
    expect(state.canSelectDeepThinking, isTrue);

    await pumpWithState(tester, state, const ConfigScreen());
    expect(state.setupTimingStyle, TimingStyle.perQuestion);
    expect(find.text('Per Question', skipOffstage: false), findsOneWidget);
    expect(find.text('Deep Thinking', skipOffstage: false), findsOneWidget);
    expect(find.text('Time Bank', skipOffstage: false), findsOneWidget);
    expect(inkWellEnabled(tester, 'Per Question'), isTrue);
    expect(inkWellEnabled(tester, 'Deep Thinking'), isTrue);
    expect(inkWellEnabled(tester, 'Time Bank'), isTrue);
    expect(find.text('Players', skipOffstage: false), findsOneWidget);
    expect(find.text('Game Mode', skipOffstage: false), findsOneWidget);
    expect(
        find.text('Adaptive Difficulty', skipOffstage: false), findsOneWidget);

    await tapVisibleText(tester, 'Time Bank');
    expect(state.setupTimingStyle, TimingStyle.timeBank);

    await tapVisibleText(tester, 'Deep Thinking');
    expect(state.setupTimingStyle, TimingStyle.untimed);
    expect(find.text('2 Players', skipOffstage: false), findsOneWidget);
    expect(find.text('Death', skipOffstage: false), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(inkWellEnabled(tester, '2 Players'), isFalse);
    expect(inkWellEnabled(tester, 'Death'), isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);

    await tapVisibleText(tester, '2 Players');
    await tapVisibleText(tester, 'Death');
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch), warnIfMissed: false);
    await tester.pump();
    expect(state.setupPlayers, 1);
    expect(state.mode, GameMode.standard);
    expect(state.adaptive, isFalse);
    expect(state.setupTimingStyle, TimingStyle.untimed);

    state.setOption('players', 2);
    await tester.pump();
    expect(find.text('Deep Thinking', skipOffstage: false), findsOneWidget);
    expect(inkWellEnabled(tester, 'Deep Thinking'), isFalse);
    await tapVisibleText(tester, 'Deep Thinking');
    expect(state.setupTimingStyle, TimingStyle.perQuestion);

    state.setOption('players', 1);
    state.setAdaptive(true);
    await tester.pump();
    expect(find.text('Deep Thinking', skipOffstage: false), findsOneWidget);
    expect(inkWellEnabled(tester, 'Deep Thinking'), isFalse);
    await tapVisibleText(tester, 'Deep Thinking');
    expect(state.setupTimingStyle, TimingStyle.perQuestion);

    state.setAdaptive(false);
    state.setOption('mode', GameMode.death.name);
    await tester.pump();
    expect(find.text('Deep Thinking', skipOffstage: false), findsOneWidget);
    expect(inkWellEnabled(tester, 'Deep Thinking'), isFalse);
    await tapVisibleText(tester, 'Deep Thinking');
    expect(state.setupTimingStyle, TimingStyle.perQuestion);
  });

  test('stale setup timing cannot start outside the v1 envelope', () async {
    final twoPlayer = await makeState();
    twoPlayer
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = false
      ..rt.challenge = Operation.addition;
    twoPlayer.setTimingStyle(TimingStyle.untimed);
    expect(twoPlayer.setupTimingStyle, TimingStyle.untimed);

    twoPlayer.players = 2;
    twoPlayer.startGame();

    expect(twoPlayer.activeRunSnapshot?.players, 2);
    expect(twoPlayer.activeRunSnapshot?.timingStyle, TimingStyle.perQuestion);

    final adaptive = await makeState();
    adaptive
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = false
      ..rt.challenge = Operation.addition;
    adaptive.setTimingStyle(TimingStyle.untimed);
    adaptive.adaptive = true;
    adaptive.startGame();

    expect(adaptive.activeRunSnapshot?.timingStyle, TimingStyle.perQuestion);

    final timeBank = await makeState();
    timeBank
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = true
      ..rt.challenge = Operation.addition
      ..timingStyle = TimingStyle.timeBank;
    timeBank.startGame();

    expect(timeBank.activeRunSnapshot?.timingStyle, TimingStyle.perQuestion);
  });

  test('forged untimed snapshots fail closed outside the v1 envelope',
      () async {
    final twoPlayer = await makeState();
    twoPlayer.debugStartGameFromSnapshot(supportedSnapshot(
      timingStyle: TimingStyle.untimed,
      players: 2,
    ));
    expect(twoPlayer.activeRunSnapshot?.timingStyle, TimingStyle.perQuestion);
    twoPlayer.rt.timer?.cancel();

    final specialMechanic = await makeState();
    specialMechanic.debugStartGameFromSnapshot(supportedSnapshot(
      timingStyle: TimingStyle.untimed,
      questionMechanic: QuestionMechanic.missingOperation,
    ));
    expect(specialMechanic.activeRunSnapshot?.timingStyle,
        TimingStyle.perQuestion);
    specialMechanic.rt.timer?.cancel();

    final timeBank = await makeState();
    timeBank.debugStartGameFromSnapshot(supportedSnapshot(
      timingStyle: TimingStyle.timeBank,
      difficulty: Difficulty.expert,
    ));
    expect(timeBank.activeRunSnapshot?.timingStyle, TimingStyle.perQuestion);
    timeBank.rt.timer?.cancel();
  });

  test('selecting Deep Thinking creates an untimed snapshot', () async {
    final state = await startConfiguredRun(timingStyle: TimingStyle.untimed);

    expect(state.activeRunSnapshot?.timingStyle, TimingStyle.untimed);
    expect(state.rt.timer, isNull);
    expect(state.debugQuestionTimerDurationMs(), 0);
  });

  test('replay preserves the active snapshot timing style', () async {
    final state = await startSupportedSnapshot(TimingStyle.untimed);

    await state.replayGame();
    state.rt.timer?.cancel();

    expect(state.activeRunSnapshot?.timingStyle, TimingStyle.untimed);
  });

  test('configured replay preserves Deep Thinking timing', () async {
    final state = await startConfiguredRun(timingStyle: TimingStyle.untimed);

    await state.replayGame();

    expect(state.activeRunSnapshot?.timingStyle, TimingStyle.untimed);
    expect(state.rt.timer, isNull);
  });

  test('Deep Thinking has no timer-driven timeout path', () async {
    final state = await startConfiguredRun(timingStyle: TimingStyle.untimed);
    final question = state.rt.q;

    state.debugTimeoutForTest();

    expect(state.rt.q, same(question));
    expect(state.rt.totalTurns, 0);
    expect(state.rt.accepting, isTrue);

    state.onAnswer(state.rt.q!.ans);
    expect(state.p[1].correct, 1);
    expect(state.rt.totalTurns, 1);
  });

  testWidgets('Deep Thinking still completes at the question target',
      (tester) async {
    final state = await startConfiguredRun(
      timingStyle: TimingStyle.untimed,
      questionCount: 1,
    );

    await answerCorrectAndSettle(tester, state);

    expect(state.rt.gameActive, isFalse);
    expect(state.currentModal, GameModal.win);
  });

  test('per-question timeout behavior remains unchanged', () async {
    final state = await startConfiguredRun();

    state.debugTimeoutForTest();

    expect(state.rt.totalTurns, 1);
    expect(state.p[1].correct, 0);
    expect(state.reactionPill, contains("Time's Up"));
  });

  test('Blitz and Combo keep global timer behavior when setup was untimed',
      () async {
    final blitz = await makeState();
    blitz
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = false
      ..rt.challenge = Operation.addition;
    blitz.setTimingStyle(TimingStyle.untimed);
    blitz.setOption('mode', GameMode.blitz.name);
    blitz.startGame();
    expect(blitz.activeRunSnapshot?.timingStyle, TimingStyle.perQuestion);
    expect(blitz.debugQuestionTimerDurationMs(), GameConfig.blitzTimerDefault);

    final combo = await makeState();
    combo
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = false
      ..rt.challenge = Operation.addition;
    combo.setTimingStyle(TimingStyle.untimed);
    combo.setOption('mode', GameMode.combo.name);
    combo.startGame();
    expect(combo.activeRunSnapshot?.timingStyle, TimingStyle.perQuestion);
    expect(combo.debugQuestionTimerDurationMs(), GameConfig.comboTimerDefault);
  });

  test('Deep Thinking mastery keeps wrong/correct evidence without speed tiers',
      () async {
    final wrong = await startConfiguredRun(timingStyle: TimingStyle.untimed);
    wrong.skillMap[Operation.addition.name] = SkillData(
      mastery: 50,
      confidence: 50,
    );
    wrong.rt.qTimerLimit = 1;
    wrong.rt.qStartTs = DateTime.now().millisecondsSinceEpoch - 11000;
    wrong.onAnswer(wrong.rt.q!.choices.firstWhere(
      (choice) => (choice - wrong.rt.q!.ans).abs() >= 1e-9,
    ));
    expect(wrong.skillMap[Operation.addition.name]!.mastery,
        closeTo(45.5, 0.0001));

    final correct = await startConfiguredRun(timingStyle: TimingStyle.untimed);
    correct.skillMap[Operation.addition.name] = SkillData(
      mastery: 50,
      confidence: 50,
    );
    correct.rt.qTimerLimit = 1;
    correct.rt.qStartTs = DateTime.now().millisecondsSinceEpoch - 11000;
    correct.onAnswer(correct.rt.q!.ans);
    expect(correct.skillMap[Operation.addition.name]!.mastery,
        closeTo(55.2, 0.0001));
  });

  testWidgets('Deep Thinking scoring and Hall of Fame are timer-independent',
      (tester) async {
    final untimed = await startConfiguredRun(
      timingStyle: TimingStyle.untimed,
      questionCount: 1,
    );
    await answerCorrectAndSettle(tester, untimed);

    expect(untimed.p[1].score, 10);
    expect(untimed.p[1].bonus, 0);
    expect(untimed.highScores, isEmpty);

    final perQuestion = await startConfiguredRun(questionCount: 1);
    await answerCorrectAndSettle(tester, perQuestion);

    expect(perQuestion.p[1].score, greaterThan(10));
    expect(perQuestion.highScores, isNotEmpty);
  });

  testWidgets('Deep Thinking does not progress speed demon', (tester) async {
    final state = await startConfiguredRun(
      timingStyle: TimingStyle.untimed,
      questionCount: 5,
    );

    for (var i = 0; i < 5; i++) {
      await answerCorrectAndSettle(tester, state);
    }

    expect(state.rt.fastAnswers, 0);
    expect(state.achievements['speed_demon'], isFalse);
  });

  test('Deep Thinking blocks only timer-dependent power-ups', () async {
    final state = await startConfiguredRun(timingStyle: TimingStyle.untimed);
    state.p[1].pups = [
      PowerUp.time,
      PowerUp.freeze,
      PowerUp.fifty,
    ];

    expect(state.isPowerUpBlocked(PowerUp.time), isTrue);
    expect(state.isPowerUpBlocked(PowerUp.freeze), isTrue);
    expect(state.isPowerUpBlocked(PowerUp.fifty), isFalse);

    state.usePowerUp(PowerUp.time);
    state.usePowerUp(PowerUp.freeze);

    expect(state.p[1].pups, contains(PowerUp.time));
    expect(state.p[1].pups, contains(PowerUp.freeze));
    expect(state.rt.puUsed, 0);
    expect(state.rt.frozen, isFalse);
    expect(state.debugQuestionTimerDurationMs(), 0);
  });

  test('Deep Thinking rewards only non-timer power-ups', () async {
    final state = await startConfiguredRun(timingStyle: TimingStyle.untimed);

    state.onAnswer(state.rt.q!.ans);

    expect(state.p[1].pups, isNot(contains(PowerUp.time)));
    expect(state.p[1].pups, isNot(contains(PowerUp.freeze)));
    expect(state.p[1].pups, contains(PowerUp.fifty));
    expect(state.p[1].pups, contains(PowerUp.double));
    expect(state.p[1].pups, contains(PowerUp.shield));
    expect(state.p[1].pups, contains(PowerUp.switchOp));
  });

  testWidgets('gameplay shows countdown only for per-question timing',
      (tester) async {
    final perQuestion = await startConfiguredRun();
    await pumpWithState(tester, perQuestion, const gameplay.GameScreen());
    expect(timerCircleFinder(), findsOneWidget);
    perQuestion.rt.timer?.cancel();

    final untimed = await startConfiguredRun(timingStyle: TimingStyle.untimed);
    await pumpWithState(tester, untimed, const gameplay.GameScreen());
    expect(timerCircleFinder(), findsNothing);

    final timeBank =
        await startConfiguredRun(timingStyle: TimingStyle.timeBank);
    await pumpWithState(tester, timeBank, const gameplay.GameScreen());
    expect(timerCircleFinder(), findsNothing);
    expect(find.byKey(const Key('time-bank-display')), findsOneWidget);
    expect(find.text('TIME BANK'), findsOneWidget);
    timeBank.handleAppLifecycleChange(resumed: false);
  });

  test('non-per-question timing is not player-selectable', () {
    expect(
        GameMode.values.map((mode) => mode.name), isNot(contains('untimed')));
    expect(
        GameMode.values.map((mode) => mode.name), isNot(contains('timeBank')));
    expect(AnswerStyle.values.map((style) => style.name),
        isNot(contains('untimed')));
    expect(AnswerStyle.values.map((style) => style.name),
        isNot(contains('timeBank')));
  });

  test('only active per-question timing enters current Phase-1 evidence',
      () async {
    for (final expectation in <(TimingStyle, TimingStyle, bool)>[
      (TimingStyle.perQuestion, TimingStyle.perQuestion, true),
      (TimingStyle.untimed, TimingStyle.untimed, false),
      (TimingStyle.timeBank, TimingStyle.timeBank, false),
    ]) {
      final state = await startSupportedSnapshot(expectation.$1);

      expect(state.activeRunSnapshot?.timingStyle, expectation.$2);
      expect(state.debugP1F01IntegrityRunEligible, expectation.$3);
      state.onAnswer(state.rt.q!.ans);

      expect(state.debugQuestionExperienceObservationCount,
          expectation.$3 ? 1 : 0);
      expect(
          state.debugContextEvidenceObservationCount, expectation.$3 ? 1 : 0);
    }
  });

  test('Time Bank freezes the fixed budget and replay restores it', () async {
    for (final expectation in <(Difficulty, int, int)>[
      (Difficulty.easy, 10, 100000),
      (Difficulty.medium, 15, 120000),
      (Difficulty.hard, 25, 150000),
    ]) {
      final state = await startConfiguredRun(
        timingStyle: TimingStyle.timeBank,
        questionCount: expectation.$2,
        difficulty: expectation.$1,
      );

      expect(state.activeRunSnapshot?.timingStyle, TimingStyle.timeBank);
      expect(state.rt.qTimerLimit, 0);
      expect(state.rt.timer, isNull);
      expect(state.rt.timeBankRemainingMs, expectation.$3);
      expect(state.rt.timeBankTimer?.isActive, isTrue);

      state.handleAppLifecycleChange(resumed: false);
      state.rt.timeBankRemainingMs = 1;
      await state.replayGame();

      expect(state.activeRunSnapshot?.timingStyle, TimingStyle.timeBank);
      expect(state.rt.timeBankRemainingMs, expectation.$3);
      expect(state.rt.timeBankTimer?.isActive, isTrue);
    }
  });

  testWidgets(
      'Time Bank pauses in background, cannot UI-pause, and exhausts once',
      (tester) async {
    final state = await startConfiguredRun(timingStyle: TimingStyle.timeBank);
    state.skillMap[Operation.addition.name] = SkillData(
      mastery: 50,
      confidence: 50,
    );

    state.handleAppLifecycleChange(resumed: false);
    final pausedRemaining = state.rt.timeBankRemainingMs;
    await tester.pump(const Duration(seconds: 2));
    expect(state.rt.timeBankRemainingMs, pausedRemaining);

    state.rt.timeBankRemainingMs = 0;
    state.showQuitConfirm();
    expect(state.rt.state, 'playing');
    state.handleAppLifecycleChange(resumed: true);

    expect(state.rt.timeBankExhausted, isTrue);
    expect(state.rt.totalTurns, 1);
    expect(state.p[1].total, 1);
    expect(state.reactionPill, contains("Time's Up"));
    expect(state.skillMap[Operation.addition.name]!.mastery,
        closeTo(47.5, 0.0001));
    expect(state.rt.timeBankTimer, isNull);
    expect(state.rt.state, 'ending');

    state.handleAppLifecycleChange(resumed: true);
    expect(state.rt.totalTurns, 1);
    await tester.pump(const Duration(milliseconds: 1300));

    expect(state.rt.gameActive, isFalse);
    expect(state.rt.totalTurns, 1);
    expect(state.resultDescription, 'Time remaining: 0s');
  });

  testWidgets('zero Time Bank preempts an answer before the periodic tick',
      (tester) async {
    final state = await startConfiguredRun(timingStyle: TimingStyle.timeBank);
    final currentQuestion = state.rt.q;
    state.rt.timeBankTimerStart = DateTime.now().millisecondsSinceEpoch -
        state.rt.timeBankRemainingMs -
        1;

    state.onAnswer(currentQuestion!.ans);

    expect(state.rt.timeBankExhausted, isTrue);
    expect(state.p[1].correct, 0);
    expect(state.p[1].total, 1);
    expect(state.rt.totalTurns, 1);
    expect(state.reactionPill, contains("Time's Up"));
    expect(state.rt.timeBankTimer, isNull);
    expect(state.rt.state, 'ending');
    await tester.pump(const Duration(milliseconds: 1300));
    expect(state.rt.gameActive, isFalse);
    expect(state.rt.q, same(currentQuestion));
    expect(state.rt.totalTurns, 1);
  });

  test('Time Bank duplicate active resume keeps the live ticker and debit',
      () async {
    final state = await startConfiguredRun(timingStyle: TimingStyle.timeBank);
    final initialRemaining = state.rt.timeBankRemainingMs;
    final timer = state.rt.timeBankTimer;
    final activeStart = DateTime.now().millisecondsSinceEpoch - 2000;
    state.rt.timeBankTimerStart = activeStart;

    state.handleAppLifecycleChange(resumed: true);

    expect(state.rt.timeBankTimer, same(timer));
    expect(state.rt.timeBankTimerStart, activeStart);

    state.rt.timeBankTimerStart = DateTime.now().millisecondsSinceEpoch - 7000;
    state.handleAppLifecycleChange(resumed: false);

    expect(state.rt.timeBankTimer, isNull);
    expect(
      state.rt.timeBankRemainingMs,
      inInclusiveRange(initialRemaining - 7005, initialRemaining - 6995),
    );
  });

  test('disposing cancels the Time Bank timer', () async {
    final state = await startConfiguredRun(timingStyle: TimingStyle.timeBank);
    final timer = state.rt.timeBankTimer;
    expect(timer?.isActive, isTrue);

    state.dispose();

    expect(timer?.isActive, isFalse);
  });

  testWidgets('Time Bank has base scoring and blocks timer power-ups',
      (tester) async {
    final state = await startConfiguredRun(
      timingStyle: TimingStyle.timeBank,
      questionCount: 1,
    );
    state.p[1].pups = [PowerUp.time, PowerUp.freeze, PowerUp.fifty];

    expect(state.isPowerUpBlocked(PowerUp.time), isTrue);
    expect(state.isPowerUpBlocked(PowerUp.freeze), isTrue);
    state.usePowerUp(PowerUp.time);
    state.usePowerUp(PowerUp.freeze);
    expect(state.p[1].pups, containsAll([PowerUp.time, PowerUp.freeze]));
    expect(state.rt.puUsed, 0);

    state.onAnswer(state.rt.q!.ans);
    expect(state.rt.timeBankTimer, isNull);
    expect(state.p[1].score, 10);
    expect(state.p[1].bonus, 0);
    expect(state.rt.fastAnswers, 0);
    await tester.pump(const Duration(seconds: 4));

    expect(state.highScores, isEmpty);
    expect(state.achievements['speed_demon'], isFalse);
    expect(state.resultDescription, startsWith('Time remaining: '));
  });

  test('Time Bank and Deep Thinking mastery are speed-neutral', () async {
    Future<(double mastery, double confidence)> answerCorrect(
      TimingStyle timingStyle,
      int responseMs,
    ) async {
      final state = await startConfiguredRun(timingStyle: timingStyle);
      state.skillMap[Operation.addition.name] = SkillData(
        mastery: 50,
        confidence: 50,
      );
      state.rt.qStartTs = DateTime.now().millisecondsSinceEpoch - responseMs;
      state.onAnswer(state.rt.q!.ans);
      final skill = state.skillMap[Operation.addition.name]!;
      return (skill.mastery, skill.confidence);
    }

    final timeBankFast = await answerCorrect(TimingStyle.timeBank, 500);
    final timeBankSlow = await answerCorrect(TimingStyle.timeBank, 5000);
    expect(timeBankFast, timeBankSlow);

    final deepThinkingFast = await answerCorrect(TimingStyle.untimed, 500);
    final deepThinkingSlow = await answerCorrect(TimingStyle.untimed, 5000);
    expect(deepThinkingFast, deepThinkingSlow);

    final perQuestionFast = await answerCorrect(TimingStyle.perQuestion, 500);
    final perQuestionSlow = await answerCorrect(TimingStyle.perQuestion, 5000);
    expect(perQuestionFast.$1, greaterThan(perQuestionSlow.$1));
    expect(perQuestionFast.$2, greaterThan(perQuestionSlow.$2));
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
