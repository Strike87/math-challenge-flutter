import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/main.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/iap.dart';
import 'package:math_challenge/services/settings.dart';

void main() {
  testWidgets('VM product mode rejects injected GameState', (tester) async {
    expect(kReleaseMode, isTrue);
    final state = GameState(settings: SettingsService(), audio: _SilentAudio());
    try {
      await tester.pumpWidget(MathChallengeApp(
        adService: const UnavailableAdMobService(),
        iapAdapter: const UnavailableIapPurchaseAdapter(),
        testGameState: state,
      ));
      expect(
        tester.takeException(),
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Test GameState injection is unavailable in release.',
        ),
      );
      debugPrint('INJECTION_GUARD_ASSERTION_EXECUTED_PASS');
    } finally {
      state.dispose();
    }
  }, skip: !kReleaseMode);
}

final class _SilentAudio implements AudioService {
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
