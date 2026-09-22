import 'package:shared_preferences/shared_preferences.dart';

/// One notification preference. The first four are the "Communication
/// Preferences" toggles on the Notifications settings screen, the last three
/// the "Notification Types" toggles.
enum NotificationSetting {
  push(defaultValue: true),
  email(defaultValue: true),
  sms(defaultValue: false),
  sound(defaultValue: true),
  eventReminders(defaultValue: true),
  allowanceAlerts(defaultValue: true),
  promotions(defaultValue: true);

  /// What each toggle shows before the user has ever touched it -- the state
  /// drawn in the Figma frame (node 1217:2539): SMS off, everything else on.
  final bool defaultValue;

  const NotificationSetting({required this.defaultValue});
}

/// A snapshot of every notification preference.
class NotificationSettings {
  final Map<NotificationSetting, bool> _values;

  const NotificationSettings._(this._values);

  /// Every toggle at its default (what the design shows).
  factory NotificationSettings.defaults() => NotificationSettings._({
    for (final s in NotificationSetting.values) s: s.defaultValue,
  });

  bool isOn(NotificationSetting setting) => _values[setting] ?? setting.defaultValue;

  NotificationSettings copyWith(NotificationSetting setting, bool value) =>
      NotificationSettings._({..._values, setting: value});
}

/// Notification preferences, stored **only on this device** with
/// `shared_preferences` -- no table, no backend, no network.
///
/// That is the standing decision (Sprint 2 checkpoint): whether these belong in
/// the database is tied to the still-open question of what a notification even
/// is (the Home bell / notifications feed and its schema, decision #32), so no
/// backend storage is built for them while that's unresolved. This file and the
/// screen that uses it deliberately import nothing that can reach the network
/// (`test/notification_prefs_test.dart` checks that).
///
/// Keys are namespaced by [userId], so if two people sign in on the same phone
/// one person's choices don't silently become the other's. The caller passes
/// the id (read from the local session, which is not a network call); with
/// none, the settings belong to "the device".
class NotificationPrefs {
  final String? userId;

  const NotificationPrefs({this.userId});

  String _key(NotificationSetting setting) => 'notification_settings.${userId ?? 'device'}.${setting.name}';

  /// The saved value of every toggle, falling back to its default for any the
  /// user hasn't changed yet.
  Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    var settings = NotificationSettings.defaults();
    for (final setting in NotificationSetting.values) {
      final saved = prefs.getBool(_key(setting));
      if (saved != null) settings = settings.copyWith(setting, saved);
    }
    return settings;
  }

  /// Saves one toggle. Returns once it has been written to the device.
  Future<void> set(NotificationSetting setting, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(setting), value);
  }
}
