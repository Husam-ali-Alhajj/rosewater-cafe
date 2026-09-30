import 'package:flutter/material.dart';

/// One onboarding slide. Each slide has its own two-colour gradient from the design.
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
