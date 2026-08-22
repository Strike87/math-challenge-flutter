import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/game_brain/experience/question_experience_observation.dart';
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

  void startSupported(
    GameState state, {
    bool adaptive = false,
    AnswerStyle answerStyle = AnswerStyle.choice4,
  }) {
    state
      ..rt.challenge = Operation.addition
      ..mode = GameMode.standard
      ..diff = Difficulty.easy
      ..numType = NumberType.natural
      ..questionCount = 10
      ..adaptive = adaptive
      ..selectedAnswerStyle = answerStyle
      ..startGame();
    state.rt.timer?.cancel();
  }

  Future<void> enable(GameState state, FamilyAgeRange range) async {
    await state.submitFamilyAgeRange(range);
    await state.setGameBrainPreference(true);
    expect(state.effectiveGameBrainEnabled, isTrue);
  }

  test('captures each approved answer terminal exactly once', () async {
    for (final expectation in <(String, void Function(GameState), Type)>[
      ('correct', (state) => state.onAnswer(state.rt.q!.ans), AnsweredCorrect),
      (
        'incorrect',
        (state) => state.onAnswer(state.rt.q!.choices.firstWhere(
              (value) => value != state.rt.q!.ans,
            )),
        AnsweredIncorrect,
      ),
      ('timeout', (state) => state.debugTimeoutForTest(), QuestionTimedOut),
      ('skip', (state) => state.skip(), QuestionSkipped),
    ]) {
      final state = await makeState();
      await enable(state, FamilyAgeRange.adult18plus);
      startSupported(state);

      expectation.$2(state);
      expectation.$2(state);

      expect(state.debugQuestionExperienceObservationCount, 1,
          reason: expectation.$1);
      expect(state.debugQuestionExperienceObservations.single.terminal.runtimeType,
          expectation.$3);
    }
  });

  test('captures an accepted switch replacement only once', () async {
    final state = await makeState();
    await enable(state, FamilyAgeRange.adult18plus);
    startSupported(state);
    state.p[1].pups.add(PowerUp.switchOp);

    state.usePowerUp(PowerUp.switchOp);
    state.usePowerUp(PowerUp.switchOp);

    expect(state.debugQuestionExperienceObservationCount, 1);
    expect(state.debugQuestionExperienceObservations.single.terminal,
        isA<QuestionReplaced>());
  });

  test('adult correct capture preserves canonical presented fields', () async {
    final state = await makeState();
    await enable(state, FamilyAgeRange.adult18plus);
    startSupported(state);
    final question = state.rt.q!;

    state.onAnswer(question.ans);

    final observation = state.debugQuestionExperienceObservations.single;
    expect(observation.terminal, isA<AnsweredCorrect>());
    expect(observation.presented.operation, question.type);
    expect(observation.presented.numberType, question.numType);
    expect(observation.presented.difficulty, question.diff);
    expect(observation.presented.answerStyle, AnswerStyle.choice4);
  });

  test('uses completion-time GameBrain eligibility while BRAIN-07 stays live',
      () async {
    final offAtCompletion = await makeState();
    await enable(offAtCompletion, FamilyAgeRange.adult18plus);
    startSupported(offAtCompletion);
    await offAtCompletion.setGameBrainPreference(false);
    offAtCompletion.onAnswer(offAtCompletion.rt.q!.ans);
    expect(offAtCompletion.debugQuestionExperienceObservationCount, 0);
    expect(offAtCompletion.debugContextEvidenceObservationCount, 1);

    final onAtCompletion = await makeState();
    startSupported(onAtCompletion);
    await enable(onAtCompletion, FamilyAgeRange.adult18plus);
    onAtCompletion.onAnswer(onAtCompletion.rt.q!.ans);
    expect(onAtCompletion.debugQuestionExperienceObservationCount, 1);
    expect(onAtCompletion.debugContextEvidenceObservationCount, 1);
  });

  test('age eligibility fails closed while eligible teens and adults capture',
      () async {
    for (final expectation in <(FamilyAgeRange?, bool)>[
      (null, false),
      (FamilyAgeRange.under13, false),
      (FamilyAgeRange.teen13to17, true),
      (FamilyAgeRange.adult18plus, true),
    ]) {
      final state = await makeState();
      if (expectation.$1 != null) {
        await state.submitFamilyAgeRange(expectation.$1!);
      }
      await state.setGameBrainPreference(true);
      startSupported(state);
      state.onAnswer(state.rt.q!.ans);

      expect(state.debugQuestionExperienceObservationCount,
          expectation.$2 ? 1 : 0);
      expect(state.debugContextEvidenceObservationCount, 1);
    }
  });

  test('deferred True/False and two-player contexts do not capture', () async {
    final trueFalse = await makeState();
    await enable(trueFalse, FamilyAgeRange.adult18plus);
    startSupported(trueFalse, answerStyle: AnswerStyle.trueFalse);
    trueFalse.onTrueFalseAnswer(trueFalse.rt.proposedTruth!);
    expect(trueFalse.debugQuestionExperienceObservationCount, 0);

    final twoPlayer = await makeState();
    await enable(twoPlayer, FamilyAgeRange.adult18plus);
    twoPlayer
      ..players = 2
      ..rt.challenge = Operation.addition
      ..mode = GameMode.standard
      ..diff = Difficulty.easy
      ..numType = NumberType.natural
      ..questionCount = 10
      ..startGame();
    twoPlayer.rt.timer?.cancel();
    twoPlayer.onAnswer(twoPlayer.rt.q!.ans);
    expect(twoPlayer.debugQuestionExperienceObservationCount, 0);
  });

  test('new runs, replay, and new states retain no prior observations',
      () async {
    final state = await makeState();
    await enable(state, FamilyAgeRange.adult18plus);
    startSupported(state);
    state.onAnswer(state.rt.q!.ans);
    expect(state.debugQuestionExperienceObservationCount, 1);

    state.startGame();
    state.rt.timer?.cancel();
    expect(state.debugQuestionExperienceObservationCount, 0);
    await state.replayGame();
    state.rt.timer?.cancel();
    expect(state.debugQuestionExperienceObservationCount, 0);

    final newState = await makeState();
    expect(newState.debugQuestionExperienceObservationCount, 0);
  });

  test('neutral quit never creates a QuestionAbandoned observation', () async {
    final state = await makeState();
    await enable(state, FamilyAgeRange.adult18plus);
    startSupported(state);

    await state.quitToMenu();

    expect(state.debugQuestionExperienceObservations, isEmpty);
  });

  test('capture is observation-only and leaves seeded questions unchanged',
      () async {
    final off = await makeState(
      questionGenerator: QuestionGenerator(rng: Random(1408)),
    );
    final on = await makeState(
      questionGenerator: QuestionGenerator(rng: Random(1408)),
    );
    await enable(on, FamilyAgeRange.adult18plus);
    startSupported(off, adaptive: true);
    startSupported(on, adaptive: true);

    for (var turn = 0; turn < 2; turn++) {
      expect(on.rt.q!.key, off.rt.q!.key);
      off.onAnswer(off.rt.q!.ans);
      on.onAnswer(on.rt.q!.ans);
      expect(on.p[1].score, off.p[1].score);
      expect(on.rt.totalTurns, off.rt.totalTurns);
      if (turn == 0) await Future<void>.delayed(const Duration(milliseconds: 1350));
    }
    expect(off.debugQuestionExperienceObservationCount, 0);
    expect(on.debugQuestionExperienceObservationCount, 2);
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
