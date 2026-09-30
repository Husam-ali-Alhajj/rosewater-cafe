/// A row of `notifications`. Rows are created by the server; the app can only mark them read or
/// delete them.
///
/// [title]/[body] are an English fallback. The app shows text built from [type] + [data] in the
/// user's language (see notification_localization.dart).
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;

  /// The subscription or event reservation this notification is about.
  final String? relatedId;

  /// The details the notification reports; the shape depends on [type].
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
