import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/adaptive/domain/adaptive_difficulty_engine.dart';
import 'package:math_challenge/features/gameplay/domain/question_difficulty_legality.dart';
import 'package:math_challenge/features/operation_quest/domain/operation_quest.dart';
import 'package:math_challenge/models/enums.dart';
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
      questionGenerator: questionGenerator,
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  void startNormal(
    GameState state, {
    Difficulty difficulty = Difficulty.easy,
    bool adaptive = false,
    Operation operation = Operation.addition,
    GameMode mode = GameMode.standard,
  }) {
    state
      ..rt.challenge = operation
      ..mode = mode
      ..diff = difficulty
      ..numType = NumberType.natural
      ..questionCount = 10
      ..adaptive = adaptive
      ..startGame();
    state.rt.timer?.cancel();
  }

  test('player-configured and adaptive legality sets stay explicit', () {
    expect(playerConfigurableDifficulties, const [
      Difficulty.easy,
      Difficulty.medium,
      Difficulty.hard,
    ]);
    expect(playerConfigurableDifficulties, isNot(Difficulty.values));
    expect(
      AdaptiveDifficultyEngine.legalOutputDifficulties,
      const [
        Difficulty.easy,
        Difficulty.medium,
        Difficulty.hard,
        Difficulty.expert,
        Difficulty.insane,
      ],
    );
  });

  test('manual normal runs expose the exact player-configured legality',
      () async {
    final state = await makeState();

    startNormal(state, difficulty: Difficulty.medium);

    expect(state.rt.q!.diff, Difficulty.medium);
    expect(
      state.debugQuestionDifficultyLegality?.route,
      QuestionDifficultyRoute.playerConfigured,
    );
    expect(
      state.debugQuestionDifficultyLegality?.legalDifficulties,
      playerConfigurableDifficultySet,
    );
  });

  test(
      'manual unsupported expert difficulty fails closed without changing gameplay',
      () async {
    final state = await makeState();

    startNormal(state, difficulty: Difficulty.expert);

    expect(state.rt.q!.diff, Difficulty.expert);
    expect(state.debugQuestionDifficultyLegality, isNull);
  });

  test('adaptive legality preserves the full canonical output envelope',
      () async {
    final state = await makeState();
    state.skillMap[Operation.addition.name]!.mastery = 95;

    startNormal(state, adaptive: true);

    expect(state.rt.q!.diff, Difficulty.insane);
    expect(
      state.debugQuestionDifficultyLegality?.route,
      QuestionDifficultyRoute.adaptive,
    );
    expect(
      state.debugQuestionDifficultyLegality?.legalDifficulties,
      adaptiveDifficultySet,
    );
  });

  test('forced routes expose truthful singleton legality', () async {
    final master = await makeState();
    master.startMasterMode();
    master.startGame();
    master.rt.timer?.cancel();
    expect(
      master.debugQuestionDifficultyLegality?.route,
      QuestionDifficultyRoute.masterStage,
    );
    expect(
      master.debugQuestionDifficultyLegality?.legalDifficulties,
      {master.rt.q!.diff!},
    );

    final dailyBoss = await makeState();
    dailyBoss.startDailyBoss();
    dailyBoss.startGame();
    dailyBoss.rt.timer?.cancel();
    expect(
      dailyBoss.debugQuestionDifficultyLegality?.route,
      QuestionDifficultyRoute.dailyBoss,
    );
    expect(
      dailyBoss.debugQuestionDifficultyLegality?.legalDifficulties,
      {dailyBoss.rt.q!.diff!},
    );

    final survival = await makeState();
    startNormal(survival, mode: GameMode.survival);
    expect(
      survival.debugQuestionDifficultyLegality?.route,
      QuestionDifficultyRoute.survivalPhase,
    );
    expect(
      survival.debugQuestionDifficultyLegality?.legalDifficulties,
      {survival.rt.q!.diff!},
    );

    final quest = await makeState();
    quest.startOperationQuestStage(OperationQuestStageId.additionEasy);
    quest.startGame();
    quest.rt.timer?.cancel();
    expect(
      quest.debugQuestionDifficultyLegality?.route,
      QuestionDifficultyRoute.operationQuestStage,
    );
    expect(
      quest.debugQuestionDifficultyLegality?.legalDifficulties,
      {Difficulty.easy},
    );
  });

  test('follow-up route preserves the previous difficulty as a singleton',
      () async {
    final state = await makeState();

    startNormal(state, difficulty: Difficulty.hard);
    final firstQuestion = state.rt.q!;
    final wrongAnswer = firstQuestion.choices
        .firstWhere((choice) => choice != firstQuestion.ans);

    state.onAnswer(wrongAnswer);
    await Future<void>.delayed(const Duration(milliseconds: 1350));

    expect(state.rt.q!.diff, firstQuestion.diff);
    expect(
      state.debugQuestionDifficultyLegality?.route,
      QuestionDifficultyRoute.followUp,
    );
    expect(
      state.debugQuestionDifficultyLegality?.legalDifficulties,
      {firstQuestion.diff!},
    );
  });

  test('legality is unavailable outside an active generated question',
      () async {
    final state = await makeState();
    expect(state.debugQuestionDifficultyLegality, isNull);

    startNormal(state);
    expect(state.debugQuestionDifficultyLegality, isNotNull);

    await state.quitToMenu();
    expect(state.debugQuestionDifficultyLegality, isNull);
  });

  test('querying legality is observational and keeps seeded gameplay identical',
      () async {
    final untouched = await makeState(
      questionGenerator: QuestionGenerator(rng: Random(1408)),
    );
    final queried = await makeState(
      questionGenerator: QuestionGenerator(rng: Random(1408)),
    );

    untouched.skillMap[Operation.addition.name]!.mastery = 82;
    queried.skillMap[Operation.addition.name]!.mastery = 82;

    startNormal(untouched, adaptive: true);
    startNormal(queried, adaptive: true);

    for (var turn = 0; turn < 2; turn++) {
      final legality = queried.debugQuestionDifficultyLegality;
      expect(legality, isNotNull);
      expect(queried.rt.q!.key, untouched.rt.q!.key);
      expect(queried.rt.q!.diff, untouched.rt.q!.diff);
      expect(
        queried.debugQuestionTimerDurationMs(),
        untouched.debugQuestionTimerDurationMs(),
      );

      untouched.onAnswer(untouched.rt.q!.ans);
      queried.onAnswer(queried.rt.q!.ans);

      expect(queried.p[1].score, untouched.p[1].score);
      expect(queried.rt.totalTurns, untouched.rt.totalTurns);
      expect(queried.adaptLvl, untouched.adaptLvl);
      expect(queried.adaptLvlRaw, untouched.adaptLvlRaw);

      if (turn == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1350));
      }
    }
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
