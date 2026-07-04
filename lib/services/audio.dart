import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

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
  final Map<String, String> _toneFiles = {};
  Future<void> _toneQueue = Future<void>.value();
  bool _initialised = false;
  int _debugTonePlayCount = 0;
  int _debugVibrationCount = 0;

  int get debugTonePlayCount => _debugTonePlayCount;
  int get debugVibrationCount => _debugVibrationCount;

  Future<void> init() async {
    if (_initialised) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
          ),
        ),
      );
      await _player.setVolume(1);
    } catch (_) {}
    _initialised = true;
  }

  /// Play a short succession of tones (each: [freq, duration_s, delay_s]).
  Future<void> playTones(List<List<double>> tones) async {
    if (!_settings.sound) return;
    _debugTonePlayCount++;
    final bytes = _wavFromTones(tones);
    _toneQueue = _toneQueue
        .catchError((_) {})
        .then((_) => _playBytes(bytes, _toneKey(tones)));
    unawaited(_toneQueue);
  }

  Future<void> _playBytes(Uint8List bytes, String key) async {
    try {
      await init();
      await _player.stop();
      final source = await _toneSource(bytes, key);
      await _player.play(source, volume: 1);
    } catch (_) {}
  }

  Future<Source> _toneSource(Uint8List bytes, String key) async {
    final cached = _toneFiles[key];
    if (cached != null && File(cached).existsSync()) {
      return DeviceFileSource(cached, mimeType: 'audio/wav');
    }
    final path = '${Directory.systemTemp.path}/math_challenge_$key.wav';
    await File(path).writeAsBytes(bytes, flush: false);
    _toneFiles[key] = path;
    return DeviceFileSource(path, mimeType: 'audio/wav');
  }

  String _toneKey(List<List<double>> tones) {
    return tones
        .map((tone) => tone.map((v) => (v * 1000).round()).join('_'))
        .join('__');
  }

  Future<void> playCorrect() => playTones([
        [523, 0.12, 0.0],
        [659, 0.12, 0.09],
        [784, 0.16, 0.18],
      ]);

  Future<void> playWrong() => playTones([
        [294, 0.18, 0.0],
        [220, 0.24, 0.10],
        [196, 0.18, 0.28],
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

  Uint8List _wavFromTones(List<List<double>> tones) {
    const sampleRate = 22050;
    const targetVolume = 0.38;
    var totalSeconds = 0.0;
    for (final tone in tones) {
      final delay = tone.length > 2 ? tone[2] : 0.0;
      totalSeconds = math.max(totalSeconds, delay + tone[1] + 0.05);
    }

    final sampleCount = math.max(1, (totalSeconds * sampleRate).ceil());
    final samples = Float64List(sampleCount);
    for (final tone in tones) {
      final freq = tone[0];
      final duration = tone[1];
      final delay = tone.length > 2 ? tone[2] : 0.0;
      final start = (delay * sampleRate).round().clamp(0, sampleCount - 1);
      final count = (duration * sampleRate).round();
      for (var i = 0; i < count && start + i < sampleCount; i++) {
        final fade = 1.0 - (i / math.max(1, count));
        samples[start + i] +=
            math.sin(2 * math.pi * freq * i / sampleRate) * fade;
      }
    }

    final peak = samples.fold<double>(
      0,
      (max, sample) => math.max(max, sample.abs()),
    );
    final gain = peak == 0 ? 1.0 : targetVolume / peak;

    final data = ByteData(44 + sampleCount * 2);
    void ascii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        data.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + sampleCount * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, sampleCount * 2, Endian.little);

    for (var i = 0; i < sampleCount; i++) {
      final s = (samples[i] * gain).clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (s * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  // ─── Haptics ────────────────────────────────────────────────
  void vibrate(int ms) {
    if (!_settings.vibration) return;
    _debugVibrationCount++;
    unawaited(_vibrateDuration(ms, HapticFeedback.lightImpact));
  }

  void vibratePattern(List<int> pattern) {
    if (!_settings.vibration) return;
    _debugVibrationCount++;
    unawaited(_vibratePattern(pattern, HapticFeedback.mediumImpact));
  }

  void vibrateCorrect() {
    if (!_settings.vibration) return;
    _debugVibrationCount++;
    unawaited(_vibrateDuration(30, HapticFeedback.lightImpact));
  }

  void vibrateWrong() {
    if (!_settings.vibration) return;
    _debugVibrationCount++;
    unawaited(_vibrateDuration(80, HapticFeedback.heavyImpact));
  }

  void vibratePowerUp() {
    if (!_settings.vibration) return;
    _debugVibrationCount++;
    unawaited(_vibrateDuration(50, HapticFeedback.mediumImpact));
  }

  Future<void> _vibrateDuration(
    int ms,
    Future<void> Function() fallback,
  ) async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: math.max(1, ms));
        return;
      }
    } catch (_) {}
    try {
      await fallback();
    } catch (_) {}
  }

  Future<void> _vibratePattern(
    List<int> pattern,
    Future<void> Function() fallback,
  ) async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(pattern: pattern);
        return;
      }
    } catch (_) {}
    try {
      await fallback();
    } catch (_) {}
  }
}
