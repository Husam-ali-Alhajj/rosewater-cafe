import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/app_animations.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/coming_soon_screen.dart';
import '../../widgets/screen_header.dart';

// Colours for this screen come from the theme. The three contact icons keep their own colours in
// both themes.

const _hairline = 0.515;

/// One FAQ item. [isDraft] marks answers written by us rather than taken from the design.
class _FaqItem {
  final String question;
  final String answer;
  final bool isDraft;

  const _FaqItem(this.question, this.answer, {this.isDraft = false});
}

/// Only the first answer comes from the design. The other three are draft answers based on how the
/// app works, marked in the app as not yet confirmed by the company.
List<_FaqItem> _faqItems(AppLocalizations l10n) => [
  _FaqItem(l10n.faqQuestion1, l10n.faqAnswer1),
  _FaqItem(l10n.faqQuestion2, l10n.faqAnswer2, isDraft: true),
  _FaqItem(l10n.faqQuestion3, l10n.faqAnswer3, isDraft: true),
  _FaqItem(l10n.faqQuestion4, l10n.faqAnswer4, isDraft: true),
];

/// Help & Support: contact cards, an FAQ and a Resources list.
///
/// The contact cards are display only: the design has no real email, phone number or chat link to
/// use. The FAQ opens one question at a time, with the first one open. The Resources links have no
/// content yet and open a "coming soon" screen.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedIndex = 0;

  void _toggle(int index) {
    setState(() => _expandedIndex = _expandedIndex == index ? null : index);
  }

  void _openComingSoon(String label) {
    Navigator.of(context).push(appRoute(context, (_) => ComingSoonScreen(label: label)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.colors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: l10n.helpSupportLabel, onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                _ContactCard(
                  icon: Icons.chat_bubble_outline,
                  iconColor: context.colors.accent,
                  title: l10n.liveChatTitle,
                  description: l10n.liveChatDescription,
                ),
                const SizedBox(height: 16),
                _ContactCard(
                  icon: Icons.mail_outline,
                  // Purple, matching the app's other membership accents.
                  iconColor: const Color(0xFF9810FA),
                  title: l10n.emailUsTitle,
                  description: l10n.emailUsDescription,
                ),
                const SizedBox(height: 16),
                _ContactCard(
                  icon: Icons.phone_outlined,
                  // Green, matching the app's other positive actions.
                  iconColor: const Color(0xFF00A63E),
                  title: l10n.callUsTitle,
                  description: l10n.callUsDescription,
                ),
                const SizedBox(height: 24),
                _FaqCard(expandedIndex: _expandedIndex, onToggle: _toggle),
                const SizedBox(height: 24),
                _ResourcesCard(onOpen: _openComingSoon),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One contact card: icon, title and description. Not tappable.
class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _ContactCard({required this.icon, required this.iconColor, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      // Even padding on all sides, like the app's other cards.
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(height: 36),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 28 / 18,
              letterSpacing: -0.44,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            description,
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// The FAQ card: a gradient title, then the questions.
class _FaqCard extends StatelessWidget {
  final int? expandedIndex;
  final ValueChanged<int> onToggle;

  const _FaqCard({required this.expandedIndex, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final items = _faqItems(l10n);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: colors.accentGradient),
            child: Row(
              children: [
                const Icon(Icons.help_outline, size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  l10n.faqCardTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
                    letterSpacing: -0.44,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++)
            _FaqRow(
              item: items[i],
              expanded: expandedIndex == i,
              onTap: () => onToggle(i),
              showDivider: i < items.length - 1,
            ),
        ],
      ),
    );
  }
}

/// One FAQ row: the question with a chevron, and the answer when it's open. Only the open answer is
/// built.
class _FaqRow extends StatelessWidget {
  final _FaqItem item;
  final bool expanded;
  final VoidCallback onTap;
  final bool showDivider;

  const _FaqRow({required this.item, required this.expanded, required this.onTap, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border, width: _hairline),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Semantics(
              button: true,
              expanded: expanded,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          letterSpacing: -0.31,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: context.animDuration(const Duration(milliseconds: 150)),
                      turns: expanded ? 0.25 : 0,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8, top: 2),
                        child: Icon(Icons.chevron_right, size: 20, color: colors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.answer,
                    style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
                  ),
                  if (item.isDraft) ...[
                    const SizedBox(height: 8),
                    Text(
                      // Shown under draft answers.
                      AppLocalizations.of(context).faqDraftAnswerNote,
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontStyle: FontStyle.italic,
                        color: colors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The Resources card: a title and three link rows.
class _ResourcesCard extends StatelessWidget {
  final ValueChanged<String> onOpen;

  const _ResourcesCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    // This chevron points "forward", so it flips in right-to-left (unlike the FAQ chevron, which
    // only shows open/closed).
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final resources = [l10n.userGuideLabel, l10n.membershipBenefitsLabel, l10n.communityGuidelinesLabel];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border, width: _hairline),
              ),
            ),
            child: Text(
              l10n.resourcesCardTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 28 / 18,
                letterSpacing: -0.44,
                color: colors.textPrimary,
              ),
            ),
          ),
          for (var i = 0; i < resources.length; i++)
            InkWell(
              onTap: () => onOpen(resources[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 48,
                decoration: i < resources.length - 1
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colors.border, width: _hairline),
                        ),
                      )
                    : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        resources[i],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 24 / 16,
                          letterSpacing: -0.31,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(isRtl ? Icons.chevron_left : Icons.chevron_right, size: 20, color: colors.textMuted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
