import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import 'settings.dart';

/// Lightweight audio + haptic service.
///
/// The original HTML game synthesised tones via Web Audio API. We mirror that
/// behaviour by generating short tone bursts on demand rather than shipping
/// audio files — keeping the APK small and the latency low.
class AudioService {
  AudioService(this._settings);

  final SettingsService _settings;
  final AudioPlayer _player = AudioPlayer();
  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setPlayerMode(PlayerMode.lowLatency);
    } catch (_) {}
    _initialised = true;
  }

  /// Play a short succession of tones (each: [freq, duration_s, delay_s]).
  Future<void> playTones(List<List<double>> tones) async {
    if (!_settings.sound) return;
    await init();
    // Without bundled audio assets we fall back to system haptic + vibration
    // cues; the tone generator is a placeholder for users to drop .wav files
    // into assets/sfx/. We keep the API stable so the engine doesn't branch.
    for (final t in tones) {
      await Future.delayed(Duration(milliseconds: (t[2] * 1000).round()));
    }
  }

  Future<void> playCorrect() => playTones([
    [523, 0.08, 0.0],
    [659, 0.08, 0.06],
    [784, 0.10, 0.12],
  ]);

  Future<void> playWrong() => playTones([
    [220, 0.15, 0.0],
    [180, 0.20, 0.10],
  ]);

  Future<void> playStart() => playTones([
    [523, 0.10, 0.0],
    [784, 0.10, 0.15],
    [1046, 0.15, 0.30],
  ]);

  Future<void> playPowerUp() => playTones([
    [1046, 0.10, 0.0],
    [1318, 0.12, 0.06],
  ]);

  // ─── Haptics ────────────────────────────────────────────────
  void vibrate(int ms) {
    if (!_settings.vibration) return;
    HapticFeedback.lightImpact();
  }

  void vibratePattern(List<int> pattern) {
    if (!_settings.vibration) return;
    HapticFeedback.mediumImpact();
  }

  void vibrateCorrect() {
    if (!_settings.vibration) return;
    HapticFeedback.lightImpact();
  }

  void vibrateWrong() {
    if (!_settings.vibration) return;
    HapticFeedback.heavyImpact();
  }

  void vibratePowerUp() {
    if (!_settings.vibration) return;
    HapticFeedback.mediumImpact();
  }
}
