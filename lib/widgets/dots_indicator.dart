import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DotsIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final Gradient activeGradient;

  /// Null picks a brightness-appropriate grey instead of the design's fixed
  /// light-mode one -- no token in [AppSemanticColors] fits a small solid
  /// control sitting directly on the page wash (`border` is a translucent
  /// hairline, `surfaceElevated` is a card fill and, in light mode, pure
  /// white -- both wrong here), so this picks its own pair the same way
  /// e.g. the QR note / purple info box do for one-off decorative colors.
  final Color? inactiveColor;

  const DotsIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.activeGradient = AppColors.primaryGradient,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = inactiveColor ?? (isDark ? const Color(0xFF4A4152) : const Color(0xFFD1D5DC));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? null : inactive,
            gradient: isActive ? activeGradient : null,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
