import 'package:flutter/material.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_feedback.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// Null uses the theme's accent gradient (pink/purple in light mode, blue in dark). Pass one only
  /// for a fixed colour, like the per-plan buttons.
  final Gradient? gradient;
  final IconData? trailingIcon;

  /// Two sizes in the design: full-width main buttons (the default) and smaller buttons inside
  /// cards.
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
            // A light vibration on every main button press.
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
