import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'supabase_client.dart';

/// A profile-save error with a message safe to show.
class ProfileUpdateFailure implements Exception {
  final String message;
  const ProfileUpdateFailure(this.message);
}

class ProfileService {
  const ProfileService();

  /// The user's own profile.
  Future<Profile?> fetchCurrentProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  /// Saves the editable fields (name, phone, photo). Email and member ID are never sent; the
  /// database protects them anyway.
  ///
  /// [avatarPath] is only sent when there's a new photo. Returns the saved row.
  Future<Profile> updateProfile({required String fullName, required String phone, String? avatarPath}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const ProfileUpdateFailure('Your session expired. Please sign in again.');
    }
    try {
      final row = await supabase
          .from('profiles')
          .update({'full_name': fullName, 'phone': phone, 'avatar_url': ?avatarPath})
          .eq('id', userId)
          .select()
          .single();
      return Profile.fromJson(row);
    } on PostgrestException {
      // `.single()` also throws if no row was updated, so either way nothing was saved.
      throw const ProfileUpdateFailure("Couldn't save your changes. Please try again.");
    }
  }
}
