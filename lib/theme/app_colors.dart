import 'package:flutter/material.dart';

/// Colors pulled directly from the Rosewater Café Figma file (Design panel
/// inspection, not eyeballed from renders — see docs/decisions.md).
class AppColors {
  AppColors._();

  static const Color pink = Color(0xFFE91E63);
  static const Color hotPink = Color(0xFFEC1E63);
  static const Color purple = Color(0xFF9C27B0);
  static const Color orange = Color(0xFFF57C00);

  // The app's real primary CTA gradient (Sign In, and other main actions),
  // confirmed from the Auth Landing screen's "Sign In" button.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF2056), Color(0xFF9810FA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Membership status card gradient on Home
  static const LinearGradient membershipGradient = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // The soft 3-stop wash used behind every screen so far (onboarding, auth
  // landing) — confirmed identical on both, so treated as the page-wide
  // background rather than something screen-specific.
  static const LinearGradient pageBackgroundGradient = LinearGradient(
    colors: [Color(0xFFFFF1F2), Color(0xFFFDF2F8), Color(0xFFFAF5FF)],
    stops: [0, 0.5, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color background = Color(0xFFFFF5F7); // soft pink page bg
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E2939);
  static const Color textMuted = Color(0xFF4A5565);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFD32F2F);
}
