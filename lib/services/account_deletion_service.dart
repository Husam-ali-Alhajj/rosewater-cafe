import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'avatar_service.dart';
import 'id_document_service.dart';
import 'supabase_client.dart';

/// A delete-account error with a message safe to show. [field] is 'password' when it belongs to the
/// password field.
class DeleteAccountFailure implements Exception {
  final String message;
  final String? field;
  const DeleteAccountFailure(this.message, {this.field});
}

/// Deletes the user's account, in this order:
///
/// 1. Check the current password, so an unlocked phone can't be used to delete the account.
/// 2. Delete all the user's files (avatars and ID documents). This must happen first: storage isn't
/// linked to the account, and the user can no longer reach their files once the account is gone.
/// 3. Call delete_own_account, which deletes the account and, through cascades, all of its data.
///
/// If step 2 fails, nothing is deleted and the user can try again.
class AccountDeletionService {
  const AccountDeletionService({this.authService = const AuthService()});

  final AuthService authService;

  static const _cleanupBuckets = [AvatarService.bucket, IdDocumentService.bucket];

  /// Deletes the signed-in user's account. The caller signs out afterwards.
  Future<void> deleteAccount({required String currentPassword}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const DeleteAccountFailure('Your session expired. Please sign in again.');
    }

    // 1. Check the password.
    try {
      await authService.verifyCurrentPassword(currentPassword);
    } on ReauthenticationFailure catch (e) {
      throw DeleteAccountFailure(e.message, field: 'password');
    }

    // 2. Delete all stored files. A failure here stops everything.
    try {
      for (final bucket in _cleanupBuckets) {
        final files = await supabase.storage.from(bucket).list(path: userId);
        if (files.isEmpty) continue;
        await supabase.storage.from(bucket).remove([for (final f in files) '$userId/${f.name}']);
      }
    } catch (_) {
      throw const DeleteAccountFailure("Couldn't remove your stored files. Please try again.");
    }

    // 3. Delete the account.
    try {
      await supabase.rpc('delete_own_account');
    } on PostgrestException catch (e) {
      if (e.message == 'not_authenticated') {
        throw const DeleteAccountFailure('Your session expired. Please sign in again.');
      }
      throw const DeleteAccountFailure("Couldn't delete your account. Please try again.");
    } catch (_) {
      throw const DeleteAccountFailure("Couldn't delete your account. Check your connection and try again.");
    }
  }
}
