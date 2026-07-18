import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/gameplay/domain/question_mechanic.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/screens/game_screen.dart' as game_screen;
import 'package:math_challenge/screens/menu_screen.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  test('shared Missing Operation transformer supports all number forms', () {
    final cases = <Question>[
      const Question(
        type: Operation.addition,
        key: 'natural',
        text: '8 + 7 = ?',
        ans: 15,
        choices: [15],
        numType: NumberType.natural,
      ),
      const Question(
        type: Operation.subtraction,
        key: 'integer',
        text: '(-8) − (-3) = ?',
        ans: -5,
        choices: [-5],
        numType: NumberType.integers,
      ),
      const Question(
        type: Operation.multiplication,
        key: 'decimal',
        text: '1.5 × 2 = ?',
        ans: 3,
        choices: [3],
        numType: NumberType.rationals,
      ),
    ];

    for (final question in cases) {
      final transformed = missingOperationQuestion(question, Random(1))!;
      expect(transformed.type, question.type);
      expect(transformed.numType, question.numType);
      expect(transformed.text, contains(' ? '));
      expect(transformed.choices, unorderedEquals(operatorAnswerChoices));
      expect(transformed.choices.where((choice) => choice == transformed.ans),
          hasLength(1));
    }
  });

  test('shared transformer normalizes minus and rejects ambiguity', () {
    const normalized = Question(
      type: Operation.subtraction,
      key: 'minus',
      text: '9 - 4 = ?',
      ans: 5,
      choices: [5],
    );
    const ambiguous = Question(
      type: Operation.addition,
      key: 'ambiguous',
      text: '2 + 2 = ?',
      ans: 4,
      choices: [4],
    );

    expect(missingOperationQuestion(normalized, Random(1))?.ans, 1);
    expect(missingOperationQuestion(ambiguous, Random(1)), isNull);
    expect([0, 1, 2, 3].map(operatorSymbol), ['+', '−', '×', '÷']);
  });

  test('controlled Missing Operation generations can use different orders', () {
    const question = Question(
      type: Operation.addition,
      key: 'randomized-order',
      text: '8 + 7 = ?',
      ans: 15,
      choices: [15],
    );
    final random = Random(1);

    final first = missingOperationQuestion(question, random)!;
    final second = missingOperationQuestion(question, random)!;

    expect(first.choices, unorderedEquals(operatorAnswerChoices));
    expect(second.choices, unorderedEquals(operatorAnswerChoices));
    expect(second.choices, isNot(equals(first.choices)));
  });

  testWidgets(
      'long Easy Natural runs reuse only valid Missing Operation facts after exhaustion',
      (tester) async {
    final state = await _startLongMissingOperationRun(
      questionCount: 10,
      players: 1,
    );
    addTearDown(state.dispose);

    final questions = await _completeMissingOperationRun(
      tester,
      state,
      turns: 10,
    );

    expect(
      questions.map((q) => q.key).toSet().length,
      lessThan(questions.length),
    );
  });

  testWidgets('25-question Missing Operation practice completes',
      (tester) async {
    final state = await _startLongMissingOperationRun(
      questionCount: 25,
      players: 1,
    );
    addTearDown(state.dispose);

    await _completeMissingOperationRun(tester, state, turns: 25);
  });

  testWidgets('two-player Missing Operation practice completes 50 turns',
      (tester) async {
    final state = await _startLongMissingOperationRun(
      questionCount: 25,
      players: 2,
    );
    addTearDown(state.dispose);

    final questions = await _completeMissingOperationRun(
      tester,
      state,
      turns: 50,
    );

    expect(state.p[1].total, 25);
    expect(state.p[2].total, 25);
    expect(questions.map((q) => q.type).toSet(), {Operation.multiplication});
  });

  testWidgets('replay completes another exhausted Missing Operation run',
      (tester) async {
    final state = await _startLongMissingOperationRun(
      questionCount: 10,
      players: 1,
    );
    addTearDown(state.dispose);

    await _completeMissingOperationRun(tester, state, turns: 10);
    await state.replayGame();
    state.rt
      ..challenge = Operation.multiplication
      ..timer?.cancel();
    await _completeMissingOperationRun(tester, state, turns: 10);
  });

  test('practice uses a normal snapshot and forces Choice4', () async {
    SharedPreferences.setMockInitialValues({
      'mc_selectedAnswerStyle': AnswerStyle.trueFalse.name,
    });
    await Storage.init();
    final settings = SettingsService()
      ..load(
        dark: false,
        sound: false,
        vibration: false,
        dyslexia: false,
        colorblind: false,
        lowPerf: true,
        reduceMotion: true,
        animSpeed: 1,
      );
    final state = GameState(settings: settings, audio: _NoOpAudioService());
    await state.load();
    final progressBefore = state.operationQuestProgress.encode();

    state.goToConfig('missingOperation');
    expect(state.selectedAnswerStyle, AnswerStyle.trueFalse);
    expect(state.effectiveAnswerStyle, AnswerStyle.choice4);
    state.players = 2;
    state.mode = GameMode.standard;
    state.numType = NumberType.natural;
    state.diff = Difficulty.easy;
    state.questionCount = 15;
    state.startGame();
    state.rt.timer?.cancel();
    final firstQuestion = state.rt.q!;

    expect(state.activeRunSnapshot?.runType, GameRunType.normal);
    expect(
      state.activeRunSnapshot?.questionMechanic,
      QuestionMechanic.missingOperation,
    );
    expect(state.activeRunSnapshot?.players, 2);
    expect(state.activeRunSnapshot?.questionTarget, 15);
    expect(state.rt.answerStyle, AnswerStyle.choice4);
    expect(state.rt.q?.type, isNot(Operation.mixed));
    expect(state.isOperationQuest, isFalse);
    expect(state.operationQuestProgress.encode(), progressBefore);
    expect(
      Storage.getString('mc_selectedAnswerStyle', ''),
      AnswerStyle.trueFalse.name,
    );

    await state.replayGame();
    state.rt.timer?.cancel();
    final replayQuestion = state.rt.q!;
    expect(state.activeRunSnapshot?.runType, GameRunType.normal);
    expect(
      state.activeRunSnapshot?.questionMechanic,
      QuestionMechanic.missingOperation,
    );
    expect(state.activeRunSnapshot?.players, 2);
    expect(state.activeRunSnapshot?.questionTarget, 15);
    expect(state.rt.answerStyle, AnswerStyle.choice4);
    expect(state.rt.q?.type, isNot(Operation.mixed));
    expect(replayQuestion.choices, unorderedEquals(operatorAnswerChoices));
    expect(replayQuestion.choices, isNot(same(firstQuestion.choices)));
    expect(state.operationQuestProgress.encode(), progressBefore);
    state.goToConfig('addition');
    expect(state.selectedAnswerStyle, AnswerStyle.trueFalse);
    state.players = 1;
    state.mode = GameMode.standard;
    expect(state.effectiveAnswerStyle, AnswerStyle.trueFalse);
    state.dispose();
  });

  test('pending mechanic cannot leak into unrelated flows', () async {
    final state = await _makeState();

    for (final enterOtherFlow in <void Function()>[
      () => state.goToConfig('addition'),
      () => state.goToConfig('master'),
      state.showDailyBoss,
      state.showOperationQuest,
    ]) {
      state.goToConfig('missingOperation');
      expect(state.isMissingOperationPractice, isTrue);
      enterOtherFlow();
      expect(state.isMissingOperationPractice, isFalse);
    }
    state.dispose();
  });

  test('all number types and difficulties start transformed normal runs',
      () async {
    for (final numberType in [
      NumberType.natural,
      NumberType.integers,
      NumberType.rationals,
    ]) {
      for (final difficulty in [
        Difficulty.easy,
        Difficulty.medium,
        Difficulty.hard,
      ]) {
        final state = await _makeState();
        state.goToConfig('missingOperation');
        state.players = 1;
        state.mode = GameMode.standard;
        state.numType = numberType;
        state.diff = difficulty;
        state.adaptive = false;

        state.startGame();
        state.rt.timer?.cancel();

        final snapshot = state.activeRunSnapshot!;
        final question = state.rt.q!;
        expect(snapshot.runType, GameRunType.normal);
        expect(snapshot.questionMechanic, QuestionMechanic.missingOperation);
        expect(snapshot.numberType, numberType);
        expect(snapshot.difficulty, difficulty);
        expect(snapshot.answerStyle, AnswerStyle.choice4);
        expect(question.type, isNot(Operation.mixed));
        expect(question.numType, numberType);
        expect(question.ans, isIn(operatorAnswerChoices));
        expect(question.choices, unorderedEquals(operatorAnswerChoices));
        state.dispose();
      }
    }
  });

  test('every non-standard mode starts a transformed one-player run', () async {
    for (final mode in GameMode.values.where((m) => m != GameMode.standard)) {
      final state = await _makeState();
      state.goToConfig('missingOperation');
      state.players = 1;
      state.mode = mode;
      state.numType = NumberType.natural;
      state.diff = Difficulty.easy;
      state.adaptive = false;

      state.startGame();
      state.rt.timer?.cancel();

      final snapshot = state.activeRunSnapshot!;
      final question = state.rt.q!;
      expect(snapshot.runType, GameRunType.normal);
      expect(snapshot.mode, mode);
      expect(snapshot.players, 1);
      expect(snapshot.questionMechanic, QuestionMechanic.missingOperation);
      expect(snapshot.answerStyle, AnswerStyle.choice4);
      expect(question.type, isNot(Operation.mixed));
      expect(question.ans, isIn(operatorAnswerChoices));
      expect(question.choices, unorderedEquals(operatorAnswerChoices));
      state.dispose();
    }
  });

  testWidgets('rebuild and feedback use stored operator values',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    state.goToConfig('missingOperation');
    state
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = false
      ..startGame();
    state.rt.timer?.cancel();
    final question = state.rt.q!;
    final expectedOrder = question.choices.map(operatorSymbol).toList();

    Widget game() => MultiProvider(
          providers: [
            ChangeNotifierProvider<GameState>.value(value: state),
            ChangeNotifierProvider<SettingsService>.value(
              value: state.settings,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: game_screen.GameScreen()),
          ),
        );
    List<String> renderedOrder() => tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .where(expectedOrder.contains)
        .toList();

    await tester.pumpWidget(game());
    expect(renderedOrder(), expectedOrder);
    await tester.pumpWidget(game());
    expect(state.rt.q, same(question));
    expect(renderedOrder(), expectedOrder);

    final correctSymbol = operatorSymbol(question.ans);
    await tester.ensureVisible(find.text(correctSymbol));
    await tester.pump();
    await tester.tap(find.text(correctSymbol));
    await tester.pump();
    expect(state.rt.selectedAnswer, question.ans);
    expect(state.rt.lastAnswerCorrect, isTrue);
    final correctButton = tester.widget<AnimatedContainer>(find
        .ancestor(
          of: find.text(correctSymbol),
          matching: find.byType(AnimatedContainer),
        )
        .first);
    expect((correctButton.decoration! as BoxDecoration).color,
        const Color(GameConfig.mint));
    await tester.pump(const Duration(seconds: 3));

    final nextQuestion = state.rt.q!;
    final wrong = nextQuestion.choices.firstWhere(
      (choice) => choice != nextQuestion.ans,
    );
    final wrongSymbol = operatorSymbol(wrong);
    await tester.ensureVisible(find.text(wrongSymbol));
    await tester.tap(find.text(wrongSymbol));
    await tester.pump();
    expect(state.rt.selectedAnswer, wrong);
    expect(state.rt.lastAnswerCorrect, isFalse);
    final wrongButton = tester.widget<AnimatedContainer>(find
        .ancestor(
          of: find.text(wrongSymbol),
          matching: find.byType(AnimatedContainer),
        )
        .first);
    expect((wrongButton.decoration! as BoxDecoration).color,
        const Color(GameConfig.punch));
    final revealedCorrectButton = tester.widget<AnimatedContainer>(find
        .ancestor(
          of: find.text(operatorSymbol(nextQuestion.ans)),
          matching: find.byType(AnimatedContainer),
        )
        .first);
    expect((revealedCorrectButton.decoration! as BoxDecoration).color,
        const Color(GameConfig.mint));
    await tester.pump(const Duration(seconds: 3));
    state.rt.timer?.cancel();
  });

  test('ordinary player, count, and adaptive setters remain available',
      () async {
    final state = await _makeState();
    state.goToConfig('missingOperation');
    for (final count in [10, 15, 20, 25]) {
      state.setOption('q', count);
      expect(state.questionCount, count);
    }
    state.players = 2;
    state.setOption('mode', GameMode.blitz.name);
    expect(state.mode, GameMode.standard);
    state.setAdaptive(false);
    expect(state.adaptive, isFalse);
    state.setAdaptive(true);
    expect(state.adaptive, isTrue);
    expect(state.effectiveAnswerStyle, AnswerStyle.choice4);
    state.dispose();
  });

  testWidgets('fifth card stays centered at high text scale and opens config',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final settings = SettingsService()
      ..load(
        dark: false,
        sound: false,
        vibration: false,
        dyslexia: false,
        colorblind: false,
        lowPerf: true,
        reduceMotion: true,
        animSpeed: 1,
      );
    final state = GameState(settings: settings, audio: _NoOpAudioService());
    await state.load();
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      state.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<GameState>.value(value: state),
        ],
        child: const MaterialApp(home: Scaffold(body: MenuScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('MISSING OPERATION'), findsOneWidget);
    expect(find.text('MISSING NUMBER'), findsNothing);
    final fittedFinder = find.ancestor(
      of: find.text('MISSING OPERATION'),
      matching: find.byType(FittedBox),
    );
    expect(fittedFinder, findsOneWidget);
    final fittedLabel = tester.widget<FittedBox>(fittedFinder);
    expect(tester.takeException(), isNull);
    final card = find.ancestor(
      of: find.text('MISSING OPERATION'),
      matching: find.byType(InkWell),
    );
    final additionCard = find.ancestor(
      of: find.text('ADDITION'),
      matching: find.byType(InkWell),
    );
    expect(tester.getCenter(card).dx, closeTo(417, 1));
    expect(tester.getSize(card).width, tester.getSize(additionCard).width);

    await tester.ensureVisible(find.text('MISSING OPERATION'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MISSING OPERATION'));
    await tester.pump();
    expect(state.currentScreen, GameScreen.numType);
    expect(state.isMissingOperationPractice, isTrue);
    expect(state.selectedAnswerStyle, AnswerStyle.choice4);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 160, height: 32, child: fittedLabel),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('MISSING OPERATION'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<GameState> _makeState() async {
  SharedPreferences.setMockInitialValues({
    'mc_selectedAnswerStyle': AnswerStyle.trueFalse.name,
  });
  await Storage.init();
  final settings = SettingsService()
    ..load(
      dark: false,
      sound: false,
      vibration: false,
      dyslexia: false,
      colorblind: false,
      lowPerf: true,
      reduceMotion: true,
      animSpeed: 1,
    );
  final state = GameState(settings: settings, audio: _NoOpAudioService());
  await state.load();
  return state;
}

Future<GameState> _startLongMissingOperationRun({
  required int questionCount,
  required int players,
}) async {
  final state = await _makeState();
  state.goToConfig('missingOperation');
  state
    ..players = players
    ..mode = GameMode.standard
    ..numType = NumberType.natural
    ..diff = Difficulty.easy
    ..questionCount = questionCount
    ..adaptive = false;
  state.rt.challenge = Operation.multiplication;
  state.startGame();
  state.rt.timer?.cancel();
  return state;
}

Future<List<Question>> _completeMissingOperationRun(
  WidgetTester tester,
  GameState state, {
  required int turns,
}) async {
  final questions = <Question>[];
  final cycleFacts = <String>{};
  var previousUsedFactCount = 0;
  for (var turn = 0; turn < turns; turn++) {
    state.rt.timer?.cancel();
    final question = state.rt.q!;
    expect(question.type, Operation.multiplication);
    expect(question.ans, isIn(operatorAnswerChoices));
    expect(question.choices, unorderedEquals(operatorAnswerChoices));
    expect(_validOperatorCount(question), 1);
    final baseKey = question.key.replaceFirst(':missing-operation', '');
    if (state.rt.usedFacts.length < previousUsedFactCount) {
      cycleFacts.clear();
    }
    expect(cycleFacts.add(baseKey), isTrue);
    expect(state.rt.usedFacts, contains(baseKey));
    previousUsedFactCount = state.rt.usedFacts.length;
    questions.add(question);
    state.onAnswer(question.ans);
    await tester.pump(const Duration(milliseconds: 1300));
  }
  expect(state.rt.totalTurns, turns);
  await tester.pump(const Duration(seconds: 3));
  return questions;
}

int _validOperatorCount(Question question) {
  final match = RegExp(
    r'^(-?\d+(?:\.\d+)?) \? (-?\d+(?:\.\d+)?) = (-?\d+(?:\.\d+)?)$',
  ).firstMatch(question.text)!;
  final left = num.parse(match.group(1)!);
  final right = num.parse(match.group(2)!);
  final result = num.parse(match.group(3)!);
  bool matches(num value) => (value - result).abs() < 1e-9;
  return [
    matches(left + right),
    matches(left - right),
    matches(left * right),
    right != 0 && matches(left / right),
  ].where((isValid) => isValid).length;
}

class _NoOpAudioService implements AudioService {
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
