import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_semantic_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppSemanticColors.light);

  /// A real dark theme (Sprint 8 Task 2) -- not `ThemeData.dark()`, which is
  /// what this was stubbed as before. Built the same way as [light], off
  /// [AppSemanticColors.dark]'s tokens: a proper dark background/surface/
  /// input fill and real text contrast against them, while every accent
  /// gradient in [AppColors] (`primaryGradient`, the membership tier
  /// gradients, `bottomNavActive`) is reused completely unchanged -- so the
  /// app still reads as Rosewater Café's pink/purple brand at night, not
  /// generic Material dark grey with a pink button dropped on top.
  static ThemeData get dark => _build(Brightness.dark, AppSemanticColors.dark);

  static ThemeData _build(Brightness brightness, AppSemanticColors colors) {
    final isDark = brightness == Brightness.dark;
    // Brightness-correct default text colors (Material's own light/dark
    // typography), then overridden with this brand's own tokens -- same
    // approach as the rest of this method, never Flutter's raw defaults.
    final baseTextTheme = ThemeData(
      brightness: brightness,
    ).textTheme.apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // The Figma design uses Inter as its typeface throughout.
      fontFamily: GoogleFonts.inter().fontFamily,
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: colors.border,
      iconTheme: IconThemeData(color: colors.textPrimary),
      // So `context.colors` (app_semantic_colors.dart) can read these same
      // tokens back out inside any screen's `build`.
      extensions: [colors],
    );
  }
}
