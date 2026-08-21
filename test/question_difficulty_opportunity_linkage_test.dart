import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/game_brain/experience/question_experience_observation.dart';
import 'package:math_challenge/features/game_brain/experience/run_local_question_difficulty_measurement_collector.dart';
import 'package:math_challenge/features/gameplay/domain/question_difficulty_legality.dart';
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

  Future<void> startSupported(GameState state) async {
    await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
    await state.setGameBrainPreference(true);
    state
      ..rt.challenge = Operation.addition
      ..mode = GameMode.standard
      ..diff = Difficulty.easy
      ..numType = NumberType.natural
      ..questionCount = 10
      ..startGame();
    state.rt.timer?.cancel();
  }

  void startNormalWithoutQeo(GameState state) {
    state
      ..rt.challenge = Operation.addition
      ..mode = GameMode.standard
      ..diff = Difficulty.easy
      ..numType = NumberType.natural
      ..questionCount = 10
      ..startGame();
    state.rt.timer?.cancel();
  }

  test('opportunities use canonical identity and ordinal within a run',
      () async {
    final state = await makeState();
    await startSupported(state);

    final first = state.debugQuestionDifficultyMeasurementOpportunities.single;
    expect(first.opportunityOrdinalWithinRun, 1);
    expect(identical(first.legality, state.debugQuestionDifficultyLegality),
        isTrue);
    expect(first.runId, greaterThan(0));
    expect(first.questionId, greaterThan(0));

    state.onAnswer(state.rt.q!.ans);
    await Future<void>.delayed(const Duration(milliseconds: 1350));
    final opportunities = state.debugQuestionDifficultyMeasurementOpportunities;
    expect(opportunities.length, 2);
    expect(opportunities.last.opportunityOrdinalWithinRun, 2);
    expect(opportunities.last.runId, first.runId);
    expect(opportunities.last.questionId, isNot(first.questionId));
  });

  test('collector links the supplied token, not the latest identical record',
      () {
    final collector = RunLocalQuestionDifficultyMeasurementCollector();
    final legality = QuestionDifficultyLegality(
      route: QuestionDifficultyRoute.playerConfigured,
      resolvedDifficulty: Difficulty.easy,
      legalDifficulties: {Difficulty.easy, Difficulty.medium, Difficulty.hard},
    );
    const firstToken = (runId: 1, questionId: 1);
    const secondToken = (runId: 1, questionId: 2);
    const observation = QuestionExperienceObservation(
      presented: QuestionPresentedSnapshot(
        operation: Operation.addition,
        numberType: NumberType.natural,
        difficulty: Difficulty.easy,
        answerStyle: AnswerStyle.choice4,
      ),
      terminal: AnsweredCorrect(),
    );

    collector
      ..add(legality, firstToken)
      ..add(legality, secondToken);

    expect(collector.link(firstToken, observation), isTrue);
    expect(
        identical(collector.opportunities[0].terminalObservation, observation),
        isTrue);
    expect(collector.opportunities[1].terminalObservation, isNull);
  });

  test('collector cannot link a stale token after run-local clear', () {
    final collector = RunLocalQuestionDifficultyMeasurementCollector();
    const staleToken = (runId: 1, questionId: 1);
    const observation = QuestionExperienceObservation(
      presented: QuestionPresentedSnapshot(
        operation: Operation.addition,
        numberType: NumberType.natural,
        difficulty: Difficulty.easy,
        answerStyle: AnswerStyle.choice4,
      ),
      terminal: AnsweredCorrect(),
    );
    collector.add(null, staleToken);

    collector.clear();

    expect(collector.link(staleToken, observation), isFalse);
    expect(collector.opportunities, isEmpty);
  });

  test('each accepted terminal links its exact opportunity once', () async {
    for (final terminal in <(String, void Function(GameState), Type)>[
      ('correct', (state) => state.onAnswer(state.rt.q!.ans), AnsweredCorrect),
      (
        'incorrect',
        (state) => state.onAnswer(state.rt.q!.choices.firstWhere(
              (choice) => choice != state.rt.q!.ans,
            )),
        AnsweredIncorrect,
      ),
      ('timeout', (state) => state.debugTimeoutForTest(), QuestionTimedOut),
      ('skip', (state) => state.skip(), QuestionSkipped),
    ]) {
      final state = await makeState();
      await startSupported(state);
      final opportunity =
          state.debugQuestionDifficultyMeasurementOpportunities.single;

      terminal.$2(state);
      terminal.$2(state);

      final linked =
          state.debugQuestionDifficultyMeasurementOpportunities.single;
      expect(linked.questionId, opportunity.questionId, reason: terminal.$1);
      expect(linked.terminalObservation, isNotNull, reason: terminal.$1);
      expect(linked.terminalObservation!.terminal.runtimeType, terminal.$3,
          reason: terminal.$1);
      expect(
          identical(linked.terminalObservation,
              state.debugQuestionExperienceObservations.single),
          isTrue);
      expect(state.debugQuestionExperienceObservationCount, 1);
    }
  });

  test('accepted switch replacement links only the replaced question',
      () async {
    final state = await makeState();
    await startSupported(state);
    final replaced =
        state.debugQuestionDifficultyMeasurementOpportunities.single;
    state.p[1].pups.add(PowerUp.switchOp);

    state.usePowerUp(PowerUp.switchOp);
    state.usePowerUp(PowerUp.switchOp);

    final linked = state.debugQuestionDifficultyMeasurementOpportunities.single;
    expect(linked.questionId, replaced.questionId);
    expect(linked.terminalObservation?.terminal, isA<QuestionReplaced>());
    expect(state.debugQuestionExperienceObservationCount, 1);
  });

  test('identical contexts link only the matching canonical token', () async {
    final state = await makeState(
      questionGenerator: QuestionGenerator(rng: Random(1408)),
    );
    startNormalWithoutQeo(state);
    final first = state.debugQuestionDifficultyMeasurementOpportunities.single;
    final firstQuestion = state.rt.q!;

    state.onAnswer(state.rt.q!.ans);
    await Future<void>.delayed(const Duration(milliseconds: 1350));
    await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
    await state.setGameBrainPreference(true);
    final second = state.debugQuestionDifficultyMeasurementOpportunities.last;
    final secondQuestion = state.rt.q!;
    expect(secondQuestion.type, firstQuestion.type);
    expect(secondQuestion.numType, firstQuestion.numType);
    expect(secondQuestion.diff, firstQuestion.diff);
    expect(second.legality?.resolvedDifficulty,
        first.legality?.resolvedDifficulty);
    expect(second.legality?.route, first.legality?.route);

    state.onAnswer(secondQuestion.ans);
    final opportunities = state.debugQuestionDifficultyMeasurementOpportunities;
    expect(opportunities[0].terminalObservation, isNull);
    expect(opportunities[1].terminalObservation, isNotNull);
    expect(opportunities[0].questionId, isNot(opportunities[1].questionId));
    expect(
      identical(
        opportunities[1].terminalObservation,
        state.debugQuestionExperienceObservations.single,
      ),
      isTrue,
    );
  });

  test('null legality and neutral quit remain unlinked without reconstruction',
      () async {
    final state = await makeState();
    await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
    await state.setGameBrainPreference(true);
    state
      ..rt.challenge = Operation.addition
      ..mode = GameMode.standard
      ..diff = Difficulty.expert
      ..numType = NumberType.natural
      ..questionCount = 10
      ..startGame();
    state.rt.timer?.cancel();
    expect(
        state.debugQuestionDifficultyMeasurementOpportunities.single.legality,
        isNull);

    await state.quitToMenu();
    expect(state.debugQuestionDifficultyMeasurementOpportunities, isEmpty);
    expect(state.debugQuestionExperienceObservations, isEmpty);
  });

  test('new runs and replay discard stale opportunity tokens', () async {
    final state = await makeState();
    await startSupported(state);
    final stale = state.debugQuestionDifficultyMeasurementOpportunities.single;
    state.p[1].pups.add(PowerUp.switchOp);
    state.usePowerUp(PowerUp.switchOp);
    await state.replayGame();
    state.rt.timer?.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final restarted =
        state.debugQuestionDifficultyMeasurementOpportunities.single;
    expect(restarted.opportunityOrdinalWithinRun, 1);
    expect(restarted.runId, isNot(stale.runId));
    expect(restarted.questionId, isNot(stale.questionId));
    expect(restarted.terminalObservation, isNull);
    expect(state.debugQuestionExperienceObservations, isEmpty);
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
