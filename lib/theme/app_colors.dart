import 'package:flutter/material.dart';

/// Colours from the Rosewater Cafe design.
class AppColors {
  AppColors._();

  static const Color pink = Color(0xFFE91E63);
  static const Color purple = Color(0xFF9C27B0);
  static const Color orange = Color(0xFFF57C00);

  // Main button gradient (Sign In and other main actions).
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF2056), Color(0xFF9810FA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Per-plan accent gradients on the membership cards.
  static const LinearGradient membershipBasicGradient = LinearGradient(
    colors: [Color(0xFF99A1AF), Color(0xFF4A5565)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient membershipPremiumGradient = LinearGradient(
    colors: [Color(0xFFC27AFF), Color(0xFF9810FA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient membershipVipGradient = LinearGradient(
    colors: [Color(0xFFFF637E), Color(0xFFEC003F)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // "Most Popular" badge (a solid colour in the design).
  static const Color membershipPopularBadge = Color(0xFF9810FA);

  // Bullet checkmark green, and the Premium card's border.
  static const Color membershipCheckmark = Color(0xFF00C950);
  static const Color membershipPremiumBorder = Color(0xFFC27AFF);

  // Soft background gradient used behind every screen.
  static const LinearGradient pageBackgroundGradient = LinearGradient(
    colors: [Color(0xFFFFF1F2), Color(0xFFFDF2F8), Color(0xFFFAF5FF)],
    stops: [0, 0.5, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Active tab colour in the bottom navigation.
  static const Color bottomNavActive = Color(0xFFEC003F);

  static const Color background = Color(0xFFFFF5F7); // soft pink page background
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E2939);
  static const Color textMuted = Color(0xFF4A5565);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFD32F2F);

  // Dark mode: a navy background with a blue accent (instead of reusing the light-mode pink).
  static const Color darkBackground = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF121A2E);
  static const Color darkSurfaceElevated = Color(0xFF1B2540);
  static const Color darkInputFill = Color(0xFF161F38);
  static const Color darkBorder = Color(0x333B82F6); // accent blue at 20%
  static const Color darkTextPrimary = Color(0xFFEEF2FC);
  static const Color darkTextMuted = Color(0xFF94A3C0); // slate blue

  // Dark version of [pageBackgroundGradient].
  static const LinearGradient pageBackgroundGradientDark = LinearGradient(
    colors: [Color(0xFF0F1830), Color(0xFF0B1222), Color(0xFF070A16)],
    stops: [0, 0.5, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark-mode accent gradient, used instead of [primaryGradient] (see AppSemanticColors).
  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const Color accentDark = Color(0xFF5B9BFF); // single-colour dark-mode accent

  // Status colours, lightened so they stay readable on dark cards.
  static const Color successDark = Color(0xFF6FDD86);
  static const Color warningDark = Color(0xFFFFCA5C);
  static const Color dangerDark = Color(0xFFFF7A7E);
}
