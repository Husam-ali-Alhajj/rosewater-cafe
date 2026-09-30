import 'package:flutter/material.dart';
import '../theme/app_semantic_colors.dart';

class OnboardingIconBadge extends StatelessWidget {
  final IconData icon;

  /// Null uses the theme's accent gradient (used by the auth screens). Onboarding passes its own
  /// per-slide gradient.
  final Gradient? gradient;
  final double size;

  const OnboardingIconBadge({super.key, required this.icon, this.gradient, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient ?? context.colors.accentGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 20),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size / 2),
    );
  }
}
