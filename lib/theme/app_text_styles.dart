import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The Figma file pairs a serif display face ("Times") for the
/// "Rosewater Café" wordmark with Inter everywhere else.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle logoTitle = TextStyle(
    fontFamily: 'Times New Roman',
    fontSize: 36,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.bold,
    height: 40 / 36,
    color: AppColors.textDark,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textDark,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.44,
    height: 28 / 18,
    color: Colors.white,
  );
}
