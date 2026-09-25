import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_semantic_colors.dart';

/// The header used by the Profile sub-screens (Edit Profile, Payment Methods,
/// Add Payment Method...): a 40x36 back button, 16px gap, then the title in
/// Inter Medium 26 / line height 40. Read from the Figma frames' `Container`
/// header (e.g. Edit Profile node 1217:2405, Payment Methods 1217:2479) --
/// identical on both.
class ScreenHeader extends StatelessWidget {
  final String title;

  /// Null disables the back button (e.g. while a save is in progress).
  final VoidCallback? onBack;

  const ScreenHeader({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Sprint 8 Task 6: same explicit RTL check as every other back button
    // in the app (sign_in_screen.dart, coming_soon_screen.dart, ...) --
    // Icons.arrow_back doesn't auto-mirror.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Tooltip(
            message: AppLocalizations.of(context).backButton,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 40,
                height: 36,
                child: Center(
                  child: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, size: 16, color: colors.textPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                height: 40 / 26,
                letterSpacing: 0.369,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
