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

  testWidgets('true-false UI submits once and keeps 50/50 disabled',
      (tester) async {
    final state = await _makeState();
    _startTrueFalse(state);
    state.p[1].pups = [PowerUp.fifty];
    await _pump(tester, state, const game_screen.GameScreen());

    expect(find.byKey(const Key('true-false-proposal')), findsOneWidget);
    expect(find.byKey(const Key('answer-true')), findsOneWidget);
    expect(find.byKey(const Key('answer-false')), findsOneWidget);
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
    expect(state.p[1].pups.where((pu) => pu == PowerUp.fifty).length, 1);
    expect(state.rt.puUsed, 0);
    expect(state.p[1].total, 0);

    final answerKey = state.rt.proposedTruth!
        ? const Key('answer-true')
        : const Key('answer-false');
    await tester.tap(find.byKey(answerKey));
    await tester.pump();

    expect(state.p[1].total, 1);
    expect(state.p[1].correct, 1);
    await tester.pump(const Duration(milliseconds: 1400));
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

Future<void> _pump(
  WidgetTester tester,
  GameState state,
  Widget child,
) async {
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
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}
