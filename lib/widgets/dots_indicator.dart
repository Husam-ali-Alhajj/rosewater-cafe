import 'package:flutter/material.dart';
import '../theme/app_semantic_colors.dart';
import '../utils/app_animations.dart';

class DotsIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  /// Null uses the theme's accent gradient. Onboarding passes its own per-slide gradient.
  final Gradient? activeGradient;

  /// Null uses a grey suited to the current theme.
  final Color? inactiveColor;

  const DotsIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.activeGradient,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = inactiveColor ?? (isDark ? const Color(0xFF4A4152) : const Color(0xFFD1D5DC));
    final active = activeGradient ?? context.colors.accentGradient;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: context.animDuration(const Duration(milliseconds: 200)),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? null : inactive,
            gradient: isActive ? active : null,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
