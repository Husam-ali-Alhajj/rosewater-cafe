import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_semantic_colors.dart';

/// The header used by the Profile sub-screens: a back button and the title.
class ScreenHeader extends StatelessWidget {
  final String title;

  /// Null disables the back button (for example, while saving).
  final VoidCallback? onBack;

  const ScreenHeader({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The back arrow has to point the other way in right-to-left.
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
                fontWeight: FontWeight.w700,
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
