import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'supabase_client.dart';

/// Thrown for a signup failure with a message that's already safe and
/// specific enough to show the user directly (never a raw stack trace).
/// [field] names which form field the error belongs to ('email' or
/// 'password'), so the UI can show it inline instead of a generic banner;
/// null means it isn't tied to a specific field.
class SignUpFailure implements Exception {
  final String message;
  final String? field;
  const SignUpFailure(this.message, {this.field});
}

/// Thrown for a sign-in failure. Deliberately carries only one possible
/// message for any credential-related problem — see [AuthService.signIn].
class SignInFailure implements Exception {
  final String message;
  const SignInFailure(this.message);
}

/// Thrown ONLY for a genuine technical failure requesting a password reset
/// (bad format that slipped past client validation, rate limiting, network
/// error) — never for "this email isn't registered", since that case must
/// be indistinguishable from success. See [AuthService.resetPassword].
class ResetPasswordFailure implements Exception {
  final String message;
  const ResetPasswordFailure(this.message);
}

/// Thrown by [AuthService.changePassword] with a message that's already safe
/// to show the user directly. [field] says which form field it belongs to
/// (`'current'` or `'new'`) so the UI can show it inline; null means it isn't
/// tied to a field.
class ChangePasswordFailure implements Exception {
  final String message;
  final String? field;
  const ChangePasswordFailure(this.message, {this.field});
}

/// Thrown by [AuthService.verifyCurrentPassword] with a message that's
/// already safe to show the user directly.
class ReauthenticationFailure implements Exception {
  final String message;
  const ReauthenticationFailure(this.message);
}

/// Thrown by [AuthService.completePasswordRecovery] with a message that's
/// already safe to show the user directly. [field] is `'password'` when the
/// failure belongs specifically to the new-password field (so the UI can
/// show it inline, the same shape [ChangePasswordFailure] already uses);
/// null means a general failure not tied to any field.
class SetNewPasswordFailure implements Exception {
  final String message;
  final String? field;
  const SetNewPasswordFailure(this.message, {this.field});
}

/// Thrown by [AuthService.changeEmail] with a message that's already safe to
/// show the user directly. [field] is `'password'` or `'email'` so the UI
/// can show it under the right field, the same shape every other sensitive
/// action's failure type in this file already uses; null means a general
/// failure not tied to either.
class ChangeEmailFailure implements Exception {
  final String message;
  final String? field;
  const ChangeEmailFailure(this.message, {this.field});
}

class AuthService {
  /// [auth] exists only so tests can substitute a fake auth client; the app
  /// always uses the real one from the shared Supabase client.
  const AuthService({GoTrueClient? auth}) : _authOverride = auth;

  final GoTrueClient? _authOverride;
  GoTrueClient get _auth => _authOverride ?? supabase.auth;

  static const _invalidCredentials = SignInFailure('Invalid email or password.');

  /// The signed-in user's current login email, or null if nobody's signed
  /// in. A getter (not a field) so callers -- e.g. `PrivacySecurityScreen`'s
  /// Email card -- always see the live value, not a stale snapshot; a fake
  /// in a widget test overrides this instead of needing a live Supabase
  /// client just to render what email is on screen.
  String? get currentUserEmail => _auth.currentUser?.email;

  /// The new email address a pending [changeEmail] request is still waiting
  /// to be confirmed for, or null if there's no change in progress. Reflects
  /// real server state (from the user object Supabase itself returns), not
  /// anything cached locally -- so it's still correct if the confirmation
  /// link gets clicked on a different device, or this screen is reopened
  /// long after the request was made.
  String? get pendingEmailChange => _auth.currentUser?.newEmail;

