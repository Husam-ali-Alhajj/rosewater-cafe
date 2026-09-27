import 'supabase_client.dart';

/// One notification preference. The first four are the "Communication
/// Preferences" toggles on the Notifications settings screen, the last three
/// the "Notification Types" toggles.
enum NotificationSetting {
  push(column: 'push', defaultValue: true),
  email(column: 'email', defaultValue: true),
  sms(column: 'sms', defaultValue: false),
  sound(column: 'sound', defaultValue: true),
  eventReminders(column: 'event_reminders', defaultValue: true),
  allowanceAlerts(column: 'allowance_alerts', defaultValue: true),
  promotions(column: 'promotions', defaultValue: true);

  /// This toggle's column in `public.notification_preferences`.
  final String column;

  /// What each toggle shows before the user has ever touched it -- the state
  /// drawn in the Figma frame (node 1217:2539): SMS off, everything else on.
  /// Must match the column defaults in migration 20260930100000.
  final bool defaultValue;

  const NotificationSetting({required this.column, required this.defaultValue});
}

/// A snapshot of every notification preference.
class NotificationSettings {
  final Map<NotificationSetting, bool> _values;

  const NotificationSettings._(this._values);

  /// Every toggle at its default (what the design shows).
  factory NotificationSettings.defaults() => NotificationSettings._({
    for (final s in NotificationSetting.values) s: s.defaultValue,
  });

  /// From a `notification_preferences` row; null (the user has never
  /// changed anything, so has no row yet) or a missing/null column means
  /// that toggle's default.
  factory NotificationSettings.fromRow(Map<String, dynamic>? row) => NotificationSettings._({
    for (final s in NotificationSetting.values) s: (row?[s.column] as bool?) ?? s.defaultValue,
  });

  bool isOn(NotificationSetting setting) => _values[setting] ?? setting.defaultValue;

  NotificationSettings copyWith(NotificationSetting setting, bool value) =>
      NotificationSettings._({..._values, setting: value});
}

/// Where the Notification Settings screen reads and saves its toggles.
/// Abstract so the screen can be tested without a backend.
abstract class NotificationPrefs {
  const NotificationPrefs();

  /// The saved value of every toggle, falling back to its default for any the
  /// user hasn't changed yet.
  Future<NotificationSettings> load();

  /// Saves one toggle. Returns once it has been saved.
  Future<void> set(NotificationSetting setting, bool value);
}

/// The signed-in user's preferences in `public.notification_preferences`
/// (notifications roadmap step 1). Stored in the database, not on the
/// device, because the channels these toggles control -- email, push,
/// scheduled reminders -- are sent by the server, which can only respect a
/// choice it can read. Following the user rather than the phone also means
/// the same choices apply on every device they sign in on.
///
/// RLS limits every read and write to the caller's own row.
class SupabaseNotificationPrefs extends NotificationPrefs {
  const SupabaseNotificationPrefs();

  String get _userId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw StateError('not signed in');
    return id;
  }

  @override
  Future<NotificationSettings> load() async {
    final row = await supabase
        .from('notification_preferences')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();
    return NotificationSettings.fromRow(row);
  }

  /// An upsert of just this one column: creates the row on the first
  /// change (every other column takes its database default, which is the
  /// same as the app's), and updates only this column after that.
  @override
  Future<void> set(NotificationSetting setting, bool value) async {
    await supabase
        .from('notification_preferences')
        .upsert({'user_id': _userId, setting.column: value}, onConflict: 'user_id');
  }
}
