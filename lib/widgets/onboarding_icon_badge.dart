import 'package:flutter/material.dart';
import '../theme/app_semantic_colors.dart';

class OnboardingIconBadge extends StatelessWidget {
  final IconData icon;

  /// Null uses this theme's own accent gradient (via `context.colors`) --
  /// the auth screens (Create Account, Forgot Password, Set New Password,
  /// Sign In) all rely on this default so their badge goes blue in dark
  /// mode along with everything else. The onboarding carousel passes its
  /// own per-slide gradient explicitly instead, unaffected by theme.
  final Gradient? gradient;
  final double size;

  const OnboardingIconBadge({
    super.key,
    required this.icon,
    this.gradient,
    this.size = 96,
  });

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
