import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_semantic_colors.dart';

class _BottomNavTabData {
  final IconData icon;
  final String label;
  const _BottomNavTabData({required this.icon, required this.label});
}

/// Built in build() because the labels are translated.
List<_BottomNavTabData> _tabs(AppLocalizations l10n) => [
  _BottomNavTabData(icon: Icons.home_outlined, label: l10n.navHome),
  _BottomNavTabData(icon: Icons.qr_code_outlined, label: l10n.navQrCode),
  _BottomNavTabData(icon: Icons.calendar_today_outlined, label: l10n.navEvents),
  _BottomNavTabData(icon: Icons.person_outline, label: l10n.navProfile),
];

/// The bottom navigation bar from the design. The active tab is bold, in the accent colour, with a
/// small dot under its icon.
///
/// Unlike the design, each tab takes equal width, so it looks right on any screen size. Works in
/// right-to-left without changes: the Row reverses the tab order automatically.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tabs = _tabs(AppLocalizations.of(context));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _BottomNavButton(data: tabs[i], isActive: i == currentIndex, onTap: () => onTap(i)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final _BottomNavTabData data;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavButton({required this.data, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? context.colors.accent : context.colors.textMuted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        // The active icon sits 4px higher (the dot's space), so all labels line up.
        padding: EdgeInsets.only(top: isActive ? 4 : 8, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 24, color: color),
            const SizedBox(height: 4),
            if (isActive)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            Text(
              data.label,
              style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
