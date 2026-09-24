import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A stand-in for the real auth client that records every call, in order.
/// Only the three members `AuthService.changeEmail` touches are
/// implemented; anything else would throw.
class _FakeAuth implements GoTrueClient {
  _FakeAuth({this.email = 'member@example.com', this.signInError, this.updateError});

  final String? email;
  final Object? signInError;
  final Object? updateError;

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
    log.add('updateUser(email: ${attributes.email}, redirectTo: $emailRedirectTo)');
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ChangeEmailFailure> _failureOf(Future<void> Function() call) async {
  try {
    await call();
  } on ChangeEmailFailure catch (e) {
    return e;
  }
  fail('expected a ChangeEmailFailure');
}

void main() {
  group('AuthService.changeEmail -- proves the current password before requesting anything', () {
    test('re-authenticates with the CURRENT password first, then requests the change', () async {
      final auth = _FakeAuth();

      await AuthService(auth: auth).changeEmail(currentPassword: 'MyPass1', newEmail: 'new@example.com');

      expect(auth.log.length, 2);
      expect(auth.log[0], 'signIn(member@example.com, MyPass1)'); // 1. prove they know the password
      expect(auth.log[1], contains('updateUser(email: new@example.com')); //   2. only then request it
    });

    test('sends the shared auth redirect URL', () async {
      final auth = _FakeAuth();

      await AuthService(auth: auth).changeEmail(currentPassword: 'MyPass1', newEmail: 'new@example.com');

      expect(auth.log[1], contains('redirectTo: http://localhost:5000'));
    });

    test('a WRONG current password is rejected and no change is requested', () async {
      final auth = _FakeAuth(signInError: const AuthException('Invalid login credentials', code: 'invalid_credentials'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changeEmail(currentPassword: 'WrongPass1', newEmail: 'new@example.com'),
      );

      expect(failure.message, 'Current password is incorrect.');
      expect(failure.field, 'password');
      expect(auth.log, ['signIn(member@example.com, WrongPass1)']); // updateUser never ran
    });

    test('with no signed-in user nothing is attempted at all', () async {
      final auth = _FakeAuth(email: null);

      final failure = await _failureOf(
        () => AuthService(auth: auth).changeEmail(currentPassword: 'MyPass1', newEmail: 'new@example.com'),
      );

      expect(failure.field, 'password');
      expect(auth.log, isEmpty);
    });
  });

  group('AuthService.changeEmail -- the request itself', () {
    test('an email already registered to another account is reported on the email field', () async {
      final auth = _FakeAuth(updateError: const AuthException('taken', code: 'email_exists'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changeEmail(currentPassword: 'MyPass1', newEmail: 'taken@example.com'),
      );

      expect(failure.field, 'email');
      expect(failure.message, contains('already exists'));
    });

    test('rate limiting is reported as a general failure, not blamed on either field', () async {
      final auth = _FakeAuth(updateError: const AuthException('slow down', code: 'over_email_send_rate_limit'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changeEmail(currentPassword: 'MyPass1', newEmail: 'new@example.com'),
      );

      expect(failure.field, isNull);
      expect(failure.message, 'Too many attempts. Please wait a moment and try again.');
    });

    test('an unexpected error becomes a friendly message, never a raw exception', () async {
      final auth = _FakeAuth(updateError: StateError('boom'));

      final failure = await _failureOf(
        () => AuthService(auth: auth).changeEmail(currentPassword: 'MyPass1', newEmail: 'new@example.com'),
      );

      expect(failure.field, isNull);
      expect(failure.message, contains("Couldn't update your email"));
      expect(failure.message, isNot(contains('boom')));
    });
  });
}
