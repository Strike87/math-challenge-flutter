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

  test('domain defines all trails, explicit unlocks, and safe progress JSON',
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
        (
          'First Differences',
          Difficulty.easy,
          Operation.subtraction,
          NumberType.natural,
          10
        ),
        (
          'Bigger Differences',
          Difficulty.medium,
          Operation.subtraction,
          NumberType.natural,
          10
        ),
        (
          'Subtraction Challenge',
          Difficulty.hard,
          Operation.subtraction,
          NumberType.natural,
          10
        ),
        (
          'Times Table Start',
          Difficulty.easy,
          Operation.multiplication,
          NumberType.natural,
          10
        ),
        (
          'Product Climb',
          Difficulty.medium,
          Operation.multiplication,
          NumberType.natural,
          10
        ),
        (
          'Multiplication Challenge',
          Difficulty.hard,
          Operation.multiplication,
          NumberType.natural,
          10
        ),
        (
          'Sharing Basics',
          Difficulty.easy,
          Operation.division,
          NumberType.natural,
          10
        ),
        (
          'Quotient Climb',
          Difficulty.medium,
          Operation.division,
          NumberType.natural,
          10
        ),
        (
          'Division Challenge',
          Difficulty.hard,
          Operation.division,
          NumberType.natural,
          10
        ),
        ('Mix It Up', Difficulty.easy, Operation.mixed, NumberType.natural, 10),
        (
          'Operation Switch',
          Difficulty.medium,
          Operation.mixed,
          NumberType.natural,
          10
        ),
        (
          'Mixed Challenge',
          Difficulty.hard,
          Operation.mixed,
          NumberType.natural,
          10
        ),
      ],
    );
    expect(
      OperationQuestStageId.values.map((id) => id.storageId),
      [
        'addition_easy',
        'addition_medium',
        'addition_hard',
        'subtraction_easy',
        'subtraction_medium',
        'subtraction_hard',
        'multiplication_easy',
        'multiplication_medium',
        'multiplication_hard',
        'division_easy',
        'division_medium',
        'division_hard',
        'mixed_easy',
        'mixed_medium',
        'mixed_hard',
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
        'addition_hard': 1,
        'subtraction_easy': 2,
        'subtraction_medium': 1,
        'subtraction_hard': 1,
        'multiplication_easy': 2,
        'multiplication_medium': 1,
        'multiplication_hard': 1,
        'division_easy': 2,
        'division_medium': 1,
        'division_hard': 1,
        'mixed_easy': 2,
        'mixed_medium': 1,
        'mixed_hard': 1,
        'unknown': 3,
      },
    }));
    expect(progress.bestStars(OperationQuestStageId.additionEasy), 3);
    expect(progress.bestStars(OperationQuestStageId.additionMedium), 0);
    expect(progress.isUnlocked(OperationQuestStageId.additionMedium), isTrue);
    expect(progress.isUnlocked(OperationQuestStageId.additionHard), isFalse);
    expect(progress.isUnlocked(OperationQuestStageId.subtractionEasy), isTrue);
    expect(
      progress.isUnlocked(OperationQuestStageId.subtractionMedium),
      isTrue,
    );
    expect(progress.isUnlocked(OperationQuestStageId.subtractionHard), isTrue);
    expect(
        progress.isUnlocked(OperationQuestStageId.multiplicationEasy), isTrue);
    expect(progress.isUnlocked(OperationQuestStageId.multiplicationMedium),
        isTrue);
    expect(
        progress.isUnlocked(OperationQuestStageId.multiplicationHard), isTrue);
    expect(progress.isUnlocked(OperationQuestStageId.divisionEasy), isTrue);
    expect(progress.isUnlocked(OperationQuestStageId.divisionMedium), isTrue);
    expect(progress.isUnlocked(OperationQuestStageId.divisionHard), isTrue);
    expect(progress.isUnlocked(OperationQuestStageId.mixedEasy), isTrue);
    expect(progress.isUnlocked(OperationQuestStageId.mixedMedium), isTrue);
    expect(progress.isUnlocked(OperationQuestStageId.mixedHard), isTrue);
    expect(
      OperationQuestProgress({
        OperationQuestStageId.additionHard: 1,
      }).isUnlocked(OperationQuestStageId.subtractionMedium),
      isFalse,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.subtractionMedium: 3,
      }).isUnlocked(OperationQuestStageId.multiplicationEasy),
      isFalse,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.subtractionHard: 1,
      }).isUnlocked(OperationQuestStageId.multiplicationMedium),
      isFalse,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.multiplicationMedium: 3,
      }).isUnlocked(OperationQuestStageId.divisionEasy),
      isFalse,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.multiplicationHard: 1,
      }).isUnlocked(OperationQuestStageId.divisionEasy),
      isTrue,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.divisionEasy: 1,
      }).isUnlocked(OperationQuestStageId.divisionMedium),
      isTrue,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.divisionMedium: 1,
      }).isUnlocked(OperationQuestStageId.divisionHard),
      isTrue,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.divisionMedium: 3,
      }).isUnlocked(OperationQuestStageId.mixedEasy),
      isFalse,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.divisionHard: 1,
      }).isUnlocked(OperationQuestStageId.mixedEasy),
      isTrue,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.divisionHard: 1,
      }).isUnlocked(OperationQuestStageId.mixedMedium),
      isFalse,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.mixedEasy: 1,
      }).isUnlocked(OperationQuestStageId.mixedMedium),
      isTrue,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.mixedMedium: 1,
      }).isUnlocked(OperationQuestStageId.mixedHard),
      isTrue,
    );
    expect(
      OperationQuestProgress({
        OperationQuestStageId.mixedEasy: 1,
      }).isUnlocked(OperationQuestStageId.mixedHard),
      isFalse,
    );
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

  test('legacy one- through four-trail progress keeps Mixed empty', () {
    for (final rawStars in [
      {'addition_easy': 1},
      {'addition_easy': 1, 'subtraction_easy': 1},
      {
        'addition_easy': 1,
        'subtraction_easy': 1,
        'multiplication_easy': 1,
      },
      {
        'addition_easy': 1,
        'subtraction_easy': 1,
        'multiplication_easy': 1,
        'division_easy': 1,
      },
    ]) {
      final progress = OperationQuestProgress.decode(jsonEncode({
        'version': 1,
        'stars': rawStars,
      }));
      expect(progress.bestStars(OperationQuestStageId.mixedEasy), 0);
      expect(progress.bestStars(OperationQuestStageId.mixedMedium), 0);
      expect(progress.bestStars(OperationQuestStageId.mixedHard), 0);
    }
  });

  test('quest snapshot leaves normal preferences untouched and drives replay',
      () async {
    final state = await _makeState({
      'mc_operationQuestProgress': jsonEncode({
        'version': 1,
        'stars': {
          'addition_hard': 1,
          'subtraction_easy': 1,
          'subtraction_medium': 1,
          'subtraction_hard': 1,
          'multiplication_easy': 1,
          'multiplication_medium': 1,
          'multiplication_hard': 1,
          'division_easy': 1,
          'division_medium': 1,
          'division_hard': 1,
          'mixed_easy': 1,
          'mixed_medium': 1,
        },
      }),
    });
    addTearDown(state.dispose);
    state
      ..players = 2
      ..mode = GameMode.combo
      ..diff = Difficulty.insane
      ..numType = NumberType.rationals
      ..questionCount = 20
      ..adaptive = true
      ..selectedAnswerStyle = AnswerStyle.trueFalse;

    state.startOperationQuestStage(OperationQuestStageId.mixedHard);
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
    expect(state.activeDifficulty, Difficulty.hard);
    expect(state.activeNumberType, NumberType.natural);
    expect(state.activeQuestionTarget, 10);
    expect(state.rt.answerStyle, AnswerStyle.choice4);
    expect(state.activeAdaptive, isFalse);
    expect(state.activeRunSnapshot?.operation, Operation.mixed);
    expect(
      state.rt.q?.type,
      isIn([
        Operation.addition,
        Operation.subtraction,
        Operation.multiplication,
        Operation.division,
      ]),
    );

    await state.replayGame();
    state.rt.timer?.cancel();
    expect(state.activeRunSnapshot?.operationQuestStageId,
        OperationQuestStageId.mixedHard);
    expect(state.activeDifficulty, Difficulty.hard);
    expect(state.mode, GameMode.combo);
    expect(state.diff, Difficulty.insane);
  });

  testWidgets('Division Quest answers use the shared Standard answer pipeline',
      (tester) async {
    final state = await _makeState({
      'mc_operationQuestProgress': jsonEncode({
        'version': 1,
        'stars': {'multiplication_hard': 1},
      }),
    });
    addTearDown(state.dispose);
    state.dailyChallengeIds = ['streak_7', 'perfect_5', 'division_10'];
    final initialSkill = state.skillMap[Operation.division.name]!;
    final initialCount = initialSkill.count;
    final initialCorrect = initialSkill.correct;
    final initialMastery = initialSkill.mastery;

    state.startOperationQuestStage(OperationQuestStageId.divisionEasy);
    state.startGame();

    expect(state.activeMode, GameMode.standard);
    expect(state.rt.answerStyle, AnswerStyle.choice4);
    expect(state.rt.qTimerLimit,
        GameConfig.timerBaseMs[Difficulty.easy.name]! ~/ 1000);

    state.rt.qStartTs = DateTime.now().millisecondsSinceEpoch - 5000;
    state.onAnswer(state.rt.q!.ans);

    expect(state.p[1].score, GameConfig.scoreBase + 5);
    expect(state.p[1].history, hasLength(1));
    expect(state.p[1].history.single.type, Operation.division);
    expect(state.p[1].history.single.correct, isTrue);
    final updatedSkill = state.skillMap[Operation.division.name]!;
    expect(updatedSkill.count, initialCount + 1);
    expect(updatedSkill.correct, initialCorrect + 1);
    expect(updatedSkill.mastery, greaterThan(initialMastery));
    expect(state.dailyProgress['streak_7'], 1);
    expect(state.dailyProgress['perfect_5'], 1);
    expect(state.dailyProgress['division_10'], 1);
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

  testWidgets(
      'Subtraction Stage 3 copy uses current stars and best stars do not decrease',
      (tester) async {
    final saved = jsonEncode({
      'version': 1,
      'stars': {
        'addition_hard': 3,
        'subtraction_easy': 3,
        'subtraction_medium': 3,
        'subtraction_hard': 3,
      },
    });
    final state = await _makeState({'mc_operationQuestProgress': saved});
    addTearDown(state.dispose);
    final initialCount = state.skillMap[Operation.subtraction.name]!.count;

    state.startOperationQuestStage(OperationQuestStageId.subtractionHard);
    state.startGame();
    await _finishQuest(tester, state, correctAnswers: 0);

    expect(state.resultTitle, 'Subtraction Challenge Complete');
    expect(
      state.operationQuestProgress
          .bestStars(OperationQuestStageId.subtractionHard),
      3,
    );
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);

    await state.replayGame();
    await _finishQuest(tester, state, correctAnswers: 6);

    expect(state.resultTitle, 'Subtraction Trail Complete');
    expect(
      state.p[1].history.every(
        (attempt) => attempt.type == Operation.subtraction,
      ),
      isTrue,
    );
    expect(
      state.skillMap[Operation.subtraction.name]!.count,
      initialCount + 20,
    );
    expect(state.highScores, isEmpty);
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Multiplication Stage 3 copy and history use the Quest snapshot',
      (tester) async {
    final saved = jsonEncode({
      'version': 1,
      'stars': {
        'subtraction_hard': 3,
        'multiplication_easy': 3,
        'multiplication_medium': 3,
        'multiplication_hard': 3,
      },
    });
    final state = await _makeState({'mc_operationQuestProgress': saved});
    addTearDown(state.dispose);
    final initialCount = state.skillMap[Operation.multiplication.name]!.count;

    state.startOperationQuestStage(OperationQuestStageId.multiplicationHard);
    state.startGame();
    await _finishQuest(tester, state, correctAnswers: 0);

    expect(state.resultIcon, '✖️');
    expect(state.resultTitle, 'Multiplication Challenge Complete');
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);

    await state.replayGame();
    await _finishQuest(tester, state, correctAnswers: 6);

    expect(state.resultIcon, '⭐');
    expect(state.resultTitle, 'Multiplication Trail Complete');
    expect(
      state.p[1].history.every(
        (attempt) => attempt.type == Operation.multiplication,
      ),
      isTrue,
    );
    expect(
      state.skillMap[Operation.multiplication.name]!.count,
      initialCount + 20,
    );
    expect(state.highScores, isEmpty);
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Division Stage 3 copy, icon, and history use the Quest snapshot',
      (tester) async {
    final saved = jsonEncode({
      'version': 1,
      'stars': {
        'multiplication_hard': 3,
        'division_easy': 3,
        'division_medium': 3,
        'division_hard': 3,
      },
    });
    final state = await _makeState({'mc_operationQuestProgress': saved});
    addTearDown(state.dispose);
    final initialCount = state.skillMap[Operation.division.name]!.count;

    state.startOperationQuestStage(OperationQuestStageId.divisionHard);
    state.startGame();
    await _finishQuest(tester, state, correctAnswers: 0);

    expect(state.resultIcon, '➗');
    expect(state.resultTitle, 'Division Challenge Complete');
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);

    await state.replayGame();
    await _finishQuest(tester, state, correctAnswers: 6);

    expect(state.resultIcon, '⭐');
    expect(state.resultTitle, 'Division Trail Complete');
    expect(
      state.p[1].history.every(
        (attempt) => attempt.type == Operation.division,
      ),
      isTrue,
    );
    expect(
      state.skillMap[Operation.division.name]!.count,
      initialCount + 20,
    );
    expect(state.highScores, isEmpty);
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
      'Mixed Stage 3 resolves concrete questions and keeps shared progress behavior',
      (tester) async {
    final saved = jsonEncode({
      'version': 1,
      'stars': {
        'division_hard': 3,
        'mixed_easy': 3,
        'mixed_medium': 3,
        'mixed_hard': 3,
      },
    });
    final state = await _makeState({'mc_operationQuestProgress': saved});
    addTearDown(state.dispose);
    state.dailyChallengeIds = ['division_10'];
    final initialTotalSkillCount = [
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    ].fold(
        0, (total, operation) => total + state.skillMap[operation.name]!.count);

    state.startOperationQuestStage(OperationQuestStageId.mixedHard);
    state.startGame();
    await _finishQuest(tester, state, correctAnswers: 0);

    expect(state.resultIcon, '🧮');
    expect(state.resultTitle, 'Mixed Challenge Complete');
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);

    await state.replayGame();
    await _finishQuest(tester, state, correctAnswers: 6);

    expect(state.resultIcon, '⭐');
    expect(state.resultTitle, 'Mixed Operations Trail Complete');
    final history = state.p[1].history;
    const concreteOperations = {
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    };
    expect(history, hasLength(10));
    expect(
        history.every((attempt) => concreteOperations.contains(attempt.type)),
        isTrue);
    expect(
      concreteOperations.fold(
        0,
        (total, operation) => total + state.skillMap[operation.name]!.count,
      ),
      initialTotalSkillCount + 20,
    );
    expect(
      state.dailyProgress['division_10'],
      history
          .where((attempt) =>
              attempt.correct && attempt.type == Operation.division)
          .length,
    );
    expect(state.highScores, isEmpty);
    expect(Storage.getString('mc_operationQuestProgress', ''), saved);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Campaign card shows all trails and locked stages do not start',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    await _pump(
      tester,
      state,
      Stack(children: const [MenuScreen(), ModalRouter()]),
    );

    expect(find.text('Operation Quest'), findsOneWidget);
    expect(find.text('5 TRAILS • 15 STAGES'), findsOneWidget);
    await tester.tap(find.text('Operation Quest'));
    await tester.pump();
    expect(find.text('➕ Addition Trail'), findsOneWidget);
    expect(find.text('➖ Subtraction Trail'), findsOneWidget);
    expect(find.text('✖️ Multiplication Trail'), findsOneWidget);
    expect(find.text('➗ Division Trail'), findsOneWidget);
    expect(find.text('🧮 Mixed Operations Trail'), findsOneWidget);
    expect(find.text('First Sums'), findsOneWidget);
    expect(find.text('Bigger Sums'), findsOneWidget);
    expect(find.text('Addition Challenge'), findsOneWidget);
    expect(find.text('First Differences'), findsOneWidget);
    expect(find.text('Bigger Differences'), findsOneWidget);
    expect(find.text('Subtraction Challenge'), findsOneWidget);
    expect(find.text('Times Table Start'), findsOneWidget);
    expect(find.text('Product Climb'), findsOneWidget);
    expect(find.text('Multiplication Challenge'), findsOneWidget);
    expect(find.text('Sharing Basics'), findsOneWidget);
    expect(find.text('Quotient Climb'), findsOneWidget);
    expect(find.text('Division Challenge'), findsOneWidget);
    expect(find.text('Mix It Up'), findsOneWidget);
    expect(find.text('Operation Switch'), findsOneWidget);
    expect(find.text('Mixed Challenge'), findsOneWidget);
    expect(find.text('🔒'), findsNWidgets(14));

    state.startOperationQuestStage(OperationQuestStageId.subtractionEasy);
    expect(state.currentScreen, GameScreen.menu);
    state.startOperationQuestStage(OperationQuestStageId.multiplicationEasy);
    expect(state.currentScreen, GameScreen.menu);
    state.startOperationQuestStage(OperationQuestStageId.divisionEasy);
    expect(state.currentScreen, GameScreen.menu);
    state.startOperationQuestStage(OperationQuestStageId.mixedEasy);
    expect(state.currentScreen, GameScreen.menu);

    await tester.tap(
      find.byKey(const Key('operation-quest-stage-addition_medium')),
    );
    await tester.pump();
    expect(state.currentScreen, GameScreen.menu);

    final multiplicationEasy = find.byKey(
      const Key('operation-quest-stage-multiplication_easy'),
    );
    await tester.ensureVisible(multiplicationEasy);
    await tester.tap(multiplicationEasy);
    await tester.pump();
    expect(state.currentScreen, GameScreen.menu);

    final divisionEasy = find.byKey(
      const Key('operation-quest-stage-division_easy'),
    );
    await tester.ensureVisible(divisionEasy);
    await tester.tap(divisionEasy);
    await tester.pump();
    expect(state.currentScreen, GameScreen.menu);

    final mixedEasy = find.byKey(
      const Key('operation-quest-stage-mixed_easy'),
    );
    await tester.ensureVisible(mixedEasy);
    await tester.tap(mixedEasy);
    await tester.pump();
    expect(state.currentScreen, GameScreen.menu);

    await tester.ensureVisible(
      find.byKey(const Key('operation-quest-stage-addition_easy')),
    );
    await tester.tap(
      find.byKey(const Key('operation-quest-stage-addition_easy')),
    );
    await tester.pump();
    expect(state.currentScreen, GameScreen.player);
    expect(state.setupPlayers, 1);
  });

  testWidgets('Quest map scrolls with compact high-text-scale layout',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    state.showOperationQuest();
    await _pump(
      tester,
      state,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: const ModalRouter(),
      ),
      size: const Size(390, 480),
    );

    final scrollable = find.byType(Scrollable).first;
    final scrollState = tester.state<ScrollableState>(scrollable);
    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pump();
    expect(scrollState.position.pixels, greaterThan(0));
    await tester.ensureVisible(find.text('Mixed Challenge'));
    expect(find.text('Close').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
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
  Widget child, {
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
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
