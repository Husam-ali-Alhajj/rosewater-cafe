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

  // Choose Membership card accents (icon badge + "Select" button) per tier.
  // Pulled exactly from the Figma file via the REST API (node 1213:1030,
  // "Choose Your Membership") — gradient fill hex values read directly off
  // each card's icon container / button, not estimated.
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

  // "Most Popular" badge — a SOLID fill in Figma (the darker end of the
  // Premium gradient), not a gradient.
  static const Color membershipPopularBadge = Color(0xFF9810FA);

  // Bullet checkmark green, and the Premium card's border color (the
  // lighter end of its gradient, not the darker one) — both read directly
  // off node 1213:1030.
  static const Color membershipCheckmark = Color(0xFF00C950);
  static const Color membershipPremiumBorder = Color(0xFFC27AFF);
  static const Color membershipCardBorder = Color(0xFFE5E7EB);

  // Text colors specific to the membership cards (Figma uses slightly
  // different shades here than the app's general textDark/textMuted).
  static const Color membershipListText = Color(0xFF364153);
  static const Color membershipPriceText = Color(0xFF101828);
  static const Color membershipPriceSuffix = Color(0xFF6A7282);

  // The soft 3-stop wash used behind every screen so far (onboarding, auth
  // landing) — confirmed identical on both, so treated as the page-wide
  // background rather than something screen-specific.
  static const LinearGradient pageBackgroundGradient = LinearGradient(
    colors: [Color(0xFFFFF1F2), Color(0xFFFDF2F8), Color(0xFFFAF5FF)],
    stops: [0, 0.5, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Bottom navigation bar's active-tab accent (icon, label, indicator dot)
  // -- read directly off the BottomNav component (Figma node 1216:2285).
  // Same hex as the darker end of membershipVipGradient, but nothing
  // standalone covered it before now.
  static const Color bottomNavActive = Color(0xFFEC003F);

  static const Color background = Color(0xFFFFF5F7); // soft pink page bg
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E2939);
  static const Color textMuted = Color(0xFF4A5565);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFD32F2F);

  // --- Dark mode (Sprint 8 Task 2, rebuilt after live feedback) ---
  //
  // v1 of this palette kept the background itself in the same plum/maroon
  // hue family as the accent gradient -- on a live device that read as
  // muddy, not "dark and premium": the pink/purple buttons had nothing to
  // pop against. Rebuilt against a real reference (a dark-mode fintech UI
  // kit) for the polish bar: the background/surfaces here are now a true,
  // NEUTRAL near-black (only the barest whisper of cool violet, not a
  // saturated plum), with a much bigger raw jump between background ->
  // surface -> elevated surface so cards visibly float instead of blending
  // in. [primaryGradient] (buttons, active nav, highlighted cards) is
  // reused completely unchanged -- keeping the accent exactly as-is is what
  // makes it actually stand out against a properly neutral backdrop,
  // instead of fighting a same-family background for attention.
  static const Color darkBackground = Color(0xFF0D0B10);
  static const Color darkSurface = Color(0xFF1E1A24);
  static const Color darkSurfaceElevated = Color(0xFF262029);
  static const Color darkInputFill = Color(0xFF221D2A);
  static const Color darkBorder = Color(0x33FFFFFF); // white @ 20% -- more definition against near-black than v1's 15%
  static const Color darkTextPrimary = Color(0xFFF7F4F8);
  static const Color darkTextMuted = Color(0xFFA79CAE);

  // Same soft 3-stop wash as [pageBackgroundGradient], re-picked as a barely-
  // perceptible near-black movement (not a visible plum wash like v1) --
  // matches [darkBackground] as its base rather than reading as a separate,
  // lighter layer.
  static const LinearGradient pageBackgroundGradientDark = LinearGradient(
    colors: [Color(0xFF120F17), Color(0xFF0F0D14), Color(0xFF0B0910)],
    stops: [0, 0.5, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // success/warning/danger, lightened so each still clears ~4.5:1 against
  // the dark surfaces above -- the light-mode hexes are tuned for a white
  // card and fall well short of that on [darkSurface].
  static const Color successDark = Color(0xFF6FDD86);
  static const Color warningDark = Color(0xFFFFCA5C);
  static const Color dangerDark = Color(0xFFFF7A7E);
}
