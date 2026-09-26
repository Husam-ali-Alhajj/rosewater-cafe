import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_semantic_colors.dart';

class AppTheme {
  AppTheme._();

  /// [isArabic] picks the typeface: the Figma design's Inter for Latin
  /// text, or a real Arabic typeface when the app's locale is Arabic --
  /// Inter itself has NO Arabic glyphs at all, so requesting it for Arabic
  /// text was silently falling through to Skia's generic system fallback
  /// font (different per platform, and never designed to match Inter's
  /// weight or rhythm) -- see [_arabicFontFamily]'s doc comment.
  static ThemeData light({bool isArabic = false}) =>
      _build(Brightness.light, AppSemanticColors.light, isArabic: isArabic);

  /// A real dark theme (Sprint 8 Task 2) -- not `ThemeData.dark()`, which is
  /// what this was stubbed as before. Built the same way as [light], off
  /// [AppSemanticColors.dark]'s tokens: a proper dark background/surface/
  /// input fill and real text contrast against them, while every accent
  /// gradient in [AppColors] (`primaryGradient`, the membership tier
  /// gradients, `bottomNavActive`) is reused completely unchanged -- so the
  /// app still reads as Rosewater Café's pink/purple brand at night, not
  /// generic Material dark grey with a pink button dropped on top.
  static ThemeData dark({bool isArabic = false}) =>
      _build(Brightness.dark, AppSemanticColors.dark, isArabic: isArabic);

  /// Noto Naskh Arabic: a real Naskh (خط النسخ) typeface -- the classic
  /// book/print Arabic script -- by Google's Noto project, SIL Open Font
  /// License, so it's free to bundle in the app and keep in this public
  /// repo. It's a registered pubspec.yaml font asset, NOT a google_fonts
  /// runtime download: `GoogleFonts.x().fontFamily` only ever fetches the
  /// Regular file, over the network, so bold text was being faked (and
  /// silently fell back to the browser's own Arabic font when the fetch
  /// hadn't finished or failed). Bundled, all four weights (400-700) are
  /// real, cover every weight this app's TextStyles use, and work offline.
  static const _arabicFontFamily = 'NotoNaskhArabic';

  static ThemeData _build(Brightness brightness, AppSemanticColors colors, {required bool isArabic}) {
    final isDark = brightness == Brightness.dark;
    final interFamily = GoogleFonts.inter().fontFamily;
    final fontFamily = isArabic ? _arabicFontFamily : interFamily;
    // Brightness-correct default text colors (Material's own light/dark
    // typography), then overridden with this brand's own tokens -- same
    // approach as the rest of this method, never Flutter's raw defaults.
    // The font MUST be applied here too, not only via `fontFamily:` below:
    // ThemeData applies `fontFamily` to its own default text styles and
    // THEN merges this textTheme over them -- and this one carries
    // Material's platform font (Roboto etc.), which wins that merge. So a
    // `fontFamily:` alone was silently ignored app-wide.
    final fontFamilyFallback = isArabic && interFamily != null ? [interFamily] : null;
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
      // Noto Naskh Arabic has no Latin letters, so any English that shows
      // up in Arabic mode (names, emails, "Rosewater Café") falls back to
      // Inter, the design's Latin face, rather than a random system font.
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
