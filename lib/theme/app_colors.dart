import 'package:flutter/material.dart';

/// Colors pulled from the Rosewater Café Figma file.
/// The brand uses a pink → purple → orange gradient family throughout
/// (onboarding icons, primary buttons, membership status card).
class AppColors {
  AppColors._();

  static const Color pink = Color(0xFFE91E63);
  static const Color hotPink = Color(0xFFEC1E63);
  static const Color purple = Color(0xFF9C27B0);
  static const Color orange = Color(0xFFF57C00);

  // Primary gradient used on main CTA buttons (Sign In, Next, Pay, etc.)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Membership status card gradient on Home
  static const LinearGradient membershipGradient = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color background = Color(0xFFFFF5F7); // soft pink page bg
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF757575);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFD32F2F);
}
