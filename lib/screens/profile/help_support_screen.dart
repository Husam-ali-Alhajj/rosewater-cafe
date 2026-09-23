import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/coming_soon_screen.dart';
import '../../widgets/screen_header.dart';

// Values read from the Figma `HelpSupportScreen` frame (node 1217:3158) in
// the Figma app's Design panel -- the REST API was rate-limited when this was
// built (same as Privacy & Security, #45), so a few spacing values not read
// directly are noted below where they're used.
const _titleInk = Color(0xFF1E2939);
const _bodyInk = Color(0xFF4A5565);
const _chevronInk = Color(0xFF99A1AF);
const _rowDivider = Color(0xFFF3F4F6);
const _placeholderInk = Color(0xFF99A1AF);

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
const _faqItems = [
  _FaqItem(
    'How do I use my QR code to enter the café?',
    'Simply open the QR Code section from your dashboard, show it to the '
        'scanner at the entrance, and specify how many guests are with you.',
  ),
  _FaqItem('What happens when my monthly allowance runs out?', null),
  _FaqItem('Can I bring guests to the café?', null),
  _FaqItem("What's the difference between full service and self-service hours?", null),
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComingSoonScreen(label: label)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            // Figma's frame padding: 16 sides, 32 top; 32 below the last card.
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: 'Help & Support', onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                const _ContactCard(
                  icon: Icons.chat_bubble_outline,
                  // Confirmed via the Design panel.
                  iconColor: AppColors.bottomNavActive,
                  title: 'Live Chat',
                  description: 'Chat with our team',
                ),
                // Gap between the three contact cards -- not confirmed via
                // the API; 16 matches this app's usual gap between stacked
                // cards (e.g. Payment Methods' list, decision #43).
                const SizedBox(height: 16),
                const _ContactCard(
                  icon: Icons.mail_outline,
                  // Not confirmed via the API (rate-limited): inferred from
                  // the rendered design -- purple, matching the app's other
                  // membership-purple accents. Worth a real check once the
                  // API allows (same caveat as decision #20's early passes).
                  iconColor: Color(0xFF9810FA),
                  title: 'Email Us',
                  description: 'Get help via email',
                ),
                const SizedBox(height: 16),
                const _ContactCard(
                  icon: Icons.phone_outlined,
                  // Also inferred (green, matching the app's other
                  // confirmation/positive-action green) -- same caveat.
                  iconColor: Color(0xFF00A63E),
                  title: 'Call Us',
                  description: 'Speak to support',
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
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(height: 36),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 28 / 18,
              letterSpacing: -0.44,
              color: _titleInk,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            description,
            style: const TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: _bodyInk),
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: const Row(
              children: [
                Icon(Icons.help_outline, size: 20, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
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
          for (var i = 0; i < _faqItems.length; i++)
            _FaqRow(
              item: _faqItems[i],
              expanded: expandedIndex == i,
              onTap: () => onToggle(i),
              showDivider: i < _faqItems.length - 1,
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
    return Container(
      decoration: showDivider
          ? const BoxDecoration(border: Border(bottom: BorderSide(color: _rowDivider, width: _hairline)))
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
                        style: const TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          letterSpacing: -0.31,
                          color: _titleInk,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 150),
                      turns: expanded ? 0.25 : 0, // right-pointing -> down-pointing
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8, top: 2),
                        child: Icon(Icons.chevron_right, size: 20, color: _chevronInk),
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
                      style: const TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: _bodyInk),
                    )
                  : const Text(
                      // Deliberately NOT a fabricated answer -- see the class
                      // doc comment on HelpSupportScreen and decision #46.
                      'Answer not available yet.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        fontStyle: FontStyle.italic,
                        color: _placeholderInk,
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
    const resources = ['User Guide', 'Membership Benefits', 'Community Guidelines'];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _rowDivider, width: _hairline)),
            ),
            child: const Text(
              'Resources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 28 / 18,
                letterSpacing: -0.44,
                color: _titleInk,
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
                    ? const BoxDecoration(border: Border(bottom: BorderSide(color: _rowDivider, width: _hairline)))
                    : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        resources[i],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 24 / 16,
                          letterSpacing: -0.31,
                          color: _titleInk,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: _chevronInk),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
