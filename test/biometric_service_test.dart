import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:rosewater_cafe/services/biometric_service.dart';

/// A fake of the `local_auth` platform layer, since tests have no real device.
class _FakePlatform extends LocalAuthPlatform {
  _FakePlatform({this.supported = true, this.canCheck = true, this.authResult = true, this.throwOnAuth = false});

  final bool supported;
  final bool canCheck;
  final bool authResult;
  final bool throwOnAuth;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> deviceSupportsBiometrics() async => canCheck;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    if (throwOnAuth) throw Exception('platform channel unavailable');
    return authResult;
  }
}

void main() {
  group('isAvailable', () {
    test('true when the device supports biometrics and has some enrolled', () async {
      LocalAuthPlatform.instance = _FakePlatform(supported: true, canCheck: true);
      final service = BiometricService(auth: LocalAuthentication());
      expect(await service.isAvailable(), isTrue);
    });

    test('false when the device does not support biometrics at all', () async {
      LocalAuthPlatform.instance = _FakePlatform(supported: false, canCheck: true);
      final service = BiometricService(auth: LocalAuthentication());
      expect(await service.isAvailable(), isFalse);
    });

    test('false when supported but nothing is enrolled', () async {
      LocalAuthPlatform.instance = _FakePlatform(supported: true, canCheck: false);
      final service = BiometricService(auth: LocalAuthentication());
      expect(await service.isAvailable(), isFalse);
    });
  });

  group('authenticate', () {
    test('returns true on a successful check', () async {
      LocalAuthPlatform.instance = _FakePlatform(authResult: true);
      final service = BiometricService(auth: LocalAuthentication());
      expect(await service.authenticate(reason: 'test'), isTrue);
    });

    test('returns false, never throws, on a plugin-level error', () async {
      LocalAuthPlatform.instance = _FakePlatform(throwOnAuth: true);
      final service = BiometricService(auth: LocalAuthentication());
      expect(await service.authenticate(reason: 'test'), isFalse);
    });
  });
}
