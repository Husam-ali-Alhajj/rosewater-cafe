import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/config/supabase_config.dart';
import 'package:rosewater_cafe/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A stand-in for the real auth client that records every call, in order.
/// Only the two members `AuthService.completePasswordRecovery` touches are
/// implemented; anything else would throw.
class _FakeAuth implements GoTrueClient {
  _FakeAuth({this.hasSession = true, this.updateError});

  final bool hasSession;
  final Object? updateError;

  /// Every call made, in order.
  final List<String> log = [];

  @override
  Future<void> resetPasswordForEmail(String email, {String? redirectTo, String? captchaToken}) async {
    log.add('resetPasswordForEmail($email, redirectTo: $redirectTo)');
  }

  @override
  User? get currentUser => hasSession
      ? User.fromJson({
          'id': 'user-1',
          'aud': 'authenticated',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2026-01-01T00:00:00Z',
          'email': 'member@example.com',
        })
      : null;

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<SetNewPasswordFailure> _failureOf(Future<void> Function() call) async {
  try {
    await call();
  } on SetNewPasswordFailure catch (e) {
    return e;
  }
  fail('expected a SetNewPasswordFailure');
}

void main() {
  group('AuthService.resetPassword sends the deep-link redirect', () {
    test('passes the app\'s password-recovery redirect URL, not Supabase\'s bare default', () async {
      final auth = _FakeAuth();

      await AuthService(auth: auth).resetPassword('member@example.com');

      expect(auth.log, ['resetPasswordForEmail(member@example.com, redirectTo: ${SupabaseConfig.passwordRecoveryRedirectUrl})']);
    });
  });

  group('AuthService.completePasswordRecovery', () {
    test('sets the new password inside the active recovery session -- no current-password check', () async {
      final auth = _FakeAuth();

      await AuthService(auth: auth).completePasswordRecovery('NewPass2');

      expect(auth.log, ['updateUser(password: NewPass2)']);
    });

    test('with no active recovery session, nothing is attempted at all', () async {
      final auth = _FakeAuth(hasSession: false);

      final failure = await _failureOf(() => AuthService(auth: auth).completePasswordRecovery('NewPass2'));

      expect(failure.message, contains('expired'));
      expect(auth.log, isEmpty);
    });

    test('a password identical to the previous one is reported on the password field', () async {
      final auth = _FakeAuth(updateError: const AuthException('same', code: 'same_password'));

      final failure = await _failureOf(() => AuthService(auth: auth).completePasswordRecovery('OldPass1'));

      expect(failure.field, 'password');
      expect(failure.message, 'Choose a password different from your previous one.');
    });

    test("the server's own weak-password rejection is reported on the password field", () async {
      final auth = _FakeAuth(updateError: const AuthException('weak', code: 'weak_password'));

      final failure = await _failureOf(() => AuthService(auth: auth).completePasswordRecovery('weak'));

      expect(failure.field, 'password');
      expect(failure.message, contains('too weak'));
    });

    test('rate limiting is reported as a general failure, not blamed on the password field', () async {
      final auth = _FakeAuth(updateError: const AuthException('slow down', code: 'over_request_rate_limit'));

      final failure = await _failureOf(() => AuthService(auth: auth).completePasswordRecovery('NewPass2'));

      expect(failure.field, isNull);
      expect(failure.message, 'Too many attempts. Please wait a moment and try again.');
    });

    test('an unexpected error becomes a friendly message, never a raw exception', () async {
      final auth = _FakeAuth(updateError: StateError('boom'));

      final failure = await _failureOf(() => AuthService(auth: auth).completePasswordRecovery('NewPass2'));

      expect(failure.field, isNull);
      expect(failure.message, contains("Couldn't update your password"));
      expect(failure.message, isNot(contains('boom')));
    });
  });
}
