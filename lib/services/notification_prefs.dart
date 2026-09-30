import 'supabase_client.dart';

/// One notification switch: four channels, then three notification types.
enum NotificationSetting {
  push(column: 'push', defaultValue: true),
  email(column: 'email', defaultValue: true),
  sms(column: 'sms', defaultValue: false),
  sound(column: 'sound', defaultValue: true),
  eventReminders(column: 'event_reminders', defaultValue: true),
  allowanceAlerts(column: 'allowance_alerts', defaultValue: true),
  promotions(column: 'promotions', defaultValue: true);

  /// This switch's column in `notification_preferences`.
  final String column;

  /// The starting value (SMS off, the rest on). Must match the database column defaults.
  final bool defaultValue;

  const NotificationSetting({required this.column, required this.defaultValue});
}

/// All notification switches.
class NotificationSettings {
  final Map<NotificationSetting, bool> _values;

  const NotificationSettings._(this._values);

  /// Every switch at its default.
  factory NotificationSettings.defaults() =>
      NotificationSettings._({for (final s in NotificationSetting.values) s: s.defaultValue});

  /// From a database row. No row yet (never changed), or an empty column, means the default.
  factory NotificationSettings.fromRow(Map<String, dynamic>? row) => NotificationSettings._({
    for (final s in NotificationSetting.values) s: (row?[s.column] as bool?) ?? s.defaultValue,
  });

  bool isOn(NotificationSetting setting) => _values[setting] ?? setting.defaultValue;

  NotificationSettings copyWith(NotificationSetting setting, bool value) =>
      NotificationSettings._({..._values, setting: value});
}

/// Loads and saves the switches. Abstract so the screen can be tested without a backend.
abstract class NotificationPrefs {
  const NotificationPrefs();

  /// Every switch, using the default for any never changed.
  Future<NotificationSettings> load();

  /// Saves one switch.
  Future<void> set(NotificationSetting setting, bool value);
}

/// The user's switches, stored in the database so the server can respect them (for example, when
/// sending emails). They follow the user across devices. Users can only read and change their own
/// row.
class SupabaseNotificationPrefs extends NotificationPrefs {
  const SupabaseNotificationPrefs();

  String get _userId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw StateError('not signed in');
    return id;
  }

  @override
  Future<NotificationSettings> load() async {
    final row = await supabase.from('notification_preferences').select().eq('user_id', _userId).maybeSingle();
    return NotificationSettings.fromRow(row);
  }

  /// Saves just this column. Creates the row on first use; the other columns get their defaults.
  @override
  Future<void> set(NotificationSetting setting, bool value) async {
    await supabase.from('notification_preferences').upsert({
      'user_id': _userId,
      setting.column: value,
    }, onConflict: 'user_id');
  }
}
