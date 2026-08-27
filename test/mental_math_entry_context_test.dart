import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/game_brain/integration/adaptive_shadow_integration.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameRunSnapshot snapshot({MentalMathEntry? entry}) => GameRunSnapshot(
        runType: GameRunType.normal,
        mode: GameMode.standard,
        operation: Operation.addition,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
        answerStyle: AnswerStyle.choice4,
        players: 1,
        questionTarget: 10,
        mentalMathEntry: entry,
      );

  Future<GameState> makeState({
    AdaptiveShadowEvaluator? adaptiveShadowEvaluator,
  }) async {
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
      adaptiveShadowEvaluator: adaptiveShadowEvaluator,
    );
    await state.load();
    await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
    await state.setGameBrainPreference(true);
    addTearDown(state.dispose);
    return state;
  }

  test('ordinary snapshots default to no Mental Math entry', () {
    expect(snapshot().mentalMathEntry, isNull);
  });

  test('Mental Math entries are immutable snapshot facts', () {
    for (final entry in MentalMathEntry.values) {
      expect(snapshot(entry: entry).mentalMathEntry, entry);
    }
  });

  test('replay preserves each Mental Math entry', () async {
    for (final entry in MentalMathEntry.values) {
      final state = await makeState();
      state.debugStartGameFromSnapshot(snapshot(entry: entry));
      state.rt.timer?.cancel();

      await state.replayGame();
      state.rt.timer?.cancel();

      expect(state.activeRunSnapshot?.mentalMathEntry, entry);
    }
  });

  test('ordinary run remains eligible and observable', () async {
    var evaluations = 0;
    final state = await makeState(
      adaptiveShadowEvaluator: (_, __) {
        evaluations++;
        return const AdaptiveIntegrationDecision.noAdaptation();
      },
    );
    state.debugStartGameFromSnapshot(snapshot());
    state.rt.timer?.cancel();

    expect(state.debugP1F01IntegrityRunEligible, isTrue);
    state.onAnswer(state.rt.q!.ans);

    expect(state.debugQuestionExperienceObservationCount, 1);
    expect(state.debugContextEvidenceObservationCount, 1);
    expect(state.debugLastContextEvidenceResult, isNotNull);
    expect(evaluations, 1);
  });

  test('Mental Math entries fail closed for P1, QEO, and GameBrain context',
      () async {
    for (final entry in MentalMathEntry.values) {
      var evaluations = 0;
      final state = await makeState(
        adaptiveShadowEvaluator: (_, __) {
          evaluations++;
          return const AdaptiveIntegrationDecision.noAdaptation();
        },
      );
      state.debugStartGameFromSnapshot(snapshot(entry: entry));
      state.rt.timer?.cancel();

      expect(state.debugP1F01IntegrityRunEligible, isFalse, reason: '$entry');
      state.onAnswer(state.rt.q!.ans);

      expect(state.debugQuestionExperienceObservationCount, 0,
          reason: '$entry');
      expect(state.debugContextEvidenceObservationCount, 0, reason: '$entry');
      expect(state.debugLastContextEvidenceResult, isNull, reason: '$entry');
      expect(evaluations, 0, reason: '$entry');
    }
  });

  test('legacy Weak Skills snapshots remain non-Mental Math', () async {
    final state = await makeState();
    state.goToConfig('weakSkills');
    state.continueWeakSkillsSetup();
    state
      ..mode = GameMode.standard
      ..numType = NumberType.natural
      ..diff = Difficulty.easy
      ..questionCount = 10
      ..startGame();
    state.rt.timer?.cancel();

    expect(state.activeRunSnapshot?.weakSkillsPlan, isNotNull);
    expect(state.activeRunSnapshot?.mentalMathEntry, isNull);
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
