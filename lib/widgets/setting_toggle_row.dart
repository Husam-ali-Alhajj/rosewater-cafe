import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';
import '../utils/app_animations.dart';

const _switchOn = Color(0xFFEC003F);

const _hairline = 0.515;

/// One settings row: icon, label, description and a switch, with a divider below (except the last
/// row). [iconSize] varies as in the design.
///
/// A null [onToggle] disables the row (dimmed and not tappable). [note] adds a small extra line,
/// like "(Coming Soon)".
class SettingToggleRow extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final String description;
  final bool value;
  final VoidCallback? onToggle;
  final bool showDivider;
  final String? note;

  /// Set on the switch so tests can find it.
  final Key? switchKey;

  const SettingToggleRow({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.description,
    required this.value,
    required this.onToggle,
    required this.showDivider,
    this.note,
    this.switchKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border, width: _hairline),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(icon, size: iconSize, color: colors.textMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          letterSpacing: -0.15,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
                      ),
                      if (note != null)
                        Text(
                          note!,
                          style: TextStyle(fontSize: 12, height: 16 / 12, color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SettingSwitch(key: switchKey, label: label, value: value, onTap: onToggle),
        ],
      ),
    );
  }
}

/// The design's switch: a pill that's red when on and grey when off, with a white thumb. Disabled
/// when [onTap] is null.
class SettingSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback? onTap;

  const SettingSwitch({super.key, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    // Its own grey instead of a card colour: in light mode that would be white on a white card, so
    // the switch would be invisible.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final switchOff = isDark ? const Color(0xFF4A4152) : const Color(0xFFD1D5DC);
    return Semantics(
      toggled: value,
      label: label,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: context.animDuration(const Duration(milliseconds: 150)),
            width: 44,
            height: 24,
            decoration: BoxDecoration(color: value ? _switchOn : switchOff, borderRadius: BorderRadius.circular(12)),
            child: Stack(
              children: [
                // The thumb slides toward the correct side in right-to-left too.
                AnimatedPositionedDirectional(
                  duration: context.animDuration(const Duration(milliseconds: 150)),
                  start: value ? 24 : 4,
                  top: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
