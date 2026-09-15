import '../models/profile.dart';
import 'supabase_client.dart';

class ProfileService {
  const ProfileService();

  /// The current user's own profile row (RLS restricts this to their own
  /// row regardless of the `.eq('id', ...)` filter, which is kept anyway as
  /// defense in depth, same convention as SubscriptionService).
  Future<Profile?> fetchCurrentProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }
}
