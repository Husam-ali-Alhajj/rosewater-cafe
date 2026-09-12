import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The Figma file pairs a serif display face for the "Rosewater Café"
/// wordmark with a plain sans body font everywhere else. We use the
/// platform default sans for now — swap in a Google Font later if the
/// design calls for something more specific once you inspect it closer.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle logoTitle = TextStyle(
    fontFamily: 'serif',
    fontSize: 28,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w600,
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
