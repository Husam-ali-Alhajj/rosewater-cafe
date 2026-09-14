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
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: 1.5),
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
