import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/app_animations.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/coming_soon_screen.dart';
import '../../widgets/screen_header.dart';

// Values read from the Figma `HelpSupportScreen` frame (node 1217:3158) in
// the Figma app's Design panel -- the REST API was rate-limited when this was
// built (same as Privacy & Security, #45), so a few spacing values not read
// directly are noted below where they're used.
//
// Sprint 8 Task 2 (dark mode rebuild): the neutral ink/divider values above
// are now sourced from `context.colors`. The three contact-card icon colors
// (Live Chat pink, Email Us purple, Call Us green) stay fixed brand/accent
// colors in both themes, same as every other accent in this app.

const _hairline = 0.515; // Figma's fractional hairline stroke width

/// One FAQ item: the question, and either the one real answer or a marker
/// that no answer exists yet.
class _FaqItem {
  final String question;
  final String? answer; // null = not yet answered in the design export

  const _FaqItem(this.question, this.answer);
}

/// **Only the first answer is real, exported design copy.** The other three
/// questions are shown with their real question text but a plain "not
/// available yet" placeholder body -- never an invented answer standing in
/// for real content (see docs/decisions.md #46). This gap was already logged
/// (Sprint 2 checkpoint, decision #32/#45's open-questions list) as "only 1 of
/// 4 FAQ answers exported."
List<_FaqItem> _faqItems(AppLocalizations l10n) => [
      _FaqItem(l10n.faqQuestion1, l10n.faqAnswer1),
      _FaqItem(l10n.faqQuestion2, null),
      _FaqItem(l10n.faqQuestion3, null),
      _FaqItem(l10n.faqQuestion4, null),
    ];

/// Help & Support (Figma frame "HelpSupportScreen", node 1217:3158): three
/// static contact cards, an FAQ accordion, and a Resources list.
///
/// **Contact cards (Live Chat / Email Us / Call Us) are static, on purpose.**
/// The design shows only a label and a one-line description -- no actual
/// email address, phone number, or chat link -- so there is nothing to wire
/// up. They are plain display cards, not buttons: no live chat integration,
/// no `mailto:`/`tel:` intents, no backend.
///
/// **FAQ accordion:** the design exports only one real question-and-answer
/// pair; the other three questions are real (they're in the Figma text), but
/// their answers are not -- shown as "Answer not available yet." rather than
/// invented copy. Expand/collapse is exclusive (opening one closes any other),
/// the first item starts open, matching the one state the design shows.
///
/// **Resources** (User Guide / Membership Benefits / Community Guidelines)
/// have no content behind them yet -- each opens a `ComingSoonScreen`, the
/// same pattern as Privacy & Security's Privacy Policy / Terms of Service.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedIndex = 0; // the design's one exported state: item 0 open

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
            // Figma's frame padding: 16 sides, 32 top; 32 below the last card.
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: l10n.helpSupportLabel, onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                _ContactCard(
                  icon: Icons.chat_bubble_outline,
                  // The design's own accent color -- now theme-aware so it
                  // goes blue in dark mode along with every other accent use.
                  iconColor: context.colors.accent,
                  title: l10n.liveChatTitle,
                  description: l10n.liveChatDescription,
                ),
                // Gap between the three contact cards -- not confirmed via
                // the API; 16 matches this app's usual gap between stacked
                // cards (e.g. Payment Methods' list, decision #43).
                const SizedBox(height: 16),
                _ContactCard(
                  icon: Icons.mail_outline,
                  // Not confirmed via the API (rate-limited): inferred from
                  // the rendered design -- purple, matching the app's other
                  // membership-purple accents. Worth a real check once the
                  // API allows (same caveat as decision #20's early passes).
                  iconColor: const Color(0xFF9810FA),
                  title: l10n.emailUsTitle,
                  description: l10n.emailUsDescription,
                ),
                const SizedBox(height: 16),
                _ContactCard(
                  icon: Icons.phone_outlined,
                  // Also inferred (green, matching the app's other
                  // confirmation/positive-action green) -- same caveat.
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

/// One static contact card: an icon, 36px below it the title, 36px below
/// that the description -- all left-aligned (Figma "Card", e.g. node
/// 1217:3168). No backend, not tappable.
class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      // Figma: left 24, top 24, bottom 24; right read as 0, which would run
      // text to the card's edge -- almost certainly the same kind of export
      // quirk decision #28 already found in this file (a shadcn/React layout
      // whose geometry doesn't survive the Figma import literally). Kept
      // symmetric at 24, matching every other card in this app, rather than
      // reproduced literally.
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
              fontWeight: FontWeight.w500,
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

/// The FAQ card: a gradient title band, then the accordion rows (Figma node
/// 1217:3169: card 343x486, header band, rows container).
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
                    fontWeight: FontWeight.w500,
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

/// One accordion row: a tappable question (16px, a chevron that rotates from
/// pointing right to pointing down) and, when expanded, its answer below --
/// Figma "Details" nodes (e.g. 1217:3199), which literally export as HTML
/// `<details>`/`<summary>` elements: this widget reproduces that semantics
/// (only one row's content exists in the DOM/tree at a time, driven by
/// [expanded]) rather than just hiding it visually.
class _FaqRow extends StatelessWidget {
  final _FaqItem item;
  final bool expanded;
  final VoidCallback onTap;
  final bool showDivider;

  const _FaqRow({
    required this.item,
    required this.expanded,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: showDivider
          ? BoxDecoration(border: Border(bottom: BorderSide(color: colors.border, width: _hairline)))
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
                      turns: expanded ? 0.25 : 0, // right-pointing -> down-pointing
                      child: Padding(
                        // Sprint 8 Task 6: the gap between the question text
                        // and this chevron -- EdgeInsetsDirectional so it
                        // stays on the chevron's near side in RTL too.
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
              child: item.answer != null
                  ? Text(
                      item.answer!,
                      style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
                    )
                  : Text(
                      // Deliberately NOT a fabricated answer -- see the class
                      // doc comment on HelpSupportScreen and decision #46.
                      AppLocalizations.of(context).faqAnswerNotAvailable,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        fontStyle: FontStyle.italic,
                        color: colors.textMuted,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// "Resources": a plain card title, then three link-style rows (Figma
/// mirrors the Password/Privacy card shape -- title with a hairline
/// underline, 24 below it the rows).
class _ResourcesCard extends StatelessWidget {
  final ValueChanged<String> onOpen;

  const _ResourcesCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    // Sprint 8 Task 6: same "leads forward" reasoning as ProfileScreen's
    // _SettingsRow -- this chevron flips in RTL, unlike the FAQ accordion's
    // own chevron (a rotation-driven open/closed state, not a navigation cue).
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
              border: Border(bottom: BorderSide(color: colors.border, width: _hairline)),
            ),
            child: Text(
              l10n.resourcesCardTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
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
                    ? BoxDecoration(border: Border(bottom: BorderSide(color: colors.border, width: _hairline)))
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
