import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';

class OutlinedSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;

  /// Null uses this theme's own hairline border / primary text (via
  /// `context.colors`) instead of a fixed light-mode value -- a caller only
  /// needs to pass these when it wants a specific BRAND accent instead (e.g.
  /// Auth Landing's pink "Create Account" outline), not for an ordinary
  /// secondary button like Payment's "Back".
  final Color? borderColor;
  final Color? textColor;
  final double fontSize;
  final double height;
  final double letterSpacing;

  /// The button's own box height — distinct from [height] above, which is
  /// actually the text line-height ratio (a pre-existing naming collision
  /// this doesn't attempt to fix, to avoid touching other call sites).
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18, color: ink),
              const SizedBox(width: 15),
            ],
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
