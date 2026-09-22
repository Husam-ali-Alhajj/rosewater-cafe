import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A stand-in for the real auth client that records every call, in order, so a
/// test can prove WHAT `changePassword` does and -- just as important -- what it
/// refuses to do. Only the four members `AuthService.changePassword` touches
/// are implemented; anything else would throw.
class _FakeAuth implements GoTrueClient {
  _FakeAuth({this.email = 'member@example.com', this.signInError, this.updateError, this.signOutError});

  final String? email;
  final Object? signInError;
  final Object? updateError;
  final Object? signOutError;

  /// Every call made, in order.
  final List<String> log = [];

  @override
  User? get currentUser => email == null
      ? null
      : User.fromJson({
          'id': 'user-1',
          'aud': 'authenticated',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2026-01-01T00:00:00Z',
          'email': email,
        });

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    log.add('signIn($email, $password)');
    if (signInError != null) throw signInError!;
    return AuthResponse();
  }

  @override
  Future<UserResponse> updateUser(UserAttributes attributes, {String? emailRedirectTo}) async {
    log.add('updateUser(password: ${attributes.password})');
    if (updateError != null) throw updateError!;
    return UserResponse.fromJson({
      'id': 'user-1',
      'aud': 'authenticated',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-01-01T00:00:00Z',
    });
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    log.add('signOut(${scope.name})');
    if (signOutError != null) throw signOutError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ChangePasswordFailure> _failureOf(Future<void> Function() call) async {
  try {
    await call();
  } on ChangePasswordFailure catch (e) {
    return e;
  }
  fail('expected a ChangePasswordFailure');
}

void main() {
  group('AuthService.changePassword -- proves the current password before changing anything', () {
    test('re-authenticates with the CURRENT password first, then changes it, then ends other sessions', () async {
      final auth = _FakeAuth();

      await AuthService(auth: auth).changePassword(currentPassword: 'OldPass1', newPassword: 'NewPass2');

      expect(auth.log, [
        'signIn(member@example.com, OldPass1)', // 1. prove they know the current password
        'updateUser(password: NewPass2)', //        2. only then change it
        'signOut(others)', //                       3. and lock every other session out
      ]);
    });

    test('a WRONG current password is rejected and the password is never changed', () async {
      final auth = _FakeAuth(signInError: const AuthException('Invalid login credentials', code: 'invalid_credentials'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changePassword(currentPassword: 'WrongPass1', newPassword: 'NewPass2'),
      );

      expect(failure.message, 'Current password is incorrect.');
      expect(failure.field, 'current');
      // The important part: updateUser (and the sign-out of others) never ran.
      expect(auth.log, ['signIn(member@example.com, WrongPass1)']);
    });

    test('the "invalid login credentials" message is recognised even without an error code', () async {
      final auth = _FakeAuth(signInError: const AuthException('Invalid login credentials'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changePassword(currentPassword: 'x', newPassword: 'NewPass2'),
      );

      expect(failure.field, 'current');
      expect(auth.log.where((l) => l.startsWith('updateUser')), isEmpty);
    });

    test('rate limiting while verifying is reported as such and changes nothing', () async {
      final auth = _FakeAuth(signInError: const AuthException('slow down', code: 'over_request_rate_limit'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changePassword(currentPassword: 'OldPass1', newPassword: 'NewPass2'),
      );

      expect(failure.message, 'Too many attempts. Please wait a moment and try again.');
      expect(failure.field, isNull);
      expect(auth.log.where((l) => l.startsWith('updateUser')), isEmpty);
    });

    test('a network failure while verifying is NOT reported as a wrong password, and changes nothing', () async {
      final auth = _FakeAuth(signInError: Exception('SocketException: offline'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changePassword(currentPassword: 'OldPass1', newPassword: 'NewPass2'),
      );

      expect(failure.message, contains("Couldn't verify your current password"));
      expect(failure.field, isNull); // not blamed on the field: the password may well be right
      expect(auth.log.where((l) => l.startsWith('updateUser')), isEmpty);
    });

    test('with no signed-in user nothing is attempted at all', () async {
      final auth = _FakeAuth(email: null);

      final failure = await _failureOf(
        () => AuthService(auth: auth).changePassword(currentPassword: 'OldPass1', newPassword: 'NewPass2'),
      );

      expect(failure.message, 'Your session expired. Please sign in again.');
      expect(auth.log, isEmpty);
    });
  });

  group('AuthService.changePassword -- the change itself', () {
    test('a new password the server says is the same as the old one is reported on the new-password field', () async {
      final auth = _FakeAuth(updateError: const AuthException('same', code: 'same_password'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changePassword(currentPassword: 'OldPass1', newPassword: 'OldPass1'),
      );

      expect(failure.field, 'new');
      expect(failure.message, 'Choose a password different from your current one.');
      expect(auth.log.where((l) => l.startsWith('signOut')), isEmpty); // nothing changed, so no lock-out
    });

    test("the server's own weak-password rejection is reported on the new-password field", () async {
      final auth = _FakeAuth(updateError: const AuthException('weak', code: 'weak_password'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changePassword(currentPassword: 'OldPass1', newPassword: 'NewPass2'),
      );

      expect(failure.field, 'new');
      expect(failure.message, contains('too weak'));
    });

    test('an unexpected error while changing becomes a friendly message, never a raw exception', () async {
      final auth = _FakeAuth(updateError: StateError('boom'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changePassword(currentPassword: 'OldPass1', newPassword: 'NewPass2'),
      );

      expect(failure.message, contains("Couldn't update your password"));
      expect(failure.message, isNot(contains('boom')));
    });

    test('failing to sign out other sessions does not fail a password change that already happened', () async {
      final auth = _FakeAuth(signOutError: Exception('network'));

      await AuthService(auth: auth).changePassword(currentPassword: 'OldPass1', newPassword: 'NewPass2');

      expect(auth.log, [
        'signIn(member@example.com, OldPass1)',
        'updateUser(password: NewPass2)',
        'signOut(others)',
      ]);
    });
  });
}
