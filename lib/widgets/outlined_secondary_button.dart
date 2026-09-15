import 'package:flutter/material.dart';

class OutlinedSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final Color borderColor;
  final Color textColor;
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
    this.borderColor = const Color(0x1A000000),
    this.textColor = const Color(0xFF0A0A0A),
    this.fontSize = 14,
    this.height = 20 / 14,
    this.letterSpacing = -0.15,
    this.buttonHeight = 48,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18, color: textColor),
              const SizedBox(width: 15),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
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
