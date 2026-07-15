import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/operation_quest/domain/operation_quest.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/screens/menu_screen.dart';
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

  test('domain defines Addition Trail stages, stars, and safe progress JSON',
      () {
    expect(
      operationQuestStages
          .map((stage) => (
                stage.title,
                stage.difficulty,
                stage.operation,
                stage.numberType,
                stage.questionTarget,
              ))
          .toList(),
      [
        (
          'First Sums',
          Difficulty.easy,
          Operation.addition,
          NumberType.natural,
          10
        ),
        (
          'Bigger Sums',
          Difficulty.medium,
          Operation.addition,
          NumberType.natural,
          10
        ),
        (
          'Addition Challenge',
          Difficulty.hard,
          Operation.addition,
          NumberType.natural,
          10
        ),
      ],
    );
    expect(
      List.generate(11, operationQuestStarsForCorrectAnswers),
      [0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3],
    );

    final progress = OperationQuestProgress.decode(jsonEncode({
      'version': 1,
      'stars': {
        'addition_easy': 9,
        'addition_medium': -2,
        'unknown': 3,
      },
    }));
    expect(progress.bestStars(OperationQuestStageId.additionEasy), 3);
    expect(progress.bestStars(OperationQuestStageId.additionMedium), 0);
    expect(progress.isUnlocked(OperationQuestStageId.additionMedium), isTrue);
    expect(progress.isUnlocked(OperationQuestStageId.additionHard), isFalse);
    expect(
      progress
          .recordBest(OperationQuestStageId.additionEasy, 1)
          .bestStars(OperationQuestStageId.additionEasy),
      3,
    );
    expect(OperationQuestProgress.decode('broken').stars, isEmpty);
    expect(
      OperationQuestProgress.decode('{"version":2,"stars":{}}').stars,
      isEmpty,
    );
  });

  test('quest snapshot leaves normal preferences untouched and drives replay',
      () async {
    final state = await _makeState();
    addTearDown(state.dispose);
    state
      ..players = 2
      ..mode = GameMode.combo
      ..diff = Difficulty.insane
      ..numType = NumberType.rationals
      ..questionCount = 20
      ..adaptive = true
      ..selectedAnswerStyle = AnswerStyle.trueFalse;

    state.startOperationQuestStage(OperationQuestStageId.additionEasy);
    expect(state.setupPlayers, 1);
    state.startGame();
    state.rt.timer?.cancel();

    expect(state.players, 2);
    expect(state.mode, GameMode.combo);
    expect(state.diff, Difficulty.insane);
    expect(state.numType, NumberType.rationals);
    expect(state.questionCount, 20);
    expect(state.selectedAnswerStyle, AnswerStyle.trueFalse);
    expect(state.activeRunSnapshot?.runType, GameRunType.operationQuest);
    expect(state.activeMode, GameMode.standard);
    expect(state.activePlayers, 1);
    expect(state.activeDifficulty, Difficulty.easy);
    expect(state.activeNumberType, NumberType.natural);
    expect(state.activeQuestionTarget, 10);
    expect(state.rt.answerStyle, AnswerStyle.choice4);
    expect(state.activeAdaptive, isFalse);
    expect(state.rt.q?.type, Operation.addition);

    await state.replayGame();
    state.rt.timer?.cancel();
    expect(state.activeRunSnapshot?.operationQuestStageId,
        OperationQuestStageId.additionEasy);
    expect(state.activeDifficulty, Difficulty.easy);
    expect(state.mode, GameMode.combo);
    expect(state.diff, Difficulty.insane);
  });

  testWidgets('quest answers use the shared Standard answer pipeline',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    state.dailyChallengeIds = ['streak_7', 'perfect_5'];
    final initialSkill = state.skillMap[Operation.addition.name]!;
    final initialCount = initialSkill.count;
    final initialCorrect = initialSkill.correct;
    final initialMastery = initialSkill.mastery;

    state.startOperationQuestStage(OperationQuestStageId.additionEasy);
    state.startGame();

    expect(state.activeMode, GameMode.standard);
    expect(state.rt.answerStyle, AnswerStyle.choice4);
    expect(state.rt.qTimerLimit,
        GameConfig.timerBaseMs[Difficulty.easy.name]! ~/ 1000);

    state.rt.qStartTs = DateTime.now().millisecondsSinceEpoch - 5000;
    state.onAnswer(state.rt.q!.ans);

    expect(state.p[1].score, GameConfig.scoreBase + 5);
    expect(state.p[1].history, hasLength(1));
    expect(state.p[1].history.single.type, Operation.addition);
    expect(state.p[1].history.single.correct, isTrue);
    final updatedSkill = state.skillMap[Operation.addition.name]!;
    expect(updatedSkill.count, initialCount + 1);
    expect(updatedSkill.correct, initialCorrect + 1);
    expect(updatedSkill.mastery, greaterThan(initialMastery));
    expect(state.dailyProgress['streak_7'], 1);
    expect(state.dailyProgress['perfect_5'], 1);
    for (final powerUp in PowerUp.values) {
      expect(state.p[1].pups, contains(powerUp));
    }

    await tester.pump(const Duration(milliseconds: 1300));
    state.usePowerUp(PowerUp.shield);
    expect(state.p[1].shieldActive, isTrue);
    expect(state.p[1].pups, isNot(contains(PowerUp.shield)));
    expect(state.rt.puUsed, 1);
    state.rt.timer?.cancel();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
      'completed quest persists improved stars once, excludes Hall of Fame, and replays snapshot',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    state.startOperationQuestStage(OperationQuestStageId.additionEasy);
    state.startGame();

    await _finishQuest(tester, state, correctAnswers: 6);

    expect(state.gamesPlayed, 1);
    expect(state.adGameCount, 1);
    expect(state.coins, 3);
    expect(state.achievements['first_win'], isTrue);
    expect(state.operationQuestResultStars, 1);
    expect(
      state.operationQuestProgress
          .bestStars(OperationQuestStageId.additionEasy),
      1,
    );
    expect(
      state.operationQuestProgress
          .isUnlocked(OperationQuestStageId.additionMedium),
      isTrue,
    );
    expect(state.highScores, isEmpty);
    expect(state.currentModal, GameModal.win);
    expect(Storage.containsKey('mc_operationQuestProgress'), isTrue);

    final saved = Storage.getString('mc_operationQuestProgress', '');
    await state.replayGame();
    state.rt.timer?.cancel();
    expect(state.gamesPlayed, 1);
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);
    expect(state.activeRunSnapshot?.operationQuestStageId,
        OperationQuestStageId.additionEasy);

    await state.returnToOperationQuestMap();
    expect(state.gamesPlayed, 1);
    expect(state.currentModal, GameModal.operationQuest);
    expect(state.activeRunSnapshot, isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
      'zero-star completion still counts but unfinished attempt does not',
      (tester) async {
    final unfinished = await _makeState();
    addTearDown(unfinished.dispose);
    unfinished.startOperationQuestStage(OperationQuestStageId.additionEasy);
    unfinished.startGame();
    unfinished.rt.timer?.cancel();
    unfinished.onAnswer(unfinished.rt.q!.ans);
    await unfinished.quitToMenu();
    expect(unfinished.gamesPlayed, 0);
    expect(Storage.containsKey('mc_operationQuestProgress'), isFalse);

    final completed = await _makeState();
    addTearDown(completed.dispose);
    completed.startOperationQuestStage(OperationQuestStageId.additionEasy);
    completed.startGame();
    await _finishQuest(tester, completed, correctAnswers: 0);
    expect(completed.gamesPlayed, 1);
    expect(completed.adGameCount, 1);
    expect(completed.operationQuestResultStars, 0);
    expect(Storage.containsKey('mc_operationQuestProgress'), isFalse);
  });

  testWidgets(
      'Stage 3 clear copy requires a star and lower results are not saved',
      (tester) async {
    final saved = jsonEncode({
      'version': 1,
      'stars': {
        'addition_easy': 3,
        'addition_medium': 3,
        'addition_hard': 3,
      },
    });
    final state = await _makeState({'mc_operationQuestProgress': saved});
    addTearDown(state.dispose);
    state.startOperationQuestStage(OperationQuestStageId.additionHard);
    state.startGame();

    await _finishQuest(tester, state, correctAnswers: 0);

    expect(state.resultTitle, 'Addition Challenge Complete');
    expect(
      state.operationQuestProgress
          .bestStars(OperationQuestStageId.additionHard),
      3,
    );
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);

    await state.replayGame();
    await _finishQuest(tester, state, correctAnswers: 6);

    expect(state.resultTitle, 'Addition Trail Complete');
    expect(
      state.operationQuestProgress
          .bestStars(OperationQuestStageId.additionHard),
      3,
    );
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Campaign card opens locked Addition Trail and starts Stage 1',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    await _pump(
      tester,
      state,
      Stack(children: const [MenuScreen(), ModalRouter()]),
    );

    expect(find.text('Operation Quest'), findsOneWidget);
    await tester.tap(find.text('Operation Quest'));
    await tester.pump();
    expect(find.text('Addition Trail'), findsOneWidget);
    expect(find.text('First Sums'), findsOneWidget);
    expect(find.text('Bigger Sums'), findsOneWidget);
    expect(find.text('Addition Challenge'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('operation-quest-stage-addition_medium')),
    );
    await tester.pump();
    expect(state.currentScreen, GameScreen.menu);

    await tester.tap(
      find.byKey(const Key('operation-quest-stage-addition_easy')),
    );
    await tester.pump();
    expect(state.currentScreen, GameScreen.player);
    expect(state.setupPlayers, 1);
  });

  test('reset removes quest progress and runtime identity', () async {
    final state = await _makeState({
      'mc_operationQuestProgress': jsonEncode({
        'version': 1,
        'stars': {'addition_easy': 2},
      }),
    });
    addTearDown(state.dispose);
    state.startOperationQuestStage(OperationQuestStageId.additionMedium);
    state.startGame();
    state.rt.timer?.cancel();

    await state.resetAllData();

    expect(Storage.containsKey('mc_operationQuestProgress'), isFalse);
    expect(state.operationQuestProgress.stars, isEmpty);
    expect(state.operationQuestResultStars, 0);
    expect(state.activeRunSnapshot, isNull);
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

Future<void> _finishQuest(
  WidgetTester tester,
  GameState state, {
  required int correctAnswers,
}) async {
  for (var i = 0; i < 10; i++) {
    state.rt.timer?.cancel();
    final question = state.rt.q!;
    final answer = i < correctAnswers
        ? question.ans
        : question.choices.firstWhere(
            (choice) => (choice - question.ans).abs() >= 1e-9,
          );
    state.onAnswer(answer);
    await tester.pump(const Duration(milliseconds: 1300));
  }
  await tester.pump();
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
