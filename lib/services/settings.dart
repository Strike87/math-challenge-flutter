import 'dart:async';

import 'package:flutter/material.dart';
import '../game_config.dart';
import '../models/enums.dart';
import 'storage.dart';

/// Theme + accessibility + audio + haptics preferences.
class SettingsService extends ChangeNotifier {
  bool _dark = false;
  bool _sound = true;
  bool _vibration = true;
  bool _dyslexia = false;
  bool _colorblind = false;
  bool _lowPerf = false;
  bool _reduceMotion = false;
  bool _platformReduceMotion = false;
  double _animSpeed = 1.0;

  bool get dark => _dark;
  bool get sound => _sound;
  bool get vibration => _vibration;
  bool get dyslexia => _dyslexia;
  bool get colorblind => _colorblind;
  bool get lowPerf => _lowPerf;
  bool get reduceMotion => _reduceMotion || _platformReduceMotion;
  bool get manualReduceMotion => _reduceMotion;
  double get animSpeed => _animSpeed;

  void load({
    required bool dark,
    required bool sound,
    required bool vibration,
    required bool dyslexia,
    required bool colorblind,
    required bool lowPerf,
    required bool reduceMotion,
    required double animSpeed,
  }) {
    _dark = dark;
    _sound = sound;
    _vibration = vibration;
    _dyslexia = dyslexia;
    _colorblind = colorblind;
    _lowPerf = lowPerf;
    _reduceMotion = reduceMotion;
    _animSpeed = animSpeed;
    notifyListeners();
  }

  void toggleDark() {
    _dark = !_dark;
    unawaited(Storage.setBool('mc_dark', _dark));
    notifyListeners();
  }

  void toggleSound() {
    _sound = !_sound;
    unawaited(Storage.setBool('mc_sound', _sound));
    notifyListeners();
  }

  void toggleVibration() {
    _vibration = !_vibration;
    unawaited(Storage.setBool('mc_vibration', _vibration));
    notifyListeners();
  }

  void toggleDyslexia() {
    _dyslexia = !_dyslexia;
    unawaited(Storage.setBool('mc_dyslexia', _dyslexia));
    notifyListeners();
  }

  void toggleColorblind() {
    _colorblind = !_colorblind;
    unawaited(Storage.setBool('mc_colorblind', _colorblind));
    notifyListeners();
  }

  void toggleLowPerf() {
    _lowPerf = !_lowPerf;
    _animSpeed = _lowPerf ? 0.3 : 1.0;
    unawaited(Storage.setBool('mc_lowPerf', _lowPerf));
    unawaited(Storage.setDouble('mc_animSpeed', _animSpeed));
    notifyListeners();
  }

  void toggleReduceMotion() {
    _reduceMotion = !_reduceMotion;
    unawaited(Storage.setBool('mc_reduceMotion', _reduceMotion));
    notifyListeners();
  }

  void setAnimSpeed(double v) {
    _animSpeed = v;
    unawaited(Storage.setDouble('mc_animSpeed', _animSpeed));
    notifyListeners();
  }

  void setPlatformReduceMotion(bool value) {
    if (_platformReduceMotion == value) return;
    _platformReduceMotion = value;
    notifyListeners();
  }

  // ─── Color helpers ──────────────────────────────────────────
  Color get bg =>
      _dark ? const Color(GameConfig.bgDark) : const Color(GameConfig.bgLight);
  Color get text => _dark
      ? const Color(GameConfig.textDark)
      : const Color(GameConfig.textLight);
  Color get text2 => _dark
      ? const Color(GameConfig.text2Dark)
      : const Color(GameConfig.text2Light);
  Color get muted => _dark
      ? const Color(GameConfig.mutedDark)
      : const Color(GameConfig.mutedLight);
  Color get border => _dark
      ? const Color(GameConfig.borderDark)
      : const Color(GameConfig.borderLight);
  Color get surface =>
      _dark ? const Color(0xBF1E1A16) : const Color(0xBFFFFFFF);
  Color get surface2 =>
      _dark ? const Color(0x732A2520) : const Color(0x73FFFFFF);

  /// Colorblind-safe alternates — uses Okabe-Ito set for the main palette.
  Color opColor(Operation op) {
    if (_colorblind) {
      switch (op) {
        case Operation.addition:
          return const Color(0xFF0072B2); // blue
        case Operation.subtraction:
          return const Color(0xFFD55E00); // vermillion
        case Operation.multiplication:
          return const Color(0xFF009E73); // bluish green
        case Operation.division:
          return const Color(0xFFCC79A7); // reddish purple
        default:
          return const Color(GameConfig.coral);
      }
    }
    switch (op) {
      case Operation.addition:
        return const Color(GameConfig.mint);
      case Operation.subtraction:
        return const Color(GameConfig.sky);
      case Operation.multiplication:
        return const Color(GameConfig.mango);
      case Operation.division:
        return const Color(GameConfig.punch);
      default:
        return const Color(GameConfig.coral);
    }
  }

  /// Text theme provider. When dyslexia mode is on, we use a heavier
  /// sans-serif weight and slightly larger line height.
  FontWeight get bodyWeight => _dyslexia ? FontWeight.w600 : FontWeight.w500;
  double get bodyLineHeight => _dyslexia ? 1.6 : 1.4;

  /// Animation duration scales like the original CSS variable:
  /// 0.3x is short/fast, 2.0x is long/slow.
  Duration duration(double baseMs) {
    if (reduceMotion) return Duration.zero;
    final scaled = baseMs * _animSpeed;
    return Duration(milliseconds: scaled.round());
  }
}
