import 'package:flutter/material.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_feedback.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// Null uses this theme's own accent gradient (via `context.colors`) --
  /// pink/purple in light mode, blue in dark -- instead of a fixed
  /// light-mode gradient. Callers pass an explicit gradient only when they
  /// want a specific one regardless of theme (e.g. Choose Membership's
  /// per-tier "Select" buttons, or Onboarding's per-page accent), same
  /// "null defaults to the theme" pattern as [OutlinedSecondaryButton].
  final Gradient? gradient;
  final IconData? trailingIcon;

  /// Figma uses two distinct button sizes: full-width primary CTAs (Sign
  /// In, Continue to Payment) at the default 48/18, and compact in-card
  /// buttons (the plan "Select" buttons) at a smaller height/font — hence
  /// these being overridable rather than fixed.
  final double height;
  final double fontSize;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient,
    this.trailingIcon,
    this.height = 48,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final resolvedGradient = gradient ?? context.colors.accentGradient;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: resolvedGradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            // Sprint 8 Task 4: every primary CTA's press point, wired once
            // here rather than at each of this button's call sites --
            // "a small fixed set of real trigger points," not
            // instrumenting every tap individually.
            onTap: onPressed == null
                ? null
                : () {
                    context.triggerButtonPress();
                    onPressed!();
                  },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AppTextStyles.button.copyWith(fontSize: fontSize)),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 15),
                  Icon(trailingIcon, color: Colors.white, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
