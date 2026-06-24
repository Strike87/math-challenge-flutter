import 'package:flutter/material.dart';
import '../game_config.dart';
import '../services/settings.dart';

/// App-wide theme + colour helpers driven by [SettingsService].
class AppTheme {
  AppTheme._();

  static ThemeData light(SettingsService s) => _base(s, Brightness.light);
  static ThemeData dark(SettingsService s) => _base(s, Brightness.dark);

  static ThemeData _base(SettingsService s, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(GameConfig.bgDark) : const Color(GameConfig.bgLight);
    final surface = isDark ? const Color(0xFF1E1B18) : Colors.white;
    final text = isDark ? const Color(GameConfig.textDark) : const Color(GameConfig.textLight);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(GameConfig.coral),
        brightness: brightness,
        surface: surface,
        primary: const Color(GameConfig.coral),
        secondary: const Color(GameConfig.sky),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: text, fontWeight: s.bodyWeight, height: s.bodyLineHeight),
        bodyMedium: TextStyle(color: text, fontWeight: s.bodyWeight, height: s.bodyLineHeight),
        bodySmall: TextStyle(color: text, fontWeight: s.bodyWeight, height: s.bodyLineHeight),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(color: text, fontWeight: FontWeight.w700),
      ),
      fontFamily: 'PlusJakartaSans',
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      dividerColor: isDark ? const Color(GameConfig.borderDark) : const Color(GameConfig.borderLight),
    );
  }

  /// Headline font (Baloo 2 in original).
  static const String headFont = 'Baloo2';
  static const String bodyFont = 'PlusJakartaSans';
}
