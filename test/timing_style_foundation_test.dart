import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameState> makeState() async {
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
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  Future<void> enableGameBrain(GameState state) async {
    await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
    await state.setGameBrainPreference(true);
    expect(state.effectiveGameBrainEnabled, isTrue);
  }

  GameRunSnapshot supportedSnapshot({
    TimingStyle timingStyle = TimingStyle.perQuestion,
  }) =>
      GameRunSnapshot(
        runType: GameRunType.normal,
        mode: GameMode.standard,
        operation: Operation.addition,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
        answerStyle: AnswerStyle.choice4,
        players: 1,
        questionTarget: 10,
        timingStyle: timingStyle,
      );

  Future<GameState> startSupportedSnapshot(TimingStyle timingStyle) async {
    final state = await makeState();
    await enableGameBrain(state);
    state.debugStartGameFromSnapshot(supportedSnapshot(
      timingStyle: timingStyle,
    ));
    state.rt.timer?.cancel();
    return state;
  }

  test('snapshot defaults to per-question timing', () {
    expect(supportedSnapshot().timingStyle, TimingStyle.perQuestion);
  });

  test('snapshot accepts future timing styles without gameplay wiring', () {
    expect(supportedSnapshot(timingStyle: TimingStyle.untimed).timingStyle,
        TimingStyle.untimed);
    expect(supportedSnapshot(timingStyle: TimingStyle.timeBank).timingStyle,
        TimingStyle.timeBank);
  });

  test('default active run keeps existing per-question timer behavior',
      () async {
    final state = await makeState();
    state
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = false
      ..diff = Difficulty.easy
      ..rt.challenge = Operation.addition
      ..startGame();

    expect(state.activeRunSnapshot?.timingStyle, TimingStyle.perQuestion);
    expect(state.debugQuestionTimerDurationMs(), 10000);
    expect(state.rt.timer?.isActive, isTrue);
    state.rt.timer?.cancel();
  });

  test('replay preserves the active snapshot timing style', () async {
    final state = await startSupportedSnapshot(TimingStyle.untimed);

    await state.replayGame();
    state.rt.timer?.cancel();

    expect(state.activeRunSnapshot?.timingStyle, TimingStyle.untimed);
  });

  test('non-per-question timing is not player-selectable', () {
    expect(
        GameMode.values.map((mode) => mode.name), isNot(contains('untimed')));
    expect(
        GameMode.values.map((mode) => mode.name), isNot(contains('timeBank')));
    expect(AnswerStyle.values.map((style) => style.name),
        isNot(contains('untimed')));
    expect(AnswerStyle.values.map((style) => style.name),
        isNot(contains('timeBank')));
  });

  test('only per-question timing enters current Phase-1 evidence', () async {
    for (final expectation in <(TimingStyle, bool)>[
      (TimingStyle.perQuestion, true),
      (TimingStyle.untimed, false),
      (TimingStyle.timeBank, false),
    ]) {
      final state = await startSupportedSnapshot(expectation.$1);

      expect(state.debugP1F01IntegrityRunEligible, expectation.$2);
      state.onAnswer(state.rt.q!.ans);

      expect(state.debugQuestionExperienceObservationCount,
          expectation.$2 ? 1 : 0);
      expect(
          state.debugContextEvidenceObservationCount, expectation.$2 ? 1 : 0);
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
