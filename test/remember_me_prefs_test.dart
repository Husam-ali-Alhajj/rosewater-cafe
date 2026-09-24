import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/remember_me_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simulates the app being closed and reopened: the in-memory
/// SharedPreferences singleton is thrown away, so the next read has to come
/// from what was actually written to the (fake) device storage.
void _restartApp() => SharedPreferences.resetStatic();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('RememberMePrefs', () {
    test('a fresh install defaults to remembered -- matches decision #15\'s original behavior', () async {
      expect(await const RememberMePrefs().isRemembered(), isTrue);
    });

    test('unchecking persists across a restart', () async {
      await const RememberMePrefs().setRemembered(false);

      _restartApp();
      expect(await const RememberMePrefs().isRemembered(), isFalse);
    });

    test('checking again after unchecking persists too', () async {
      await const RememberMePrefs().setRemembered(false);
      await const RememberMePrefs().setRemembered(true);

      _restartApp();
      expect(await const RememberMePrefs().isRemembered(), isTrue);
    });

    test('storage is device-local, not tied to any account', () async {
      await const RememberMePrefs().setRemembered(false);

      final stored = (await SharedPreferences.getInstance()).getKeys();
      expect(stored, {'remember_me'});
    });
  });
}
