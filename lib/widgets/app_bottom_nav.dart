import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_semantic_colors.dart';

class _BottomNavTabData {
  final IconData icon;
  final String label;
  const _BottomNavTabData({required this.icon, required this.label});
}

/// Sprint 8 Task 6: built inside `build()`, not as a top-level `const`
/// list, since the labels now come from `AppLocalizations` (needs a
/// `BuildContext`) instead of fixed string literals.
List<_BottomNavTabData> _tabs(AppLocalizations l10n) => [
  _BottomNavTabData(icon: Icons.home_outlined, label: l10n.navHome),
  _BottomNavTabData(icon: Icons.qr_code_outlined, label: l10n.navQrCode),
  _BottomNavTabData(icon: Icons.calendar_today_outlined, label: l10n.navEvents),
  _BottomNavTabData(icon: Icons.person_outline, label: l10n.navProfile),
];

/// Bottom navigation bar matching the Figma `BottomNav` component (node
/// 1216:2285) exactly: white background, 1px top border, 24px outline
/// icons, 12px labels (bold + accent color when active, regular + muted
/// gray otherwise), and a small 4px accent dot under the active tab's icon
/// -- all four values read directly off that node, not eyeballed.
///
/// One deliberate deviation from the Figma frame: tabs there hug their own
/// text width (a 375px-wide mock with per-label gaps); here each tab is
/// `Expanded` to equal width instead; a fixed-content-width nav bar looks
/// wrong the moment the device isn't exactly 375px wide, so this trades
/// exact-pixel-match for correctness at real screen widths.
///
/// **RTL note (Sprint 8 Task 6, decision #63):** needed NO layout changes
/// for Arabic -- every tab is a plain vertical `Column` (icon, dot, label),
/// with no left/right positioning to mirror, and the enclosing `Row`
/// already reverses its children's visual order automatically under RTL
/// `Directionality` (Flutter's default `Row` behavior, since this file
/// never overrides `textDirection`). Confirmed by reading the render logic,
/// not assumed -- see `test/app_bottom_nav_test.dart`'s RTL group.
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
                  child: _BottomNavButton(
                    data: tabs[i],
                    isActive: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
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
        // The active tab's icon sits 4px higher than an inactive one --
        // the 4px the accent dot below it takes up -- so every tab's
        // label still lands at the same baseline regardless of state.
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
