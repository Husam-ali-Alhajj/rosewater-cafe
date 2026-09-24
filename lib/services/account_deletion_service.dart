import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'avatar_service.dart';
import 'id_document_service.dart';
import 'supabase_client.dart';

/// Thrown by [AccountDeletionService.deleteAccount] with a message that's
/// already safe to show the user directly. [field] is `'password'` when the
/// failure belongs specifically to the current-password field (so the UI can
/// show it inline, the same way [ChangePasswordFailure] does); null means a
/// general failure not tied to any field.
class DeleteAccountFailure implements Exception {
  final String message;
  final String? field;
  const DeleteAccountFailure(this.message, {this.field});
}

/// "Delete Account", for real (docs/decisions.md #52 -- replacing the
/// request-queue of decision #45 after the user was shown that tradeoff and
/// explicitly asked for self-service deletion instead; hardened afterwards
/// with a current-password re-check and storage cleanup, decision TBD).
///
/// Deleting an account does three things, strictly in this order:
///
/// 1. **Re-authenticates with the current password** ([AuthService
///    .verifyCurrentPassword]) -- the same reasoning as Change Password: a
///    phone left unlocked shouldn't let anyone silently delete the account.
///    Nothing below happens unless this succeeds.
/// 2. **Removes every file this user ever stored**, in both the `avatars`
///    and `id-documents` buckets. This has to happen BEFORE the account row
///    is deleted, not after: `storage.objects` has no foreign key to
///    `auth.users` (confirmed during the original build), so deleting the
///    account does NOT cascade to storage -- and storage's own RLS policies
///    check the object's folder against `auth.uid()` of the CURRENT
///    session, which stops working the moment the account (and the session
///    tied to it) is gone. Skip this step or do it after, and every photo
///    and ID document a deleted user ever uploaded is left behind forever
///    with no owner and no way to reach it again.
/// 3. **Calls the `delete_own_account` RPC**, which reads `auth.uid()`
///    itself and deletes exactly the caller's own `auth.users` row --
///    nothing else can be targeted, by construction, not by a check this
///    class makes. Deleting that row cascades through every table of the
///    user's own data (profile, subscriptions, payment methods,
///    reservations, everything).
///
/// If step 2 fails partway (e.g. a network blip mid-cleanup), the whole
/// deletion is aborted -- step 3 is never reached. The account and every
/// file are left exactly as they were; the user sees an error and can just
/// try again. The account is never deleted while leaving orphaned files
/// behind.
class AccountDeletionService {
  const AccountDeletionService({this.authService = const AuthService()});

  final AuthService authService;

  static const _cleanupBuckets = [AvatarService.bucket, IdDocumentService.bucket];

  /// Permanently deletes the signed-in user's account after proving they
  /// know [currentPassword]. The caller is responsible for ending the local
  /// session afterwards (see `signOutAndShowLanding`) -- this call only
  /// removes the account and its files server-side, it doesn't touch the
  /// device's own session state.
  Future<void> deleteAccount({required String currentPassword}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const DeleteAccountFailure('Your session expired. Please sign in again.');
    }

    // 1. Prove the caller actually knows the current password before doing
    // anything irreversible.
    try {
      await authService.verifyCurrentPassword(currentPassword);
    } on ReauthenticationFailure catch (e) {
      throw DeleteAccountFailure(e.message, field: 'password');
    }

    // 2. Remove every file this user ever stored, in both buckets. See the
    // class doc above for why this must happen before step 3, and why a
    // failure here aborts the whole deletion instead of continuing anyway.
    try {
      for (final bucket in _cleanupBuckets) {
        final files = await supabase.storage.from(bucket).list(path: userId);
        if (files.isEmpty) continue;
        await supabase.storage.from(bucket).remove([for (final f in files) '$userId/${f.name}']);
      }
    } catch (_) {
      throw const DeleteAccountFailure("Couldn't remove your stored files. Please try again.");
    }

    // 3. Only now delete the account itself.
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
