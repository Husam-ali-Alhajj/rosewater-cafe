import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/notification_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simulates the app being closed and reopened: the in-memory SharedPreferences
/// singleton is thrown away, so the next read has to come from what was
/// actually written to the (fake) device storage.
void _restartApp() => SharedPreferences.resetStatic();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('NotificationPrefs', () {
    test('a fresh install shows the design defaults: SMS off, everything else on', () async {
      final settings = await const NotificationPrefs(userId: 'u1').load();

      expect(settings.isOn(NotificationSetting.push), isTrue);
      expect(settings.isOn(NotificationSetting.email), isTrue);
      expect(settings.isOn(NotificationSetting.sms), isFalse);
      expect(settings.isOn(NotificationSetting.sound), isTrue);
      expect(settings.isOn(NotificationSetting.eventReminders), isTrue);
      expect(settings.isOn(NotificationSetting.allowanceAlerts), isTrue);
      expect(settings.isOn(NotificationSetting.promotions), isTrue);
    });

    test('a saved toggle persists across an app restart', () async {
      const prefs = NotificationPrefs(userId: 'u1');
      await prefs.set(NotificationSetting.sms, true);
      await prefs.set(NotificationSetting.push, false);
      await prefs.set(NotificationSetting.promotions, false);

      _restartApp();
      final settings = await const NotificationPrefs(userId: 'u1').load();

      expect(settings.isOn(NotificationSetting.sms), isTrue); // was off by default
      expect(settings.isOn(NotificationSetting.push), isFalse); // was on by default
      expect(settings.isOn(NotificationSetting.promotions), isFalse);
      // ... and the ones never touched are still at their defaults.
      expect(settings.isOn(NotificationSetting.email), isTrue);
      expect(settings.isOn(NotificationSetting.sound), isTrue);
    });

    test('a toggle can be flipped back, and that persists too', () async {
      const prefs = NotificationPrefs(userId: 'u1');
      await prefs.set(NotificationSetting.push, false);
      await prefs.set(NotificationSetting.push, true);

      _restartApp();
      expect((await const NotificationPrefs(userId: 'u1').load()).isOn(NotificationSetting.push), isTrue);
    });

    test('only what the user changed is written', () async {
      await const NotificationPrefs(userId: 'u1').set(NotificationSetting.sms, true);

      final stored = (await SharedPreferences.getInstance()).getKeys();
      expect(stored, {'notification_settings.u1.sms'});
    });

    test("one person's choices don't become another's on the same device", () async {
      await const NotificationPrefs(userId: 'alice').set(NotificationSetting.push, false);

      _restartApp();
      final bob = await const NotificationPrefs(userId: 'bob').load();
      final alice = await const NotificationPrefs(userId: 'alice').load();

      expect(bob.isOn(NotificationSetting.push), isTrue); // Bob still has the default
      expect(alice.isOn(NotificationSetting.push), isFalse);
    });

    test('with no user, settings belong to the device', () async {
      await const NotificationPrefs().set(NotificationSetting.sound, false);

      _restartApp();
      expect((await const NotificationPrefs().load()).isOn(NotificationSetting.sound), isFalse);
      expect((await const NotificationPrefs(userId: 'u1').load()).isOn(NotificationSetting.sound), isTrue);
    });
  });

  group('no network', () {
    /// Follows every project-relative import from [path] and collects every
    /// non-project import (package: / dart:) found along the way.
    Set<String> externalImports(String path, [Set<String>? seen]) {
      seen ??= {};
      final file = File(path);
      if (!seen.add(file.absolute.path)) return {};
      final found = <String>{};
      for (final match in RegExp(r"^import '([^']+)';", multiLine: true).allMatches(file.readAsStringSync())) {
        final target = match.group(1)!;
        if (target.startsWith('package:rosewater_cafe/')) {
          found.addAll(externalImports('lib/${target.substring('package:rosewater_cafe/'.length)}', seen));
        } else if (target.startsWith('package:') || target.startsWith('dart:')) {
          found.add(target);
        } else {
          final dir = file.parent.path;
          found.addAll(externalImports(File('$dir/$target').absolute.path, seen));
        }
      }
      return found;
    }

    test('the settings screen and its preferences import nothing that can reach the network', () {
      final imports = <String>{
        ...externalImports('lib/screens/profile/notification_settings_screen.dart'),
        ...externalImports('lib/services/notification_prefs.dart'),
      };

      // Everything they (transitively) import from outside the project:
      // `provider` joined this list in Sprint 8 Task 3 -- SettingToggleRow's
      // switch (used by this screen's toggles) now reads
      // SettingsProvider.animationsEnabled via `app_animations.dart` for the
      // Animations toggle. `provider` is a pure InheritedWidget wrapper with
      // no I/O of its own, so it doesn't weaken the "no network" guarantee
      // this test actually exists to check -- the loop below still holds.
      expect(imports, {
        'package:flutter/material.dart',
        'package:shared_preferences/shared_preferences.dart',
        'package:provider/provider.dart',
      });
      // ... in particular, no backend client and no HTTP.
      for (final i in imports) {
        expect(i, isNot(contains('supabase')));
        expect(i, isNot(contains('http')));
        expect(i, isNot(contains('dart:io')));
      }
    });
  });
}
