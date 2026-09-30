import '../models/app_notification.dart';
import 'supabase_client.dart';

/// The signed-in user's in-app notifications (`public.notifications`),
/// for the Notifications feed and the Home bell's unread badge.
///
/// Every row is written server-side (payment, reservation); a client may
/// only flip `is_read` (column-level grant) and delete its own rows. RLS
/// limits every read, update and delete to the caller's own rows, so no
/// query here needs its own `user_id` filter to be safe -- the `eq`s are
/// there to make the intent explicit, not for security.
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

  /// How many are unread, for the Home bell's badge.
  Future<int> unreadCount() async {
    final rows = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', _userId)
        .eq('is_read', false);
    return rows.length;
  }

  Future<void> markRead(String id) async {
    await supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('notifications').delete().eq('id', id);
  }
}