  /// Signs in with email + password. Deliberately reports the exact same
  /// message for every credential-related failure — wrong email, wrong
  /// password, and even an unconfirmed account all look identical to the
  /// caller. Distinguishing any of these would let a login form be used to
  /// enumerate which emails have accounts (submit a guessed email, see if
  /// the error changes) — the security goal here is that a login attempt
  /// must never reveal whether an email is registered at all.
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw _signInMessageFor(e);
    }
  }

  SignInFailure _signInMessageFor(AuthException e) {
    switch (e.code) {
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        // Rate limiting doesn't leak account existence — it's fine, and
        // more helpful, to name it specifically.
        return const SignInFailure('Too many attempts. Please wait a moment and try again.');
    }
    // Every other case — including "email_not_confirmed", which Supabase
    // *does* report distinctly from wrong-password — collapses to the same
    // generic message on purpose. A real user who forgot to confirm their
    // email gets no specific hint why login failed; that's an accepted UX
    // cost for the stated goal of never confirming an email is registered.
    return _invalidCredentials;
  }

  /// Requests a password-reset email. Deliberately does NOT distinguish
  /// "email not found" from "email sent" — verified directly against the
  /// live API (see docs/decisions.md) that Supabase's own /auth/v1/recover
  /// endpoint already returns an identical 200 response either way, so no
  /// decoy-detection is needed here the way signUp() needed one. The only
  /// failures surfaced distinctly are ones that can't leak account
  /// existence: a malformed email (same for every caller, registered or
  /// not) and rate limiting.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email, redirectTo: SupabaseConfig.authRedirectUrl);
    } on AuthException catch (e) {
      switch (e.code) {
        case 'over_email_send_rate_limit':
        case 'over_request_rate_limit':
          throw const ResetPasswordFailure('Too many attempts. Please wait a moment and try again.');
        case 'validation_failed':
          throw const ResetPasswordFailure('Enter a valid email address.');
      }
      throw const ResetPasswordFailure('Something went wrong. Check your connection and try again.');
    }
  }

  /// Changes the signed-in user's password -- and only after proving they know
  /// the CURRENT one.
  ///
  /// Supabase's `updateUser(password:)` does not ask for the current password:
  /// anyone holding a live session could change it. That's the risk here -- a
  /// phone left unlocked and open could have its password silently changed by
  /// someone else, locking the real owner out. So before touching anything, this
  /// re-authenticates with the user's own email and the password they just typed
  /// (`signInWithPassword`); if that fails, **`updateUser` is never called**.
  ///
  /// After a successful change it also signs out every OTHER session (other
  /// devices), best effort -- a stolen session shouldn't survive the password
  /// that was changed to lock it out. The current session stays signed in.
  ///
  /// Every failure is a [ChangePasswordFailure] with a user-safe message; a raw
  /// auth error never reaches the UI.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final email = _auth.currentUser?.email;
    if (email == null) {
      throw const ChangePasswordFailure('Your session expired. Please sign in again.');
    }

    // 1. Re-authenticate with the current password. Nothing is changed unless this succeeds.
    try {
      await _auth.signInWithPassword(email: email, password: currentPassword);
    } on AuthException catch (e) {
      switch (e.code) {
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          throw const ChangePasswordFailure('Too many attempts. Please wait a moment and try again.');
        case 'invalid_credentials':
          throw const ChangePasswordFailure('Current password is incorrect.', field: 'current');
      }
      // Older/self-hosted versions don't always set `code`.
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw const ChangePasswordFailure('Current password is incorrect.', field: 'current');
      }
      throw const ChangePasswordFailure(
        "Couldn't verify your current password. Check your connection and try again.",
      );
    } catch (_) {
      throw const ChangePasswordFailure(
        "Couldn't verify your current password. Check your connection and try again.",
      );
    }

    // 2. Only now change it.
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      switch (e.code) {
        case 'same_password':
          throw const ChangePasswordFailure(
            'Choose a password different from your current one.',
            field: 'new',
          );
        case 'weak_password':
          throw const ChangePasswordFailure(
            'That password is too weak. Use at least 8 characters with upper and lower case letters and a number.',
            field: 'new',
          );
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          throw const ChangePasswordFailure('Too many attempts. Please wait a moment and try again.');
      }
      throw const ChangePasswordFailure("Couldn't update your password. Please try again.");
    } catch (_) {
      throw const ChangePasswordFailure(
        "Couldn't update your password. Check your connection and try again.",
      );
    }

    // 3. Best effort: end every other session. Failing to is not a failure of
    // the password change, which has already happened.
    try {
      await _auth.signOut(scope: SignOutScope.others);
    } catch (_) {}
  }

  /// Re-authenticates the signed-in user with [currentPassword] -- proving
  /// they actually know it -- without changing anything. This is the same
  /// re-authentication step [changePassword] does before touching the
  /// password, pulled out on its own so another irreversible action can
  /// reuse the exact same check: Delete Account calls this before deleting
  /// anything, for the same reason -- a phone left unlocked shouldn't let
  /// anyone silently delete the account any more than it should let them
  /// silently change the password.
  Future<void> verifyCurrentPassword(String currentPassword) async {
    final email = _auth.currentUser?.email;
    if (email == null) {
      throw const ReauthenticationFailure('Your session expired. Please sign in again.');
    }
    try {
      await _auth.signInWithPassword(email: email, password: currentPassword);
    } on AuthException catch (e) {
      switch (e.code) {
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          throw const ReauthenticationFailure('Too many attempts. Please wait a moment and try again.');
        case 'invalid_credentials':
          throw const ReauthenticationFailure('Current password is incorrect.');
      }
      // Older/self-hosted versions don't always set `code`.
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw const ReauthenticationFailure('Current password is incorrect.');
      }
      throw const ReauthenticationFailure(
        "Couldn't verify your current password. Check your connection and try again.",
      );
    } catch (_) {
      throw const ReauthenticationFailure(
        "Couldn't verify your current password. Check your connection and try again.",
      );
    }
  }

  /// Sets a new password inside an active password-recovery session -- the
  /// one Supabase creates automatically the moment a recovery email link is
  /// opened (see `AuthChangeEvent.passwordRecovery`, listened for in
  /// `auth_deep_link_listener.dart`). Unlike [changePassword], there's no
  /// "current password" to re-check here: the recovery token itself, not a
  /// password the user typed, is what already proved this is really them --
  /// the whole point of Forgot Password is that they don't remember it.
  Future<void> completePasswordRecovery(String newPassword) async {
    if (_auth.currentUser == null) {
      throw const SetNewPasswordFailure('This reset link has expired. Please request a new one.');
    }
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      switch (e.code) {
        case 'same_password':
          throw const SetNewPasswordFailure('Choose a password different from your previous one.', field: 'password');
        case 'weak_password':
          throw const SetNewPasswordFailure(
            'That password is too weak. Use at least 8 characters with upper and lower case letters and a number.',
            field: 'password',
          );
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          throw const SetNewPasswordFailure('Too many attempts. Please wait a moment and try again.');
      }
      throw const SetNewPasswordFailure("Couldn't update your password. Please try again.");
    } catch (_) {
      throw const SetNewPasswordFailure("Couldn't update your password. Check your connection and try again.");
    }
  }

  /// Changes the signed-in user's login email -- after proving they know the
  /// current password first, the same reasoning [changePassword] and account
  /// deletion already use for a sensitive action (decision #57).
  ///
  /// This only ever *requests* the change: Supabase sends a confirmation
  /// link to [newEmail], and the change doesn't take effect until that's
  /// clicked ("Secure email change" is off for this project, so only the new
  /// address needs to confirm -- see decision #57). The current email keeps
  /// working for sign-in the entire time; nothing here ends the local
  /// session or requires any follow-up action once the link is clicked --
  /// the actual `auth.users.email` update happens server-side, at Supabase's
  /// own `/verify` step, before the browser is ever redirected back.
  Future<void> changeEmail({required String currentPassword, required String newEmail}) async {
    // 1. Prove the caller actually knows the current password before
    // requesting anything.
    try {
      await verifyCurrentPassword(currentPassword);
    } on ReauthenticationFailure catch (e) {
      throw ChangeEmailFailure(e.message, field: 'password');
    }

    // 2. Only now request the change.
    try {
      await _auth.updateUser(UserAttributes(email: newEmail), emailRedirectTo: SupabaseConfig.authRedirectUrl);
    } on AuthException catch (e) {
      switch (e.code) {
        case 'email_exists':
        case 'user_already_exists':
          throw const ChangeEmailFailure(
            'An account with this email already exists.',
            field: 'email',
          );
        case 'validation_failed':
          throw const ChangeEmailFailure('Enter a valid email address.', field: 'email');
        case 'over_email_send_rate_limit':
        case 'over_request_rate_limit':
          throw const ChangeEmailFailure('Too many attempts. Please wait a moment and try again.');
      }
      throw const ChangeEmailFailure("Couldn't update your email. Please try again.");
    } catch (_) {
      throw const ChangeEmailFailure("Couldn't update your email. Check your connection and try again.");
    }
  }

  static const _emailInUseFailure = SignUpFailure(
    'An account with this email already exists. Try signing in instead.',
    field: 'email',
  );

  /// Creates the auth.users row and, via the handle_new_user trigger,
  /// the matching profiles row — full_name/phone travel as signup metadata
  /// so profile creation is atomic with signup, not a separate write.
  ///
  /// Returns whether a session was actually created. If the project
  /// requires email confirmation, `signUp()` succeeds but returns no
  /// session until the user clicks the confirmation link — the caller MUST
  /// check this before treating the user as logged in, or it will route an
  /// unconfirmed, unauthenticated user to a screen that assumes they're
  /// signed in.
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
      // Supabase deliberately does NOT throw for a duplicate, already-
      // confirmed email — to avoid letting the signup endpoint be used to
      // enumerate which addresses have accounts, it returns a fake HTTP 200
      // with a decoy user instead. The one reliable signal that this is a
      // decoy rather than a real new user: `identities` comes back as an
      // empty list. A genuinely new signup always has exactly one identity
      // (the email provider just created). Without this check, a duplicate
      // signup would silently "succeed" and route straight to Choose
      // Membership — confirmed by live testing against the real project.
      final user = response.user;
      if (user != null && (user.identities?.isEmpty ?? false)) {
        throw _emailInUseFailure;
      }
      return response.session != null;
    } on AuthException catch (e) {
      throw _messageFor(e);
    }
  }

  SignUpFailure _messageFor(AuthException e) {
    switch (e.code) {
      case 'email_exists':
      case 'user_already_exists':
        return _emailInUseFailure;
      case 'weak_password':
        return const SignUpFailure(
          'That password is too weak. Use at least 8 characters.',
          field: 'password',
        );
      case 'over_email_send_rate_limit':
        return const SignUpFailure('Too many attempts. Please wait a moment and try again.');
    }
    // Older/self-hosted Supabase versions don't always set `code` — fall
    // back to matching the message text for the same cases.
    final message = e.message.toLowerCase();
    if (message.contains('already registered') || message.contains('already exists')) {
      return _emailInUseFailure;
    }
    return SignUpFailure(e.message);
  }
}
