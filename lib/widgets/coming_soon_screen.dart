import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';

/// A placeholder screen for things that aren't built yet.
class ComingSoonScreen extends StatelessWidget {
  final String label;

  const ComingSoonScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    // The back arrow has to point the other way in right-to-left.
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl ? Icons.arrow_forward : Icons.arrow_back,
                      color: colors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).comingSoonSuffix(label),
                    style: AppTextStyles.bodyMuted(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
