import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/notification_prefs.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/form_buttons.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/setting_toggle_row.dart';

const _hairline = 0.515; // Figma's fractional hairline stroke width

/// What one toggle row shows.
class _ToggleSpec {
  final NotificationSetting setting;
  final IconData icon;

  /// The design's icon frames are different sizes (15.31 to 20); kept as
  /// exported. The text always starts 12px after the icon's right edge.
  final double iconSize;
  final String label;
  final String description;

  const _ToggleSpec(this.setting, this.icon, this.iconSize, this.label, this.description);
}

List<_ToggleSpec> _communicationToggles(AppLocalizations l10n) => [
      _ToggleSpec(NotificationSetting.push, Icons.notifications_none, 20, l10n.pushNotificationsLabel,
          l10n.pushNotificationsDescription),
      _ToggleSpec(
          NotificationSetting.email, Icons.mail_outline, 20, l10n.emailNotificationsLabel, l10n.emailNotificationsDescription),
      _ToggleSpec(NotificationSetting.sms, Icons.chat_bubble_outline, 16.29, l10n.smsNotificationsLabel,
          l10n.smsNotificationsDescription),
      _ToggleSpec(NotificationSetting.sound, Icons.volume_up_outlined, 20, l10n.soundVibrationLabel,
          l10n.soundVibrationDescription),
    ];

List<_ToggleSpec> _typeToggles(AppLocalizations l10n) => [
      _ToggleSpec(NotificationSetting.eventReminders, Icons.calendar_today_outlined, 15.31, l10n.eventRemindersLabel,
          l10n.eventRemindersDescription),
      _ToggleSpec(NotificationSetting.allowanceAlerts, Icons.warning_amber_outlined, 18.49, l10n.allowanceAlertsLabel,
          l10n.allowanceAlertsDescription),
      _ToggleSpec(NotificationSetting.promotions, Icons.card_giftcard_outlined, 16.99, l10n.promotionsOffersLabel,
          l10n.promotionsOffersDescription),
    ];

/// Notification settings (Figma frame "NotificationsScreen", node
/// 1217:2539): four "Communication Preferences" toggles (Push, Email, SMS,
/// Sound & Vibration) and three "Notification Types" toggles (Event
/// Reminders, Allowance Alerts, Promotions & Offers), with a "Done" button.
///
/// **Local-only, on purpose.** Every toggle is saved to this device with
/// `shared_preferences` ([NotificationPrefs]) the moment it's flipped -- there
/// is no Save button in the design, and no table behind this screen. That is
/// the standing decision (Sprint 2 checkpoint): whether notification
/// preferences belong in the database is tied to the still-open question of
/// what a notification is (the Home bell / notifications feed, decision #32),
/// so no backend storage is built while that's unresolved. **This screen makes
/// no network calls at all** -- it and its preferences class import nothing that
/// can reach the network.
///
/// The toggles record preferences only: nothing in the app sends push, email
/// or SMS yet, so nothing acts on them yet either.
class NotificationSettingsScreen extends StatefulWidget {
  final NotificationPrefs prefs;

  const NotificationSettingsScreen({super.key, required this.prefs});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  NotificationSettings? _settings; // null until the saved values are read

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    NotificationSettings settings;
    try {
      settings = await widget.prefs.load();
    } catch (_) {
      settings = NotificationSettings.defaults(); // unreadable storage: show defaults, not a crash
    }
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  Future<void> _toggle(NotificationSetting setting) async {
    final current = _settings;
    if (current == null) return;
    final next = !current.isOn(setting);
    setState(() => _settings = current.copyWith(setting, next)); // shown immediately
    try {
      await widget.prefs.set(setting, next);
    } catch (_) {
      // The write failed, so don't leave the switch showing something that
      // won't be there next time.
      if (!mounted) return;
      setState(() => _settings = _settings?.copyWith(setting, !next));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).couldntSaveSettingError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.colors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            // Figma's frame padding: 16 sides, 32 top; 32 below the last button.
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: l10n.notificationsLabel, onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                if (settings == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _CommunicationCard(settings: settings, onToggle: _toggle),
                  const SizedBox(height: 24),
                  _TypesCard(settings: settings, onToggle: _toggle),
                ],
                const SizedBox(height: 24),
                CancelButton(label: l10n.doneButton, onTap: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One toggle row, built from the shared [SettingToggleRow].
Widget _row(
  _ToggleSpec spec,
  NotificationSettings settings,
  ValueChanged<NotificationSetting> onToggle, {
  required bool showDivider,
}) {
  return SettingToggleRow(
    icon: spec.icon,
    iconSize: spec.iconSize,
    label: spec.label,
    description: spec.description,
    value: settings.isOn(spec.setting),
    onToggle: () => onToggle(spec.setting),
    showDivider: showDivider,
    switchKey: ValueKey('toggle-${spec.setting.name}'),
  );
}

/// Themed card surface, 14px radius, hairline border; clips its children so
/// the gradient band's top corners follow the card's.
BoxDecoration _cardDecoration(AppSemanticColors colors) {
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: colors.border, width: _hairline),
  );
}

/// "Communication Preferences": a gradient title band, then four toggles 24px
/// apart (Figma node 1217:2548).
class _CommunicationCard extends StatelessWidget {
  final NotificationSettings settings;
  final ValueChanged<NotificationSetting> onToggle;

  const _CommunicationCard({required this.settings, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final toggles = _communicationToggles(l10n);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: colors.accentGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.communicationPreferencesTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
                    letterSpacing: -0.44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.communicationPreferencesSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    letterSpacing: -0.15,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < toggles.length; i++) ...[
            const SizedBox(height: 24),
            _row(toggles[i], settings, onToggle, showDivider: i < toggles.length - 1),
          ],
        ],
      ),
    );
  }
}

/// "Notification Types": a title strip, then three toggles 24px apart (Figma
/// node 1217:2602). The strip's light-grey fill is as exported.
class _TypesCard extends StatelessWidget {
  final NotificationSettings settings;
  final ValueChanged<NotificationSetting> onToggle;

  const _TypesCard({required this.settings, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final toggles = _typeToggles(l10n);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              height: 28,
              color: colors.inputFill,
              // Sprint 8 Task 6: was Alignment.centerLeft -- a physical
              // alignment that wouldn't flip to the trailing edge in RTL.
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.notificationTypesTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 28 / 18,
                  letterSpacing: -0.44,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          for (var i = 0; i < toggles.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            _row(toggles[i], settings, onToggle, showDivider: i < toggles.length - 1),
          ],
        ],
      ),
    );
  }
}
