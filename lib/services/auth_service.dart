import 'package:supabase_flutter/supabase_flutter.dart';
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

class AuthService {
  const AuthService();

  static const _invalidCredentials = SignInFailure('Invalid email or password.');

  /// Signs in with email + password. Deliberately reports the exact same
  /// message for every credential-related failure — wrong email, wrong
  /// password, and even an unconfirmed account all look identical to the
  /// caller. Distinguishing any of these would let a login form be used to
  /// enumerate which emails have accounts (submit a guessed email, see if
  /// the error changes) — the security goal here is that a login attempt
  /// must never reveal whether an email is registered at all.
  Future<void> signIn({required String email, required String password}) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
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
      await supabase.auth.resetPasswordForEmail(email);
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
      final response = await supabase.auth.signUp(
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
