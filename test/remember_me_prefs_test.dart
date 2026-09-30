import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/remember_me_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simulates closing and reopening the app: the next read comes from what was actually saved.
void _restartApp() => SharedPreferences.resetStatic();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('RememberMePrefs', () {
    test('a fresh install defaults to remembered', () async {
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
