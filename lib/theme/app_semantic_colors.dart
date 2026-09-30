import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware tokens for the surfaces [AppColors]' plain constants can't
/// answer on their own -- a card's fill, the page's background wash, primary
/// vs. muted text, an input's fill -- registered on [ThemeData] as an
/// extension so [AppTheme.light] and [AppTheme.dark] each carry their own
/// instance (see app_theme.dart) and a screen reads whichever is active via
/// `context.colors` instead of a hardcoded `AppColors.cardWhite` /
/// `AppColors.textDark` / etc. that would stay light even in dark mode.
///
/// Also carries [accentGradient]/[accent] -- the primary CTA/active-state
/// brand color, which unlike the tokens above DOES differ per theme as of
/// the v3 dark-mode rebuild: light mode keeps `AppColors.primaryGradient`/
/// `bottomNavActive` exactly as designed, dark mode swaps in a dedicated
/// blue (`AppColors.primaryGradientDark`/`accentDark`) instead of reusing
/// pink/purple unchanged. The membership tier gradients
/// (Basic/Premium/VIP) stay OUT of this and unchanged in both themes --
/// those identify a plan, not the app's action color, and changing what
/// "VIP purple" looks like per theme would make the tier itself harder to
/// recognize, which the accent swap doesn't have that problem.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  /// The page-wide soft gradient wash every screen's `Scaffold` body sits on.
  final Gradient pageBackgroundGradient;

  /// A card/sheet's fill -- what `AppColors.cardWhite` (often
  /// `.withValues(alpha: 0.9)`) was standing in for on every screen.
  final Color surface;

  /// A surface that sits visually "above" the page wash even in light mode
  /// (the bottom nav bar, an app bar) -- same as [surface] in light mode,
  /// but a touch lighter than [surface] in dark mode so chrome doesn't flatten
  /// into the page.
  final Color surfaceElevated;

  /// A form field's fill.
  final Color inputFill;

  /// The hairline border color used on cards and inputs throughout --
  /// `Colors.black.withValues(alpha: 0.1)` in light mode.
  final Color border;

  /// Primary body/heading text -- what `AppColors.textDark` was standing in
  /// for.
  final Color textPrimary;

  /// Secondary/caption text -- what `AppColors.textMuted` was standing in
  /// for.
  final Color textMuted;

  /// Success/warning/danger, re-picked per brightness so each still clears
  /// AA contrast against [surface] -- same hue family as
  /// [AppColors.success]/[AppColors.warning]/[AppColors.danger], not a
  /// different color.
  final Color success;
  final Color warning;
  final Color danger;

  /// The primary CTA/active-state brand color -- see the class doc comment
  /// for why this one DOES change per theme, unlike everything above it.
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
    inputFill: Color(0xFFF3F4F6), // AppTheme.light's pre-existing input fill
    border: Color(0x1A000000), // black @ 10%, the hairline used everywhere
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

/// `context.colors` -- the theme-aware tokens above, for any screen/widget
/// that needs to look right in both light and dark mode.
///
/// Falls back to [AppSemanticColors.light] when the ambient [ThemeData]
/// doesn't carry the extension (a `MaterialApp` built directly with
/// `ThemeData()`, as a number of existing widget tests do, rather than
/// [AppTheme.light]/`.dark`) -- so those tests keep rendering exactly the
/// colors they did before this task, instead of a null-check crash.
extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get colors => Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
