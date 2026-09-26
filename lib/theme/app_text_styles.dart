import 'package:flutter/material.dart';
import 'app_semantic_colors.dart';

/// The Figma file pairs a serif display face ("Times") for the
/// "Rosewater Café" wordmark with Inter everywhere else.
///
/// Every style that carries a text color takes a [BuildContext] and reads it
/// from `context.colors` (see app_semantic_colors.dart) instead of a
/// hardcoded `AppColors` constant, so the same call every auth screen
/// already made (`style: AppTextStyles.heading1`) now resolves to the right
/// color in both light and dark mode (`style: AppTextStyles.heading1(context)`)
/// -- Sprint 8 Task 2. [button] is the one exception: it's always white
/// text on this app's brand gradient buttons, which stays identical in both
/// modes, so it's still a plain `const`.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle logoTitle(BuildContext context) => TextStyle(
    fontFamily: 'Times New Roman',
    fontSize: 36,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.bold,
    height: 40 / 36,
    color: context.colors.textPrimary,
  );

  static TextStyle heading1(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: context.colors.textPrimary,
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: context.colors.textPrimary,
  );

  static TextStyle body(BuildContext context) => TextStyle(
    fontSize: 14,
    color: context.colors.textPrimary,
  );

  static TextStyle bodyMuted(BuildContext context) => TextStyle(
    fontSize: 13,
    color: context.colors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.44,
    height: 28 / 18,
    color: Colors.white,
  );
}
