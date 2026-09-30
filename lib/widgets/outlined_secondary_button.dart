import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';

class OutlinedSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;

  /// Null uses the theme's border and text colours. Pass colours only for a brand accent, like the
  /// landing screen's pink "Create Account".
  final Color? borderColor;
  final Color? textColor;
  final double fontSize;
  final double height;
  final double letterSpacing;

  /// The button's height ([height] above is the text line-height).
  final double buttonHeight;
  final double borderWidth;

  const OutlinedSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.borderColor,
    this.textColor,
    this.fontSize = 14,
    this.height = 20 / 14,
    this.letterSpacing = -0.15,
    this.buttonHeight = 48,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = borderColor ?? colors.border;
    final ink = textColor ?? colors.textPrimary;
    return SizedBox(
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: border, width: borderWidth),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[Icon(leadingIcon, size: 18, color: ink), const SizedBox(width: 15)],
            Text(
              label,
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
                letterSpacing: letterSpacing,
                height: height,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
