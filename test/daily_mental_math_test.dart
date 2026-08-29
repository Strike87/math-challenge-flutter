import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameState> state() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final value = GameState(
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
      questionGenerator: QuestionGenerator(rng: Random(41)),
    );
    await value.load();
    addTearDown(value.dispose);
    return value;
  }

  test('daily profile is stable, legal, and has the fixed 45-profile pool',
      () async {
    final value = await state();
    final first = value.debugDailyMentalMathProfile(DateTime(2026, 8, 29));
    final second = value.debugDailyMentalMathProfile(DateTime(2026, 8, 29));
    expect(first.operation, second.operation);
    expect(first.numberType, second.numberType);
    expect(first.focus, second.focus);
    expect(value.debugDailyMentalMathProfilePoolSize, 45);
    expect(
      {
        Operation.addition,
        Operation.subtraction,
        Operation.multiplication,
        Operation.division,
        Operation.mixed,
      },
      contains(first.operation),
    );
    expect(
      {NumberType.natural, NumberType.integers, NumberType.rationals},
      contains(first.numberType),
    );
  });

  testWidgets(
      'daily entry bypasses setup and clears once with its 50-coin reward',
      (tester) async {
    final value = await state();
    value.startDailyMentalMath();
    expect(value.currentScreen, GameScreen.game);
    expect(value.isMentalMathCountdown, isTrue);
    expect(value.activeRunSnapshot!.mentalMathEntry, MentalMathEntry.daily);
    await tester.pump(const Duration(seconds: 4));
    value.rt.timer?.cancel();
    value
      ..rt.momentum = 9
      ..rt.completedQuestions = 39;
    final coins = value.coins;
    value.onAnswer(value.rt.q!.ans);
    await tester.pump(const Duration(milliseconds: 1301));
    expect(value.mentalMathResultSummary!.dailyRewardAmountGranted, 50);
    expect(value.coins, coins + 50);
    expect(value.isDailyMentalMathClearedToday, isTrue);
    await value.replayGame();
    await tester.pump(const Duration(seconds: 4));
    value.rt.timer?.cancel();
    value
      ..rt.momentum = 9
      ..rt.completedQuestions = 39;
    value.onAnswer(value.rt.q!.ans);
    await tester.pump(const Duration(milliseconds: 1301));
    expect(value.mentalMathResultSummary!.dailyRewardAmountGranted, 0);
    expect(value.coins, coins + 50);
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
  void vibrate(int ms) {}
  @override
  void vibrateCorrect() {}
  @override
  void vibratePattern(List<int> pattern) {}
  @override
  void vibratePowerUp() {}
  @override
  void vibrateWrong() {}
  @override
  Future<void> playWrong() async {}
}
