import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Figma's fractional hairline stroke width.
const _hairline = 0.515;

/// The white "Cancel" button that sits beside [SaveButton] at the bottom of the
/// Profile sub-screens' forms (Figma Edit Profile node 1217:2472): 49.03 tall,
/// radius 8, hairline black-at-10% border, Inter Medium 14 in #0A0A0A. The
/// Notifications screen's full-width "Done" (node 1217:2641) is the same
/// button with a different [label].
class CancelButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const CancelButton({super.key, required this.onTap, this.label = 'Cancel'});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            height: 49.03,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: Color(0xFF0A0A0A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The gradient primary button beside [CancelButton] (Figma Edit Profile node
/// 1217:2474): 48 tall, radius 8, the app's primary gradient, Inter Medium 14
/// in white. Shows [savingLabel] while [saving].
class SaveButton extends StatelessWidget {
  final String label;
  final String savingLabel;
  final bool saving;
  final VoidCallback? onTap;

  const SaveButton({
    super.key,
    required this.label,
    required this.saving,
    required this.onTap,
    this.savingLabel = 'Saving…',
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Container(
        height: 48,
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                saving ? savingLabel : label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
