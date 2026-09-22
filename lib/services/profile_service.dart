import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'supabase_client.dart';

/// Thrown by [ProfileService.updateProfile] with a message that's already
/// safe to show the user directly.
class ProfileUpdateFailure implements Exception {
  final String message;
  const ProfileUpdateFailure(this.message);
}

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

  /// Saves the editable fields with a plain `profiles` UPDATE -- no RPC.
  /// This is exactly the kind of self-owned write decision #3 always allowed
  /// (unlike subscriptions / usage / door logs): the existing
  /// `auth.uid() = id` UPDATE policy already scopes it to the caller's own
  /// row. Only the three editable columns are ever sent. `email` is never
  /// sent (changing an auth email needs its own re-verification flow, and a
  /// database trigger keeps `profiles.email` from being changed by a client
  /// request anyway), and `member_id` is immutable by trigger.
  ///
  /// [avatarPath] is included only when a new photo was uploaded; null leaves
  /// the existing one untouched. Returns the saved row, so the caller can
  /// show exactly what's stored.
  Future<Profile> updateProfile({
    required String fullName,
    required String phone,
    String? avatarPath,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const ProfileUpdateFailure('Your session expired. Please sign in again.');
    }
    try {
      final row = await supabase
          .from('profiles')
          .update({
            'full_name': fullName,
            'phone': phone,
            'avatar_url': ?avatarPath,
          })
          .eq('id', userId)
          .select()
          .single();
      return Profile.fromJson(row);
    } on PostgrestException {
      // `.single()` also throws if the UPDATE matched no row (e.g. RLS
      // refused it) -- either way nothing was saved.
      throw const ProfileUpdateFailure("Couldn't save your changes. Please try again.");
    }
  }
}
