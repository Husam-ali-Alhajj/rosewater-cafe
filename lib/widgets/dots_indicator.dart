import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DotsIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final Gradient activeGradient;
  final Color inactiveColor;

  const DotsIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.activeGradient = AppColors.primaryGradient,
    this.inactiveColor = const Color(0xFFD1D5DC),
  });

  @override
  Widget build(BuildContext context) {
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
            color: isActive ? null : inactiveColor,
            gradient: isActive ? activeGradient : null,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
