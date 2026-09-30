import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import 'screen_header.dart';

const _hairline = 0.515;

/// One heading and paragraph of a legal document.
class LegalSection {
  final String heading;
  final String body;

  const LegalSection(this.heading, this.body);
}

/// Shows the Privacy Policy or Terms of Service.
///
/// This is DRAFT placeholder text, not reviewed by a lawyer or approved by the company. The banner
/// at the top says so in the app too. Each document has English and Arabic versions, picked by the
/// app's language.
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;

  const LegalDocumentScreen({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: title, onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                _DraftBanner(text: l10n.legalDraftDisclaimer),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border, width: _hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final section in sections) ...[
                        Text(section.heading, style: AppTextStyles.heading2(context)),
                        const SizedBox(height: 8),
                        Text(
                          section.body,
                          style: TextStyle(fontSize: 14, height: 20 / 14, color: colors.textMuted),
                        ),
                        if (section != sections.last) const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  final String text;

  const _DraftBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, height: 18 / 12.5, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
