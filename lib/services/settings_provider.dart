import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The single, shared home for every app-wide setting this project has (or
/// will have this sprint): theme, animations, sound, haptics, auto-lock, and
/// biometric login. Sprint 8's foundation task -- every one of these was
/// previously either not stored anywhere at all, or (had a screen actually
/// stored one locally) would have been its own separate `shared_preferences`
/// call. One `ChangeNotifier`, registered once above `MaterialApp`
/// (`main.dart`), so any screen reads/writes through `context.watch` /
/// `context.read` instead of prop-drilling or reaching for
/// `SharedPreferences.getInstance()` itself.
///
/// **This task deliberately does not wire any screen's toggle to this class
/// yet** -- App Settings' Dark Mode/Animations/Sound/Haptic and Privacy &
/// Security's Auto-Lock/Biometric all stay exactly the inert placeholders
/// they were before this task (decisions #5/#45/#47). Each gets wired to the
/// real setting here, and made to actually do something, in its own later
/// Sprint 8 task. This task is purely the shared storage they'll all use.
///
/// Deliberately device-local, not per-account or backend state (matching
/// `OnboardingPrefs`/`RememberMePrefs`, not `NotificationPrefs`'s per-user
/// scoping) -- these are how-this-device-behaves preferences, not something
/// that should follow a specific account.
///
/// Constructed via the async [load] factory, awaited in `main()` BEFORE
/// `runApp()` -- the same "resolve everything first, no flash of a wrong
/// state" pattern decision #15 already established for session routing.
/// Building this synchronously with in-memory defaults and correcting them
/// once the real stored values loaded would mean an actual dark-mode user
/// sees a flash of light theme (or vice versa) on every cold start.
class SettingsProvider extends ChangeNotifier {
  // Initializing formals -- Dart exposes each one's call-site name with the
  // field's leading underscore stripped (a private field can't have a
  // private named-parameter name), so `load()` below calls this with plain
  // names (`prefs:`, `themeMode:`, ...) despite the fields being private.
  SettingsProvider._({
    required this._prefs,
    required this._themeMode,
    required this._animationsEnabled,
    required this._soundEnabled,
    required this._hapticsEnabled,
    required this._autoLockEnabled,
    required this._autoLockTimeoutSeconds,
    required this._biometricEnabled,
  });

  static const _keyThemeMode = 'settings.theme_mode';
  static const _keyAnimationsEnabled = 'settings.animations_enabled';
  static const _keySoundEnabled = 'settings.sound_enabled';
  static const _keyHapticsEnabled = 'settings.haptics_enabled';
  static const _keyAutoLockEnabled = 'settings.auto_lock_enabled';
  static const _keyAutoLockTimeoutSeconds = 'settings.auto_lock_timeout_seconds';
  static const _keyBiometricEnabled = 'settings.biometric_enabled';

  // Defaults, applied only when nothing has been stored yet.
  //
  // themeMode defaults to light, NOT system, on purpose: App Settings'
  // "Dark Mode" row (Sprint 8 Task 2, AppTheme.dark) is a plain on/off
  // switch, not a three-way System/Light/Dark picker -- there's no UI for
  // "follow the system" for this to represent, so a fresh install starts
  // in the state that switch actually shows as off (light), the same way
  // every other toggle here defaults to whatever its own row is drawn as.
  static const _defaultThemeMode = ThemeMode.light;
  static const _defaultAnimationsEnabled = true; // design shows these "on"
  static const _defaultSoundEnabled = true;
  static const _defaultHapticsEnabled = true;
  static const _defaultAutoLockEnabled = false; // decision #45: shown off, not implying protection that isn't real
  static const _defaultAutoLockTimeoutSeconds = 300; // 5 minutes; revisited when Auto-Lock's own task wires this up
  static const _defaultBiometricEnabled = false; // decision #45, same reasoning as auto-lock

  final SharedPreferences _prefs;

  ThemeMode _themeMode;
  bool _animationsEnabled;
  bool _soundEnabled;
  bool _hapticsEnabled;
  bool _autoLockEnabled;
  int _autoLockTimeoutSeconds;
  bool _biometricEnabled;

  ThemeMode get themeMode => _themeMode;
  bool get animationsEnabled => _animationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get autoLockEnabled => _autoLockEnabled;
  int get autoLockTimeoutSeconds => _autoLockTimeoutSeconds;
  bool get biometricEnabled => _biometricEnabled;

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    notifyListeners();
    await _prefs.setString(_keyThemeMode, value.name);
  }

  Future<void> setAnimationsEnabled(bool value) async {
    _animationsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_keyAnimationsEnabled, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    await _prefs.setBool(_keySoundEnabled, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_keyHapticsEnabled, value);
  }

  Future<void> setAutoLockEnabled(bool value) async {
    _autoLockEnabled = value;
    notifyListeners();
    await _prefs.setBool(_keyAutoLockEnabled, value);
  }

  Future<void> setAutoLockTimeoutSeconds(int value) async {
    _autoLockTimeoutSeconds = value;
    notifyListeners();
    await _prefs.setInt(_keyAutoLockTimeoutSeconds, value);
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    notifyListeners();
    await _prefs.setBool(_keyBiometricEnabled, value);
  }

  /// Reads every stored value (or its default) from disk and returns a
  /// fully-populated instance -- call once, awaited, before `runApp()`.
  static Future<SettingsProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsProvider._(
      prefs: prefs,
      themeMode: _themeModeFromName(prefs.getString(_keyThemeMode)) ?? _defaultThemeMode,
      animationsEnabled: prefs.getBool(_keyAnimationsEnabled) ?? _defaultAnimationsEnabled,
      soundEnabled: prefs.getBool(_keySoundEnabled) ?? _defaultSoundEnabled,
      hapticsEnabled: prefs.getBool(_keyHapticsEnabled) ?? _defaultHapticsEnabled,
      autoLockEnabled: prefs.getBool(_keyAutoLockEnabled) ?? _defaultAutoLockEnabled,
      autoLockTimeoutSeconds: prefs.getInt(_keyAutoLockTimeoutSeconds) ?? _defaultAutoLockTimeoutSeconds,
      biometricEnabled: prefs.getBool(_keyBiometricEnabled) ?? _defaultBiometricEnabled,
    );
  }

  static ThemeMode? _themeModeFromName(String? name) {
    if (name == null) return null;
    for (final mode in ThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return null; // an unrecognised stored value falls back to the default, never throws
  }
}
