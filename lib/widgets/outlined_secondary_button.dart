import 'package:flutter/material.dart';

class OutlinedSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;

  const OutlinedSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18, color: const Color(0xFF0A0A0A)),
              const SizedBox(width: 15),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0A0A0A),
                fontWeight: FontWeight.w500,
                fontSize: 14,
                letterSpacing: -0.15,
                height: 20 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
