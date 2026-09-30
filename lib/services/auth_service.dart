import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'supabase_client.dart';

/// A sign-up error with a message safe to show. [field] is 'email' or 'password' so the form can
/// show it inline.
class SignUpFailure implements Exception {
  final String message;
  final String? field;
  const SignUpFailure(this.message, {this.field});
}

/// A sign-in error. Always the same message for any credential problem (see [AuthService.signIn]).
class SignInFailure implements Exception {
  final String message;
  const SignInFailure(this.message);
}

/// Only for real technical problems when requesting a reset, never for an unknown email (see
/// [AuthService.resetPassword]).
class ResetPasswordFailure implements Exception {
  final String message;
  const ResetPasswordFailure(this.message);
}

/// A change-password error. [field] is 'current' or 'new' so the form can show it inline.
class ChangePasswordFailure implements Exception {
  final String message;
  final String? field;
  const ChangePasswordFailure(this.message, {this.field});
}

/// Thrown when the current password can't be verified.
class ReauthenticationFailure implements Exception {
  final String message;
  const ReauthenticationFailure(this.message);
}

/// A set-new-password error. [field] is 'password' when it belongs to that field.
class SetNewPasswordFailure implements Exception {
  final String message;
  final String? field;
  const SetNewPasswordFailure(this.message, {this.field});
}

/// A change-email error. [field] is 'password' or 'email' so the form can show it inline.
class ChangeEmailFailure implements Exception {
  final String message;
  final String? field;
  const ChangeEmailFailure(this.message, {this.field});
}

class AuthService {
  /// [auth] is replaceable only for tests.
  const AuthService({GoTrueClient? auth}) : _authOverride = auth;

  final GoTrueClient? _authOverride;
  GoTrueClient get _auth => _authOverride ?? supabase.auth;

  static const _invalidCredentials = SignInFailure('Invalid email or password.');

  /// The signed-in user's email, read live each time.
  String? get currentUserEmail => _auth.currentUser?.email;

  /// The new email waiting for confirmation, or null. Comes from Supabase, so it's correct even if
  /// the link was clicked on another device.
  String? get pendingEmailChange => _auth.currentUser?.newEmail;

  /// Signs in. Every credential problem (wrong email, wrong password, unconfirmed account) shows
  /// the same message, so the form can't be used to find out which emails are registered.
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
        // Rate limiting doesn't reveal anything about the account, so we can say so.
        return const SignInFailure('Too many attempts. Please wait a moment and try again.');
    }
    // Everything else, including an unconfirmed email, gets the same generic message on purpose.
    return _invalidCredentials;
  }

  /// Sends a password-reset email. Supabase answers the same way whether or not the email exists,
  /// and so do we. Only a malformed email or rate limiting is reported separately.
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

  /// Changes the password, but only after checking the current one. Supabase doesn't require that,
  /// but an unlocked phone shouldn't let someone else change the password.
  ///
  /// Afterwards, other devices are signed out (best effort); this one stays signed in.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final email = _auth.currentUser?.email;
    if (email == null) {
      throw const ChangePasswordFailure('Your session expired. Please sign in again.');
    }

    // 1. Check the current password.
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
      // Older Supabase versions don't always set `code`.
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw const ChangePasswordFailure('Current password is incorrect.', field: 'current');
      }
      throw const ChangePasswordFailure("Couldn't verify your current password. Check your connection and try again.");
    } catch (_) {
      throw const ChangePasswordFailure("Couldn't verify your current password. Check your connection and try again.");
    }

    // 2. Change it.
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      switch (e.code) {
        case 'same_password':
          throw const ChangePasswordFailure('Choose a password different from your current one.', field: 'new');
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
      throw const ChangePasswordFailure("Couldn't update your password. Check your connection and try again.");
    }

    // 3. Sign out other devices. The password is already changed, so a failure here is ignored.
    try {
      await _auth.signOut(scope: SignOutScope.others);
    } catch (_) {}
  }

  /// Checks the current password without changing anything. Used before irreversible actions like
  /// deleting the account.
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
      // Older Supabase versions don't always set `code`.
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

  /// Sets a new password during a password-reset session. No current-password check: the reset link
  /// already proved it's the user.
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

  /// Requests an email change after checking the current password. Supabase emails a confirmation
  /// link to the new address; the change happens when it's clicked. The old email keeps working
  /// until then.
  Future<void> changeEmail({required String currentPassword, required String newEmail}) async {
    // 1. Check the password.
    try {
      await verifyCurrentPassword(currentPassword);
    } on ReauthenticationFailure catch (e) {
      throw ChangeEmailFailure(e.message, field: 'password');
    }

    // 2. Request the change.
    try {
      await _auth.updateUser(UserAttributes(email: newEmail), emailRedirectTo: SupabaseConfig.authRedirectUrl);
    } on AuthException catch (e) {
      switch (e.code) {
        case 'email_exists':
        case 'user_already_exists':
          throw const ChangeEmailFailure('An account with this email already exists.', field: 'email');
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

  /// Creates the account; a database trigger creates the profile (name and phone are passed along).
  ///
  /// Returns whether a session was created. With email confirmation on, there's no session until
  /// the link is clicked, so the caller must check this.
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
      // For an email that's already registered, Supabase returns a fake success instead of an error
      // (so sign-up can't reveal accounts). The tell-tale sign is an empty `identities` list.
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
        return const SignUpFailure('That password is too weak. Use at least 8 characters.', field: 'password');
      case 'over_email_send_rate_limit':
        return const SignUpFailure('Too many attempts. Please wait a moment and try again.');
    }
    // Older Supabase versions don't always set `code`, so fall back to the message text.
    final message = e.message.toLowerCase();
    if (message.contains('already registered') || message.contains('already exists')) {
      return _emailInUseFailure;
    }
    return SignUpFailure(e.message);
  }
}
