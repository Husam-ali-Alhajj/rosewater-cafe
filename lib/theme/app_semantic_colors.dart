import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware colours (backgrounds, cards, text, inputs, accent). Light and dark each have their
/// own set; screens read the active one with `context.colors`.
///
/// The accent changes per theme (pink/purple in light, blue in dark). The plan colours (Basic,
/// Premium, VIP) stay the same in both, so a plan always looks the same.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  /// The background gradient behind every screen.
  final Gradient pageBackgroundGradient;

  /// Card background.
  final Color surface;

  /// Bars that sit above the page (like the bottom navigation). Slightly lighter than cards in dark
  /// mode.
  final Color surfaceElevated;

  /// Input field background.
  final Color inputFill;

  /// Thin border colour for cards and inputs.
  final Color border;

  /// Main text.
  final Color textPrimary;

  /// Secondary text.
  final Color textMuted;

  /// Status colours, adjusted per theme to stay readable.
  final Color success;
  final Color warning;
  final Color danger;

  /// The main accent colour (changes per theme).
  final Gradient accentGradient;
  final Color accent;

  const AppSemanticColors({
    required this.pageBackgroundGradient,
    required this.surface,
    required this.surfaceElevated,
    required this.inputFill,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.accentGradient,
    required this.accent,
  });

  static const light = AppSemanticColors(
    pageBackgroundGradient: AppColors.pageBackgroundGradient,
    surface: AppColors.cardWhite,
    surfaceElevated: AppColors.cardWhite,
    inputFill: Color(0xFFF3F4F6),
    border: Color(0x1A000000), // black at 10%
    textPrimary: AppColors.textDark,
    textMuted: AppColors.textMuted,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    accentGradient: AppColors.primaryGradient,
    accent: AppColors.bottomNavActive,
  );

  static const dark = AppSemanticColors(
    pageBackgroundGradient: AppColors.pageBackgroundGradientDark,
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceElevated,
    inputFill: AppColors.darkInputFill,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textMuted: AppColors.darkTextMuted,
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    danger: AppColors.dangerDark,
    accentGradient: AppColors.primaryGradientDark,
    accent: AppColors.accentDark,
  );

  @override
  AppSemanticColors copyWith({
    Gradient? pageBackgroundGradient,
    Color? surface,
    Color? surfaceElevated,
    Color? inputFill,
    Color? border,
    Color? textPrimary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? danger,
    Gradient? accentGradient,
    Color? accent,
  }) {
    return AppSemanticColors(
      pageBackgroundGradient: pageBackgroundGradient ?? this.pageBackgroundGradient,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      inputFill: inputFill ?? this.inputFill,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      accentGradient: accentGradient ?? this.accentGradient,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      pageBackgroundGradient: Gradient.lerp(pageBackgroundGradient, other.pageBackgroundGradient, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      accentGradient: Gradient.lerp(accentGradient, other.accentGradient, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

/// `context.colors`: the active theme's colours.
///
/// Falls back to the light colours when the theme doesn't have them (some tests use a plain
/// ThemeData).
extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get colors => Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
