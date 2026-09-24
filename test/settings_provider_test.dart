import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simulates the app being closed and reopened: the in-memory
/// SharedPreferences singleton is thrown away, so the next [SettingsProvider
/// .load] has to come from what was actually written to the (fake) device
/// storage -- the same restart-simulation pattern
/// `notification_prefs_test.dart`/`remember_me_prefs_test.dart` already use.
void _restartApp() => SharedPreferences.resetStatic();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsProvider -- fresh-install defaults', () {
    test('themeMode defaults to light, not system', () async {
      final settings = await SettingsProvider.load();
      // Not ThemeMode.system: App Settings' Dark Mode row is a plain on/off
      // switch, not a System/Light/Dark picker, so a fresh install starts in
      // the state that switch shows as off.
      expect(settings.themeMode, ThemeMode.light);
    });

    test('animations, sound and haptics default on; auto-lock and biometric default off', () async {
      final settings = await SettingsProvider.load();

      expect(settings.animationsEnabled, isTrue);
      expect(settings.soundEnabled, isTrue);
      expect(settings.hapticsEnabled, isTrue);
      expect(settings.autoLockEnabled, isFalse); // decision #45: never implies protection that isn't real
      expect(settings.biometricEnabled, isFalse); // same reasoning
      expect(settings.autoLockTimeoutSeconds, 300);
    });
  });

  group('SettingsProvider -- every value persists across a restart', () {
    test('themeMode', () async {
      final settings = await SettingsProvider.load();
      await settings.setThemeMode(ThemeMode.dark);

      _restartApp();
      expect((await SettingsProvider.load()).themeMode, ThemeMode.dark);
    });

    test('animationsEnabled', () async {
      final settings = await SettingsProvider.load();
      await settings.setAnimationsEnabled(false);

      _restartApp();
      expect((await SettingsProvider.load()).animationsEnabled, isFalse);
    });

    test('soundEnabled', () async {
      final settings = await SettingsProvider.load();
      await settings.setSoundEnabled(false);

      _restartApp();
      expect((await SettingsProvider.load()).soundEnabled, isFalse);
    });

    test('hapticsEnabled', () async {
      final settings = await SettingsProvider.load();
      await settings.setHapticsEnabled(false);

      _restartApp();
      expect((await SettingsProvider.load()).hapticsEnabled, isFalse);
    });

    test('autoLockEnabled', () async {
      final settings = await SettingsProvider.load();
      await settings.setAutoLockEnabled(true);

      _restartApp();
      expect((await SettingsProvider.load()).autoLockEnabled, isTrue);
    });

    test('autoLockTimeoutSeconds', () async {
      final settings = await SettingsProvider.load();
      await settings.setAutoLockTimeoutSeconds(60);

      _restartApp();
      expect((await SettingsProvider.load()).autoLockTimeoutSeconds, 60);
    });

    test('biometricEnabled', () async {
      final settings = await SettingsProvider.load();
      await settings.setBiometricEnabled(true);

      _restartApp();
      expect((await SettingsProvider.load()).biometricEnabled, isTrue);
    });

    test('a value can be flipped back, and that persists too', () async {
      final settings = await SettingsProvider.load();
      await settings.setSoundEnabled(false);
      await settings.setSoundEnabled(true);

      _restartApp();
      expect((await SettingsProvider.load()).soundEnabled, isTrue);
    });

    test('changing one setting does not disturb the others', () async {
      final settings = await SettingsProvider.load();
      await settings.setHapticsEnabled(false);

      _restartApp();
      final reloaded = await SettingsProvider.load();
      expect(reloaded.hapticsEnabled, isFalse);
      expect(reloaded.themeMode, ThemeMode.light);
      expect(reloaded.animationsEnabled, isTrue);
      expect(reloaded.soundEnabled, isTrue);
      expect(reloaded.autoLockEnabled, isFalse);
      expect(reloaded.biometricEnabled, isFalse);
    });
  });

  group('SettingsProvider -- notifies listeners', () {
    test('every setter calls notifyListeners exactly once', () async {
      final settings = await SettingsProvider.load();
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setThemeMode(ThemeMode.dark);
      await settings.setAnimationsEnabled(false);
      await settings.setSoundEnabled(false);
      await settings.setHapticsEnabled(false);
      await settings.setAutoLockEnabled(true);
      await settings.setAutoLockTimeoutSeconds(60);
      await settings.setBiometricEnabled(true);

      expect(notifications, 7);
    });
  });

  test('storage keys are namespaced under settings.*, no collision with other local prefs', () async {
    final settings = await SettingsProvider.load();
    await settings.setThemeMode(ThemeMode.dark);
    await settings.setAnimationsEnabled(false);
    await settings.setSoundEnabled(false);
    await settings.setHapticsEnabled(false);
    await settings.setAutoLockEnabled(true);
    await settings.setAutoLockTimeoutSeconds(60);
    await settings.setBiometricEnabled(true);

    final stored = (await SharedPreferences.getInstance()).getKeys();
    expect(stored, {
      'settings.theme_mode',
      'settings.animations_enabled',
      'settings.sound_enabled',
      'settings.haptics_enabled',
      'settings.auto_lock_enabled',
      'settings.auto_lock_timeout_seconds',
      'settings.biometric_enabled',
    });
  });
}
