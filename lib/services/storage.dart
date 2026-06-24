import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny type-safe wrapper over `shared_preferences` for JSON-serialisable
/// values. Mirrors the original `LS` helper from the HTML game.
class Storage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('Storage.init() must be called before use');
    }
    return p;
  }

  // ─── Primitives ─────────────────────────────────────────────
  static bool getBool(String k, bool def) => _p.getBool(k) ?? def;
  static Future<void> setBool(String k, bool v) => _p.setBool(k, v);

  static int getInt(String k, int def) => _p.getInt(k) ?? def;
  static Future<void> setInt(String k, int v) => _p.setInt(k, v);

  static double getDouble(String k, double def) => _p.getDouble(k) ?? def;
  static Future<void> setDouble(String k, double v) => _p.setDouble(k, v);

  static String getString(String k, String def) => _p.getString(k) ?? def;
  static Future<void> setString(String k, String v) => _p.setString(k, v);

  static List<String> getStringList(String k, List<String> def) =>
      _p.getStringList(k) ?? def;
  static Future<void> setStringList(String k, List<String> v) =>
      _p.setStringList(k, v);

  // ─── JSON helpers ───────────────────────────────────────────
  static T? getObject<T>(String k, T Function(Map<String, dynamic>) fromJson,
      [T? def]) {
    final raw = _p.getString(k);
    if (raw == null) return def;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return fromJson(j);
    } catch (_) {
      return def;
    }
  }

  static Future<void> setObject(String k, Object value) =>
      _p.setString(k, jsonEncode(value));

  static List<T> getObjectList<T>(String k, T Function(Map<String, dynamic>) fromJson,
      [List<T> def = const []]) {
    final raw = _p.getString(k);
    if (raw == null) return def;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return def;
    }
  }

  static Future<void> setObjectList<T>(String k, List<T> values) =>
      _p.setString(k, jsonEncode(values));

  static Future<void> remove(String k) => _p.remove(k);
}
