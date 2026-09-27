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

  // --- Dark mode (Sprint 8 Task 2, v3 -- rebuilt again after live feedback) ---
  //
  // v1 kept the background in the same plum/maroon hue family as the accent
  // -- read as muddy, nothing to pop against. v2 fixed that by going truly
  // neutral (barest whisper of violet) but kept the light-mode pink/purple
  // accent unchanged -- live feedback on v2 was still "too bad, not
  // matching." v3 leans into an actual color identity instead of a neutral
  // fix: a cool blue-black (slate/navy, not a warm or violet-tinted
  // near-black), paired with a dedicated BLUE accent for dark mode only
  // ([primaryGradientDark]/[accentDark] below) rather than reusing the
  // light-mode pink/purple gradient as-is. Deliberately not trying to lock
  // this in as final -- see [primaryGradientDark]'s own comment.
  static const Color darkBackground = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF121A2E);
  static const Color darkSurfaceElevated = Color(0xFF1B2540);
  static const Color darkInputFill = Color(0xFF161F38);
  static const Color darkBorder = Color(0x333B82F6); // accent blue @ 20%, not plain white -- a hairline that's part of the same family as the accent, not a neutral afterthought
  static const Color darkTextPrimary = Color(0xFFEEF2FC);
  static const Color darkTextMuted = Color(0xFF94A3C0); // cool slate-blue, not the warm lavender-grey v2 used

  // Same soft 3-stop wash as [pageBackgroundGradient], now a genuine navy
  // movement (not a near-invisible neutral shift) so the page itself reads
  // as blue before a single accent pixel shows up.
  static const LinearGradient pageBackgroundGradientDark = LinearGradient(
    colors: [Color(0xFF0F1830), Color(0xFF0B1222), Color(0xFF070A16)],
    stops: [0, 0.5, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark-mode-only accent, replacing [primaryGradient]/[bottomNavActive] on
  // every screen once it reads `context.colors.accentGradient`/`.accent`
  // instead of those constants directly (see AppSemanticColors). A genuine
  // blue-to-indigo two-stop, same left-to-right structure as the light-mode
  // gradient, picked to read clearly as "blue" (not a blue-tinted purple)
  // against the navy background above. Explicitly a first real attempt, not
  // a locked-in final answer -- the brief was to iterate freely here, not
  // preserve anything.
  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const Color accentDark = Color(0xFF5B9BFF); // a single-color stand-in for bottomNavActive -- bright enough to read on darkSurface/darkBackground alike

  // success/warning/danger, lightened so each still clears ~4.5:1 against
  // the dark surfaces above -- the light-mode hexes are tuned for a white
  // card and fall well short of that on [darkSurface].
  static const Color successDark = Color(0xFF6FDD86);
  static const Color warningDark = Color(0xFFFFCA5C);
  static const Color dangerDark = Color(0xFFFF7A7E);
}
