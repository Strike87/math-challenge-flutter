import 'package:flutter/material.dart';
import 'game_config.dart';
import 'services/settings.dart';

/// App-wide theme + colour helpers driven by [SettingsService].
class AppTheme {
  AppTheme._();

  static ThemeData light(SettingsService s) => _base(s, Brightness.light);
  static ThemeData dark(SettingsService s) => _base(s, Brightness.dark);

  static ThemeData _base(SettingsService s, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark
        ? const Color(GameConfig.bgDark)
        : const Color(GameConfig.bgLight);
    final surface = isDark ? const Color(0xBF1E1A16) : const Color(0xBFFFFFFF);
    final text = isDark
        ? const Color(GameConfig.textDark)
        : const Color(GameConfig.textLight);
    final bodyFamily = bodyFont;

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
        bodyLarge: TextStyle(
          color: text,
          fontWeight: s.bodyWeight,
          height: s.bodyLineHeight,
          fontFamily: bodyFamily,
        ),
        bodyMedium: TextStyle(
          color: text,
          fontWeight: s.bodyWeight,
          height: s.bodyLineHeight,
          fontFamily: bodyFamily,
        ),
        bodySmall: TextStyle(
          color: text,
          fontWeight: s.bodyWeight,
          height: s.bodyLineHeight,
          fontFamily: bodyFamily,
        ),
        titleLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
          fontFamily: headFont,
        ),
        titleMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          fontFamily: headFont,
        ),
        titleSmall: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          fontFamily: headFont,
        ),
      ),
      fontFamily: bodyFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      dividerColor: isDark
          ? const Color(GameConfig.borderDark)
          : const Color(GameConfig.borderLight),
    );
  }

  /// Headline font (Baloo 2 in original).
  static const String headFont = 'Baloo2';
  static const String bodyFont = 'PlusJakartaSans';
}
