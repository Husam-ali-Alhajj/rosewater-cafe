import 'package:local_auth/local_auth.dart';

/// Sprint 8 Task 5: a thin wrapper around `local_auth`'s
/// [LocalAuthentication], so the rest of the app (and tests) go through one
/// small surface rather than the plugin class directly -- the same
/// constructor-injection pattern every other real service in this project
/// uses (`AuthService`, `AccountDeletionService`, ...), so a fake can stand
/// in without a real device or platform channel.
class BiometricService {
  const BiometricService({LocalAuthentication? auth}) : _authOverride = auth;

  // `LocalAuthentication` isn't const-constructible, so a real one is
  // created lazily here rather than eagerly in the constructor -- keeps
  // `const BiometricService()` itself legal as a default parameter value
  // at every call site (AppLockScreen, _SecurityOptionsCard), the same
  // "null overrides a lazily-created real default" shape as every other
  // injectable service in this project.
  final LocalAuthentication? _authOverride;
  LocalAuthentication get _auth => _authOverride ?? LocalAuthentication();

  /// True only if the device both supports biometrics at all
  /// ([LocalAuthentication.isDeviceSupported]) AND has at least one
  /// biometric actually enrolled ([LocalAuthentication.canCheckBiometrics])
  /// -- checked before the Biometric Authentication toggle is allowed to
  /// turn on, per the task's own "fail gracefully... rather than a toggle
  /// that silently does nothing." Never throws: any plugin-level error
  /// (channel not implemented, permission denied, ...) is treated the same
  /// as "not available" -- there's nothing more specific a caller could
  /// usefully do with it.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Prompts for a biometric check (fingerprint/Face ID/Touch ID) and
  /// returns whether it succeeded. `biometricOnly: true` -- deliberately
  /// never falls through to the OS's own device-PIN prompt, so the lock
  /// screen's own "Use Password Instead" is the one fallback path, not two
  /// different fallback UIs layered on each other. A cancelled prompt, a
  /// device with biometrics removed since the last check, or any plugin
  /// error all just return `false` -- same "let the caller show a plain
  /// failure state" reasoning as [isAvailable].
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
