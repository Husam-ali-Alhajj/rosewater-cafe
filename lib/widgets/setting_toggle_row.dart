import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';

const _comingSoonInk = Color(0xFF99A1AF);
const _switchOn = Color(0xFFEC003F);
const _switchOff = Color(0xFFD1D5DC);

const _hairline = 0.515; // Figma's fractional hairline stroke width

/// One settings toggle: an icon, a 14px label over a 14px description, and a
/// switch at the right, all inside 16px padding, with a hairline divider below
/// (unless it's the last row in its card). Read from the Figma
/// "NotificationToggle" rows (Notifications node 1217:2554, Privacy & Security
/// node 1217:2653) -- the two screens share it.
///
/// An icon's frame in the design varies in size (15.31-20px); pass it as
/// [iconSize]. The text always starts 12px after the icon's right edge.
///
/// [onToggle] null means **disabled**: the switch is drawn dimmed, can't be
/// tapped, and announces itself as unavailable. [note] adds a small extra line
/// under the description (e.g. "(Coming Soon)", as the design labels Dark
/// Mode).
class SettingToggleRow extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final String description;
  final bool value;
  final VoidCallback? onToggle;
  final bool showDivider;
  final String? note;

  /// Set on the switch itself, so tests (and callers) can find it.
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
          ? BoxDecoration(border: Border(bottom: BorderSide(color: colors.border, width: _hairline)))
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
                          style: const TextStyle(fontSize: 12, height: 16 / 12, color: _comingSoonInk),
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

/// The design's switch (Figma e.g. node 1217:2564): a 44x24 pill, red
/// `#EC003F` when on and grey `#D1D5DC` when off, with a 16px white thumb 4px
/// in from the edge on either side. Announced to screen readers as a toggle
/// with its label. With a null [onTap] it is disabled: dimmed and inert.
class SettingSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback? onTap;

  const SettingSwitch({super.key, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
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
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              color: value ? _switchOn : _switchOff,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  left: value ? 24 : 4,
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
