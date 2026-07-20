import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:math_challenge/screens/game_screen.dart' as game_screen;
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/modals.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioPlayerChannel = MethodChannel('xyz.luan/audioplayers');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, (_) async => null);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, null);
  });

  test('proposal uses correct-index parity and fails when correct is missing',
      () {
    const even = Question(
      type: Operation.addition,
      key: 'even',
      text: '4 + 4',
      ans: 8,
      choices: [8, 7, 6, 9],
    );
    const odd = Question(
      type: Operation.addition,
      key: 'odd',
      text: '4 + 4',
      ans: 8,
      choices: [7, 8, 6, 9],
    );
    const missing = Question(
      type: Operation.addition,
      key: 'missing',
      text: '4 + 4',
      ans: 8,
      choices: [7, 6, 9, 10],
    );

    expect(trueFalseProposal(even), (answer: 8, truth: true));
    expect(trueFalseProposal(odd), (answer: 7, truth: false));
    expect(
      () => trueFalseProposal(missing),
      throwsA(anyOf(isA<AssertionError>(), isA<StateError>())),
    );
    expect(
      AnswerStyle.trueFalse.baseScore(classicBase: 10),
      5,
    );
  });

  test('missing and invalid stored styles default to four choices', () async {
    for (final prefs in [
      <String, Object>{},
      <String, Object>{'mc_selectedAnswerStyle': 'unsupported'},
    ]) {
      final state = await _makeState(prefs);
      expect(state.selectedAnswerStyle, AnswerStyle.choice4);
      state.dispose();
    }
  });

  test('selection persists while unsupported games use four choices', () async {
    final state = await _makeState();
    state.setAnswerStyle(AnswerStyle.trueFalse);
    await state.save();

    state.players = 2;
    expect(state.effectiveAnswerStyle, AnswerStyle.choice4);
    expect(state.selectedAnswerStyle, AnswerStyle.trueFalse);

    state.players = 1;
    state.mode = GameMode.blitz;
    expect(state.effectiveAnswerStyle, AnswerStyle.choice4);

    final reloaded = await _makeState(
      {
        'mc_selectedAnswerStyle':
            Storage.getString('mc_selectedAnswerStyle', '')
      },
    );
    expect(reloaded.selectedAnswerStyle, AnswerStyle.trueFalse);
    state.dispose();
    reloaded.dispose();
  });

  test('replay restores the started mode, difficulty, and answer style',
      () async {
    final state = await _makeState();
    _startTrueFalse(state);
    expect(state.rt.answerStyle, AnswerStyle.trueFalse);

    state.mode = GameMode.blitz;
    state.diff = Difficulty.hard;
    state.setAnswerStyle(AnswerStyle.choice4);
    await state.replayGame();
    state.rt.timer?.cancel();

    expect(state.activeMode, GameMode.standard);
    expect(state.activeDifficulty, Difficulty.easy);
    expect(state.mode, GameMode.standard);
    expect(state.diff, Difficulty.easy);
    expect(state.rt.answerStyle, AnswerStyle.trueFalse);
    expect(state.selectedAnswerStyle, AnswerStyle.choice4);
    state.dispose();
  });

  testWidgets('true-false scores once and records the session style',
      (tester) async {
    final state = await _makeState();
    state.questionCount = 1;
    _startTrueFalse(state);
    state.rt.qTimerLimit = 0;
    state.rt.qStartTs = DateTime.now().millisecondsSinceEpoch - 5000;
    state.p[1].pups = [PowerUp.fifty];
    state.mode = GameMode.blitz;
    state.diff = Difficulty.hard;
    state.setAnswerStyle(AnswerStyle.choice4);

    expect(state.isPowerUpBlocked(PowerUp.fifty), isTrue);
    state.usePowerUp(PowerUp.fifty);
    expect(state.p[1].pups, [PowerUp.fifty]);
    expect(state.rt.puUsed, 0);

    state.onTrueFalseAnswer(state.rt.proposedTruth!);
    state.onTrueFalseAnswer(state.rt.proposedTruth!);

    expect(state.p[1].total, 1);
    expect(state.p[1].correct, 1);
    expect(state.p[1].score, 5);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(state.highScores.single.mode, GameMode.standard);
    expect(state.highScores.single.answerStyle, AnswerStyle.trueFalse);
    expect(state.highScores.single.difficulty, Difficulty.easy);
    state.dispose();
  });

  test('matching True and False responses both grade as correct', () async {
    for (final truth in [true, false]) {
      final state = await _makeState();
      _startTrueFalse(state);
      state.rt.qTimerLimit = 0;
      state.rt.proposedTruth = truth;

      state.onTrueFalseAnswer(truth);

      expect(state.p[1].total, 1);
      expect(state.p[1].correct, 1);
      state.dispose();
    }
  });

  test('high scores serialize typed fields and migrate legacy entries', () {
    const score = HighScore(
      name: 'Ada',
      score: 42,
      mode: GameMode.standard,
      difficulty: Difficulty.hard,
      answerStyle: AnswerStyle.trueFalse,
      date: '2026-07-14',
    );

    expect(score.toJson(), {
      'name': 'Ada',
      'score': 42,
      'mode': 'standard',
      'difficulty': 'hard',
      'answerStyle': 'trueFalse',
      'date': '2026-07-14',
    });

    final legacy = HighScore.fromJson({
      'name': 'Legacy',
      'score': 10,
      'mode': 'standard',
      'date': '2025-01-01',
    });
    expect(legacy.mode, GameMode.standard);
    expect(legacy.difficulty, isNull);
    expect(legacy.answerStyle, AnswerStyle.choice4);
  });

  testWidgets('selector is shown only for one-player Standard', (tester) async {
    final state = await _makeState();
    state.players = 1;
    state.mode = GameMode.standard;
    await _pump(tester, state, const ConfigScreen());

    expect(find.text('Answer Style'), findsOneWidget);
    expect(find.text('True / False'), findsOneWidget);

    state.setOption('players', 2);
    await tester.pump();
    expect(find.text('Answer Style'), findsNothing);

    state.setOption('players', 1);
    state.setOption('mode', GameMode.blitz.name);
    await tester.pump();
    expect(find.text('Answer Style'), findsNothing);
    state.dispose();
  });

  testWidgets('true-false proposition uses stored formatted answer stably',
      (tester) async {
    final cases = [
      (
        question: const Question(
          type: Operation.addition,
          key: 'natural',
          text: '2 + 3 = ?',
          ans: 5,
          choices: [4, 5, 6, 7],
          numType: NumberType.natural,
        ),
        proposed: 5,
        truth: true,
        expected: '2 + 3 = 5',
      ),
      (
        question: const Question(
          type: Operation.addition,
          key: 'integer',
          text: '-5 + 2 = ?',
          ans: -3,
          choices: [-4, -3, -2, -1],
          numType: NumberType.integers,
        ),
        proposed: -2,
        truth: false,
        expected: '-5 + 2 = -2',
      ),
      (
        question: const Question(
          type: Operation.addition,
          key: 'rational',
          text: '1.25 + 1.25 = ?',
          ans: 2.5,
          choices: [2, 2.25, 2.5, 2.75],
          numType: NumberType.rationals,
        ),
        proposed: 2.5,
        truth: true,
        expected: '1.25 + 1.25 = 2.5',
      ),
    ];

    for (final testCase in cases) {
      final state = await _makeState();
      _setTrueFalseQuestion(
        state,
        question: testCase.question,
        proposedAnswer: testCase.proposed,
        proposedTruth: testCase.truth,
      );
      await _pump(tester, state, const game_screen.GameScreen());

      expect(
        find.text(testCase.expected, findRichText: true),
        findsOneWidget,
      );
      expect(find.text('?', findRichText: true), findsNothing);
      expect(find.byKey(const Key('true-false-proposal')), findsNothing);

      state.notifyListeners();
      await tester.pump();
      expect(
        find.text(testCase.expected, findRichText: true),
        findsOneWidget,
      );
      expect(state.rt.proposedAnswer, testCase.proposed);
      state.dispose();
    }
  });

  testWidgets('true-false reuses the normal first-row answer tile geometry',
      (tester) async {
    final state = await _makeState();
    _setTrueFalseQuestion(
      state,
      question: const Question(
        type: Operation.addition,
        key: 'geometry',
        text: '2 + 3 = ?',
        ans: 5,
        choices: [4, 5, 6, 7],
        numType: NumberType.natural,
      ),
      proposedAnswer: 5,
      proposedTruth: true,
    );
    state.rt.answerStyle = AnswerStyle.choice4;
    await _pump(tester, state, const game_screen.GameScreen());

    final firstChoice = tester.getRect(find.widgetWithText(InkWell, '4'));
    final secondChoice = tester.getRect(find.widgetWithText(InkWell, '5'));
    final normalGridTop = tester.getTopLeft(find.byType(GridView).last).dy;
    expect(firstChoice.top, normalGridTop);
    expect(secondChoice.top, normalGridTop);

    state.rt.answerStyle = AnswerStyle.trueFalse;
    state.notifyListeners();
    await tester.pump();

    final trueTile = tester.getRect(find.byKey(const Key('answer-true')));
    final falseTile = tester.getRect(find.byKey(const Key('answer-false')));
    expect(trueTile.size, firstChoice.size);
    expect(falseTile.size, secondChoice.size);
    expect(trueTile.left, firstChoice.left);
    expect(falseTile.left, secondChoice.left);
    final trueFalseGridTop = tester.getTopLeft(find.byType(GridView).last).dy;
    expect(trueTile.top, trueFalseGridTop);
    expect(falseTile.top, trueFalseGridTop);
    expect(trueTile.width, lessThan(190));
    for (final choice in ['4', '5', '6', '7']) {
      expect(find.text(choice), findsNothing);
    }
    expect(find.byKey(const Key('answer-true')), findsOneWidget);
    expect(find.byKey(const Key('answer-false')), findsOneWidget);

    await _pump(
      tester,
      state,
      const game_screen.GameScreen(),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  testWidgets('true-false hides only disabled 50/50 count until Choice4',
      (tester) async {
    final state = await _makeState();
    _setTrueFalseQuestion(
      state,
      question: const Question(
        type: Operation.addition,
        key: 'badge',
        text: '2 + 3 = ?',
        ans: 5,
        choices: [4, 5, 6, 7],
        numType: NumberType.natural,
      ),
      proposedAnswer: 5,
      proposedTruth: true,
    );
    state.p[1].pups = [PowerUp.fifty, PowerUp.fifty];
    await _pump(tester, state, const game_screen.GameScreen());

    expect(find.byKey(const Key('answer-true')), findsOneWidget);
    expect(find.byKey(const Key('answer-false')), findsOneWidget);
    expect(find.text('50/50'), findsOneWidget);
    expect(find.byKey(const Key('powerup-fifty-count')), findsNothing);
    expect(
      find
          .ancestor(
            of: find.text('50/50'),
            matching: find.byWidgetPredicate(
              (widget) => widget is Opacity && widget.opacity == 0.42,
            ),
          )
          .evaluate(),
      isNotEmpty,
    );

    await tester.tap(find.text('50/50'));
    await tester.pump();
    expect(state.p[1].pups.where((pu) => pu == PowerUp.fifty).length, 2);
    expect(state.rt.puUsed, 0);

    state.rt.answerStyle = AnswerStyle.choice4;
    state.notifyListeners();
    await tester.pump();

    expect(find.byKey(const Key('powerup-fifty-count')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('powerup-fifty-count')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(find.text('?', findRichText: true), findsOneWidget);
    for (final answer in ['4', '5', '6', '7']) {
      expect(find.text(answer), findsOneWidget);
    }
    expect(state.p[1].pups.where((pu) => pu == PowerUp.fifty).length, 2);
    state.dispose();
  });

  testWidgets('Hall of Fame composes typed score labels', (tester) async {
    final state = await _makeState();
    state.highScores = const [
      HighScore(
        name: 'Ada',
        score: 42,
        mode: GameMode.standard,
        difficulty: Difficulty.easy,
        answerStyle: AnswerStyle.trueFalse,
        date: '2026-07-14',
      ),
    ];
    await _pump(tester, state, HighScoreModal(gs: state));

    expect(find.text('Standard · Easy · True / False'), findsOneWidget);
    state.dispose();
  });
}

Future<GameState> _makeState([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
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
  final state = GameState(settings: settings, audio: AudioService(settings));
  await state.load();
  return state;
}

void _startTrueFalse(GameState state) {
  state.players = 1;
  state.mode = GameMode.standard;
  state.rt.challenge = Operation.addition;
  state.adaptive = false;
  state.setAnswerStyle(AnswerStyle.trueFalse);
  state.startGame();
  state.rt.timer?.cancel();
}

void _setTrueFalseQuestion(
  GameState state, {
  required Question question,
  required num proposedAnswer,
  required bool proposedTruth,
}) {
  state.players = 1;
  state.mode = GameMode.standard;
  state.currentScreen = GameScreen.game;
  state.p[1].resetForGame(isSinglePlayer: true, isMasterOrBoss: false);
  state.rt = RuntimeState()
    ..challenge = question.type
    ..answerStyle = AnswerStyle.trueFalse
    ..proposedAnswer = proposedAnswer
    ..proposedTruth = proposedTruth
    ..gameActive = true
    ..state = 'playing'
    ..maxTurns = 10
    ..accepting = true
    ..q = question;
}

Future<void> _pump(
  WidgetTester tester,
  GameState state,
  Widget child, {
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: state.settings),
        ChangeNotifierProvider<GameState>.value(value: state),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pump();
}
