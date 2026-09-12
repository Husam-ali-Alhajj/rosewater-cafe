import 'package:flutter/material.dart';

/// Content + accent gradient for one onboarding slide. Gradient stops are
/// taken directly from the Figma file (each slide uses its own two-color
/// pair, not a shared app color), so the icon badge, active dot, and CTA
/// button all match the design exactly.
class OnboardingPageData {
  final IconData icon;
  final Gradient accentGradient;
  final String heading;
  final String body;

  const OnboardingPageData({
    required this.icon,
    required this.accentGradient,
    required this.heading,
    required this.body,
  });
}
