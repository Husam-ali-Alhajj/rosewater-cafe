import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_semantic_colors.dart';

class AppTheme {
  AppTheme._();

  /// Light theme. [isArabic] switches the font: Inter has no Arabic letters.
  static ThemeData light({bool isArabic = false}) =>
      _build(Brightness.light, AppSemanticColors.light, isArabic: isArabic);

  /// Dark theme, built from the dark colour set (navy background, blue accent).
  static ThemeData dark({bool isArabic = false}) => _build(Brightness.dark, AppSemanticColors.dark, isArabic: isArabic);

  /// Noto Naskh Arabic for Arabic text. Bundled with the app (open licence), so every weight is
  /// real and it works offline.
  static const _arabicFontFamily = 'NotoNaskhArabic';

  /// Inter for English text, also bundled. Its bold weight is mapped to SemiBold on purpose, so
  /// English isn't too heavy (see pubspec.yaml).
  static const _latinFontFamily = 'Inter';

  static ThemeData _build(Brightness brightness, AppSemanticColors colors, {required bool isArabic}) {
    final isDark = brightness == Brightness.dark;
    final fontFamily = isArabic ? _arabicFontFamily : _latinFontFamily;
    // The font has to be set on the text theme too: ThemeData merges this text theme over its own,
    // and its default font would otherwise win.
    final fontFamilyFallback = isArabic ? const [_latinFontFamily] : null;
    final baseTextTheme = ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      // Noto Naskh has no Latin letters, so English text in Arabic mode uses Inter.
      fontFamilyFallback: fontFamilyFallback,
      textTheme: baseTextTheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pink,
        brightness: brightness,
        primary: AppColors.pink,
        secondary: AppColors.purple,
        surface: colors.surface,
        error: colors.danger,
      ),
      appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: colors.textPrimary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        labelStyle: TextStyle(color: colors.textMuted),
        hintStyle: TextStyle(color: colors.textMuted),
        helperStyle: TextStyle(color: colors.textMuted),
        prefixIconColor: colors.textMuted,
        suffixIconColor: colors.textMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: colors.border,
      iconTheme: IconThemeData(color: colors.textPrimary),
      // Lets `context.colors` read these colours.
      extensions: [colors],
    );
  }
}
