import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase auth session (access + refresh tokens) using the
/// platform's encrypted storage — Android Keystore-backed
/// EncryptedSharedPreferences, iOS/macOS Keychain, Windows Credential
/// Locker — instead of supabase_flutter's default [SharedPreferencesLocalStorage],
/// which writes the same data to disk in plain text.
///
/// Passed into `Supabase.initialize(authOptions: FlutterAuthClientOptions(
/// localStorage: SecureLocalStorage()))`.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({
    this.persistSessionKey = 'supabase.session',
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final String persistSessionKey;
  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final hasToken = await _storage.containsKey(key: persistSessionKey);
    // Never print the session value itself — only whether one exists.
    debugPrint('[SecureLocalStorage] hasAccessToken() -> $hasToken');
    return hasToken;
  }

  @override
  Future<String?> accessToken() async {
    final value = await _storage.read(key: persistSessionKey);
    debugPrint(
      '[SecureLocalStorage] accessToken() read from secure storage '
      '(session present: ${value != null})',
    );
    return value;
  }

  @override
  Future<void> removePersistedSession() async {
    debugPrint('[SecureLocalStorage] removePersistedSession() — deleting from secure storage');
    await _storage.delete(key: persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    debugPrint('[SecureLocalStorage] persistSession() — writing session to secure storage');
    await _storage.write(key: persistSessionKey, value: persistSessionString);
  }
}
