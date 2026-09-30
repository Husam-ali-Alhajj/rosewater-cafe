import 'package:local_auth/local_auth.dart';

/// A small wrapper around `local_auth`, so the app and tests use one simple class.
class BiometricService {
  const BiometricService({LocalAuthentication? auth}) : _authOverride = auth;

  // Created on first use so this class can be const.
  final LocalAuthentication? _authOverride;
  LocalAuthentication get _auth => _authOverride ?? LocalAuthentication();

  /// True only if the device supports biometrics and has at least one enrolled. Never throws; any
  /// error means "not available".
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Asks for a fingerprint or face scan and returns whether it worked. Biometrics only, so the
  /// lock screen's "Use Password Instead" is the only fallback. Any failure returns false.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
