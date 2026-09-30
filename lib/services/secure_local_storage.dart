import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores the Supabase login session in the platform's encrypted storage (Keystore, Keychain,
/// Windows Credential Locker) instead of plain-text files.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({this.persistSessionKey = 'supabase.session', FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final String persistSessionKey;
  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final hasToken = await _storage.containsKey(key: persistSessionKey);
    // Never log the session itself, only whether there is one.
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
