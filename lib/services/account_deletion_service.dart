import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// Thrown by [AccountDeletionService.deleteAccount] with a message that's
/// already safe to show the user directly.
class DeleteAccountFailure implements Exception {
  final String message;
  const DeleteAccountFailure(this.message);
}

/// "Delete Account", for real (docs/decisions.md #52 -- replacing the
/// request-queue of decision #45 after the user was shown that tradeoff and
/// explicitly asked for self-service deletion instead).
///
/// Calls the `delete_own_account` RPC, which reads `auth.uid()` itself and
/// deletes exactly the caller's own `auth.users` row -- nothing else can be
/// targeted, by construction, not by a check this class makes. Deleting
/// that row cascades through every table of the user's own data (profile,
/// subscriptions, payment methods, reservations, everything), so a single
/// successful call here means the account and all its data are gone. There
/// is no undo, and no request queue standing between tapping the button and
/// it happening.
class AccountDeletionService {
  const AccountDeletionService();

  /// Permanently deletes the signed-in user's account. The caller is
  /// responsible for ending the local session afterwards (see
  /// `signOutAndShowLanding`) -- this call only removes the account
  /// server-side, it doesn't touch the device's own session state.
  Future<void> deleteAccount() async {
    if (supabase.auth.currentUser?.id == null) {
      throw const DeleteAccountFailure('Your session expired. Please sign in again.');
    }
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
