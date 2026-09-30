import '../models/app_notification.dart';
import 'supabase_client.dart';

/// The user's notifications, for the notifications screen and the Home bell badge. Rows are created
/// by the server; users can only mark their own as read or delete them.
class NotificationService {
  const NotificationService();

  String get _userId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw StateError('not signed in');
    return id;
  }

  /// Newest first.
  Future<List<AppNotification>> fetchAll() async {
    final rows = await supabase
        .from('notifications')
        .select('id, type, title, body, is_read, related_id, data, created_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(AppNotification.fromMap).toList();
  }

  /// Number of unread notifications.
  Future<int> unreadCount() async {
    final rows = await supabase.from('notifications').select('id').eq('user_id', _userId).eq('is_read', false);
    return rows.length;
  }

  Future<void> markRead(String id) async {
    await supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('notifications').delete().eq('id', id);
  }
}
