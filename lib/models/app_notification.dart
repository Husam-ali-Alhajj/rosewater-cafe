/// One row of `public.notifications` (Sprint 9 Task 1). Every row is
/// written server-side by a SECURITY DEFINER function; the only thing a
/// client may change is [isRead] (column-level grant).
///
/// [title]/[body] are the English text baked at insert time -- a fallback
/// only. What the app actually shows comes from [type] + [data] via
/// `localizeNotification` (utils/notification_localization.dart), so the
/// text follows the active language, including after a language switch.
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;

  /// The subscriptions.id / event_reservations.id that triggered this row,
  /// depending on [type].
  final String? relatedId;

  /// The facts this notification reports; shape depends on [type] (see
  /// migration 20260929100000's header).
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.relatedId,
    required this.data,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String?,
      isRead: map['is_read'] as bool? ?? false,
      relatedId: map['related_id'] as String?,
      data: (map['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
