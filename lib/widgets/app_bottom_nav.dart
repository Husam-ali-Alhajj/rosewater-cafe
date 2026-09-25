import 'package:flutter/material.dart';
import '../theme/app_semantic_colors.dart';

class _BottomNavTabData {
  final IconData icon;
  final String label;
  const _BottomNavTabData({required this.icon, required this.label});
}

const _tabs = [
  _BottomNavTabData(icon: Icons.home_outlined, label: 'Home'),
  _BottomNavTabData(icon: Icons.qr_code_outlined, label: 'QR Code'),
  _BottomNavTabData(icon: Icons.calendar_today_outlined, label: 'Events'),
  _BottomNavTabData(icon: Icons.person_outline, label: 'Profile'),
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
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _BottomNavButton(
                    data: _tabs[i],
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
