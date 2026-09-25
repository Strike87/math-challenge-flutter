import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/game_brain/study/p1_f01_study_store.dart';
import 'package:math_challenge/features/gameplay/domain/question_mechanic.dart';
import 'package:math_challenge/features/operation_quest/domain/operation_quest.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/features/weak_skills/domain/weak_skills_policy.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TargetClashRunConfig config(Difficulty difficulty) =>
      TargetClashRunConfig.tryCreate(
        operation: Operation.addition,
        difficulty: difficulty,
        numberType: NumberType.natural,
      )!;

  test(
      'V1 config accepts only its fixed operation, difficulty, and number sets',
      () {
    expect(GameRunType.values, [
      GameRunType.normal,
      GameRunType.operationQuest,
      GameRunType.targetClash,
    ]);
    for (final operation in const [
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    ]) {
      expect(
          TargetClashRunConfig.tryCreate(
            operation: operation,
            difficulty: Difficulty.easy,
            numberType: NumberType.natural,
          ),
          isNotNull);
    }
    for (final numberType in const [
      NumberType.natural,
      NumberType.integers,
      NumberType.rationals,
    ]) {
      expect(
        TargetClashRunConfig.tryCreate(
          operation: Operation.addition,
          difficulty: Difficulty.easy,
          numberType: numberType,
        ),
        isNotNull,
      );
    }
    for (final operation in [
      Operation.mixed,
      Operation.master,
      Operation.dailyBoss,
      Operation.survival,
    ]) {
      expect(
          TargetClashRunConfig.tryCreate(
            operation: operation,
            difficulty: Difficulty.easy,
            numberType: NumberType.natural,
          ),
          isNull);
    }
    for (final difficulty in [Difficulty.expert, Difficulty.insane]) {
      expect(
          TargetClashRunConfig.tryCreate(
            operation: Operation.addition,
            difficulty: difficulty,
            numberType: NumberType.natural,
          ),
          isNull);
    }
    expect(
        TargetClashRunConfig.tryCreate(
          operation: Operation.addition,
          difficulty: Difficulty.easy,
          numberType: NumberType.mixed,
        ),
        isNull);
  });

  test('factory mirrors the exact config and fixed carrier envelope', () {
    for (final expected in [
      (Difficulty.easy, 12),
      (Difficulty.medium, 16),
      (Difficulty.hard, 17),
    ]) {
      final value = config(expected.$1);
      final snapshot = GameRunSnapshot.targetClash(value);
      expect(value.profile, TargetClashProfile.v1);
      expect(snapshot.questionTarget, expected.$2);
      expect(snapshot.targetClashConfig, same(value));
      expect(snapshot.hasValidTargetClashEnvelope, isTrue);
      expect(snapshot.mode, GameMode.standard);
      expect(snapshot.answerStyle, AnswerStyle.choice4);
      expect(snapshot.players, 1);
      expect(snapshot.questionMechanic, QuestionMechanic.standard);
      expect(snapshot.timingStyle, TimingStyle.perQuestion);
    }
  });

  test('copies preserve Target Clash identity and cannot make untimed carriers',
      () {
    final value = config(Difficulty.easy);
    final snapshot = GameRunSnapshot.targetClash(value);
    for (final copy in [
      snapshot.withTimingStyle(TimingStyle.perQuestion),
      snapshot.withTimingStyle(TimingStyle.untimed),
      snapshot.withTimingStyle(TimingStyle.timeBank),
      snapshot.withP1AgencyRoute(P1AgencyRoute.replayCarriedConfiguration),
    ]) {
      expect(copy.targetClashConfig, same(value));
      expect(copy.timingStyle, TimingStyle.perQuestion);
      expect(copy.hasValidTargetClashEnvelope, isTrue);
    }
    final normal = GameRunSnapshot(
      runType: GameRunType.normal,
      mode: GameMode.standard,
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      answerStyle: AnswerStyle.choice4,
      players: 1,
      questionTarget: 10,
    );
    expect(normal.withTimingStyle(TimingStyle.untimed).timingStyle,
        TimingStyle.untimed);
  });

  test('structural validation rejects divergent and contaminated snapshots',
      () {
    final value = config(Difficulty.easy);
    GameRunSnapshot malformed({
      Operation operation = Operation.addition,
      Difficulty difficulty = Difficulty.easy,
      NumberType numberType = NumberType.natural,
      GameMode mode = GameMode.standard,
      int players = 1,
      TimingStyle timingStyle = TimingStyle.perQuestion,
      QuestionMechanic mechanic = QuestionMechanic.standard,
      AnswerStyle answerStyle = AnswerStyle.choice4,
      int target = 12,
      TargetClashRunConfig? targetClashConfig,
      WeakSkillsPlan? weakSkillsPlan,
      OperationQuestStageId? operationQuestStageId,
      MentalMathEntry? mentalMathEntry,
      DailyMentalMathProfile? dailyMentalMathProfile,
      List<Operation>? operationPool,
      bool integerQuest = false,
      bool decimalQuest = false,
    }) =>
        GameRunSnapshot(
          runType: GameRunType.targetClash,
          mode: mode,
          operation: operation,
          difficulty: difficulty,
          numberType: numberType,
          answerStyle: answerStyle,
          players: players,
          questionTarget: target,
          timingStyle: timingStyle,
          questionMechanic: mechanic,
          targetClashConfig: targetClashConfig,
          weakSkillsPlan: weakSkillsPlan,
          operationQuestStageId: operationQuestStageId,
          mentalMathEntry: mentalMathEntry,
          dailyMentalMathProfile: dailyMentalMathProfile,
          operationPool: operationPool,
          integerQuest: integerQuest,
          decimalQuest: decimalQuest,
        );
    expect(malformed().hasValidTargetClashEnvelope, isFalse);
    for (final snapshot in [
      malformed(targetClashConfig: value, operation: Operation.subtraction),
      malformed(targetClashConfig: value, difficulty: Difficulty.medium),
      malformed(targetClashConfig: value, numberType: NumberType.integers),
      malformed(targetClashConfig: value, mode: GameMode.blitz),
      malformed(targetClashConfig: value, players: 2),
      malformed(targetClashConfig: value, timingStyle: TimingStyle.untimed),
      malformed(
          targetClashConfig: value,
          mechanic: QuestionMechanic.missingOperation),
      malformed(targetClashConfig: value, answerStyle: AnswerStyle.trueFalse),
      malformed(targetClashConfig: value, target: 10),
      malformed(
        targetClashConfig: value,
        operationQuestStageId: OperationQuestStageId.additionEasy,
      ),
      malformed(
        targetClashConfig: value,
        operationPool: [Operation.addition],
      ),
      malformed(targetClashConfig: value, integerQuest: true),
      malformed(targetClashConfig: value, decimalQuest: true),
      malformed(
        targetClashConfig: value,
        weakSkillsPlan: WeakSkillsPlan(
          isFallback: true,
          operationCycle: [Operation.addition],
        ),
      ),
      malformed(
        targetClashConfig: value,
        mentalMathEntry: MentalMathEntry.freePractice,
      ),
      malformed(
        targetClashConfig: value,
        dailyMentalMathProfile: const DailyMentalMathProfile(
          dateKey: '2026-09-20',
          operation: Operation.addition,
          numberType: NumberType.natural,
          focus: DailyMentalMathFocus.precision,
        ),
      ),
    ]) {
      expect(snapshot.hasValidTargetClashEnvelope, isFalse);
    }
    expect(
        GameRunSnapshot.targetClash(value)
            .withTimingStyle(TimingStyle.untimed)
            .hasValidTargetClashEnvelope,
        isTrue);
    expect(
        GameRunSnapshot(
          runType: GameRunType.normal,
          mode: GameMode.standard,
          operation: Operation.addition,
          difficulty: Difficulty.easy,
          numberType: NumberType.natural,
          answerStyle: AnswerStyle.choice4,
          players: 1,
          questionTarget: 10,
          targetClashConfig: value,
        ).hasValidTargetClashEnvelope,
        isFalse);
  });

  test('controlled Target Clash snapshots bypass the ordinary runtime',
      () async {
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
      questionGenerator: QuestionGenerator(rng: Random(1)),
    );
    addTearDown(state.dispose);
    await state.load();
    state.debugStartGameFromSnapshot(
        GameRunSnapshot.targetClash(config(Difficulty.easy)));
    expect(state.activeRunSnapshot, isNotNull);
    expect(state.rt.gameActive, isTrue);
    expect(state.rt.q, isNull);
    expect(state.isTargetClash, isTrue);
    expect(state.activeAdaptive, isFalse);
    expect(state.debugP1F01IntegrityRunEligible, isFalse);
    expect(state.debugQuestionExperienceObservationCount, 0);
    expect(state.debugContextEvidenceObservationCount, 0);
    await state.quitToMenu();
    expect(state.targetClashRuntime, isNull);
    expect(state.targetClashQuestion, isNull);
    state.debugStartGameFromSnapshot(GameRunSnapshot(
      runType: GameRunType.targetClash,
      mode: GameMode.standard,
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      answerStyle: AnswerStyle.choice4,
      players: 1,
      questionTarget: 12,
    ));
    expect(state.activeRunSnapshot, isNull);
    expect(state.rt.q, isNull);
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
