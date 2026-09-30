import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/secure_local_storage.dart';

/// An in-memory fake of the platform's secure storage, so this runs on any machine. It checks that
/// SecureLocalStorage reads, writes and deletes correctly (encryption is the plugin's job).
class _InMemorySecureStoragePlatform extends FlutterSecureStoragePlatform {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async {
    return _store[key];
  }

  @override
  Future<bool> containsKey({required String key, required Map<String, String> options}) async {
    return _store.containsKey(key);
  }

  @override
  Future<void> delete({required String key, required Map<String, String> options}) async {
    _store.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) async {
    return Map.of(_store);
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    _store.clear();
  }
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = _InMemorySecureStoragePlatform();
  });

  test('persistSession writes to secure storage and accessToken reads it back', () async {
    final storage = SecureLocalStorage();
    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);

    await storage.persistSession('fake-session-json-for-test');

    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), 'fake-session-json-for-test');
  });

  test('removePersistedSession deletes the stored session', () async {
    final storage = SecureLocalStorage();
    await storage.persistSession('fake-session-json-for-test');
    expect(await storage.hasAccessToken(), isTrue);

    await storage.removePersistedSession();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });
}
