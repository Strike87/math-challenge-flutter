import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
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

  void startNormal(
    GameState state, {
    Difficulty difficulty = Difficulty.easy,
    bool adaptive = false,
    GameMode mode = GameMode.standard,
  }) {
    state
      ..rt.challenge = Operation.addition
      ..mode = mode
      ..diff = difficulty
      ..numType = NumberType.natural
      ..questionCount = 10
      ..adaptive = adaptive
      ..startGame();
    state.rt.timer?.cancel();
  }

  test('manual measurement retains the canonical legality reference', () async {
    final state = await makeState();
    startNormal(state, difficulty: Difficulty.medium);

    final measured = state.debugQuestionDifficultyMeasurements.single;
    final canonical = state.debugQuestionDifficultyLegality;
    expect(identical(measured, canonical), isTrue);
    expect(measured?.route, QuestionDifficultyRoute.playerConfigured);
    expect(measured?.resolvedDifficulty, Difficulty.medium);
    expect(
      measured?.legalDifficulties,
      playerConfigurableDifficultySet,
    );
  });

  test('adaptive measurement retains the canonical full envelope', () async {
    for (final expected in <(double, Difficulty)>[
      (82, Difficulty.expert),
      (93, Difficulty.insane),
    ]) {
      final state = await makeState();
      state.skillMap[Operation.addition.name]!.mastery = expected.$1;
      startNormal(state, adaptive: true);

      final measured = state.debugQuestionDifficultyMeasurements.single;
      expect(
          identical(measured, state.debugQuestionDifficultyLegality), isTrue);
      expect(measured?.resolvedDifficulty, expected.$2);
      expect(measured?.route, QuestionDifficultyRoute.adaptive);
      expect(measured?.legalDifficulties, adaptiveDifficultySet);
    }
  });

  test('forced route measurement retains its canonical singleton', () async {
    final state = await makeState();
    state.startDailyBoss();
    state.startGame();
    state.rt.timer?.cancel();

    final measured = state.debugQuestionDifficultyMeasurements.single;
    expect(identical(measured, state.debugQuestionDifficultyLegality), isTrue);
    expect(measured?.route, QuestionDifficultyRoute.dailyBoss);
    expect(measured?.legalDifficulties, {state.rt.q!.diff!});
  });

  test('ambiguous manual Expert records unavailable legality', () async {
    final state = await makeState();
    startNormal(state, difficulty: Difficulty.expert);

    expect(state.rt.q!.diff, Difficulty.expert);
    expect(state.debugQuestionDifficultyMeasurements,
        <QuestionDifficultyLegality?>[null]);
  });

  test('measurement snapshot cannot mutate canonical legality', () async {
    final state = await makeState();
    startNormal(state);

    final measured = state.debugQuestionDifficultyMeasurements.single!;
    expect(
      () => state.debugQuestionDifficultyMeasurements.add(measured),
      throwsUnsupportedError,
    );
    expect(
      () => measured.legalDifficulties.add(Difficulty.insane),
      throwsUnsupportedError,
    );
    expect(
      state.debugQuestionDifficultyLegality?.legalDifficulties,
      playerConfigurableDifficultySet,
    );
  });

  test('measurement lifecycle clears with the active run', () async {
    final state = await makeState();
    startNormal(state);
    expect(state.debugQuestionDifficultyMeasurementCount, 1);

    await state.quitToMenu();
    expect(state.debugQuestionDifficultyMeasurementCount, 0);
  });

  test('reading measurements preserves seeded gameplay', () async {
    final untouched = await makeState(
      questionGenerator: QuestionGenerator(rng: Random(1408)),
    );
    final measured = await makeState(
      questionGenerator: QuestionGenerator(rng: Random(1408)),
    );
    untouched.skillMap[Operation.addition.name]!.mastery = 82;
    measured.skillMap[Operation.addition.name]!.mastery = 82;
    startNormal(untouched, adaptive: true);
    startNormal(measured, adaptive: true);

    for (var turn = 0; turn < 2; turn++) {
      expect(measured.debugQuestionDifficultyMeasurements.last, isNotNull);
      expect(measured.rt.q!.key, untouched.rt.q!.key);
      expect(measured.rt.q!.diff, untouched.rt.q!.diff);
      expect(
        measured.debugQuestionTimerDurationMs(),
        untouched.debugQuestionTimerDurationMs(),
      );

      untouched.onAnswer(untouched.rt.q!.ans);
      measured.onAnswer(measured.rt.q!.ans);
      expect(measured.p[1].score, untouched.p[1].score);
      expect(measured.rt.totalTurns, untouched.rt.totalTurns);

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
