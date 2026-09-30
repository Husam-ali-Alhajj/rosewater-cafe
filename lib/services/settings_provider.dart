import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings for this device: theme, animations, sound, haptics, auto-lock, biometric login
/// and language. Provided once above MaterialApp so any screen can read or change them.
///
/// Stored on the device, not the account. Loaded before the app starts so there's no flash of the
/// wrong theme.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider._({
    required this._prefs,
    required this._themeMode,
    required this._animationsEnabled,
    required this._soundEnabled,
    required this._hapticsEnabled,
    required this._autoLockEnabled,
    required this._autoLockTimeoutSeconds,
    required this._biometricEnabled,
    required this._locale,
  });

  static const _keyThemeMode = 'settings.theme_mode';
  static const _keyAnimationsEnabled = 'settings.animations_enabled';
  static const _keySoundEnabled = 'settings.sound_enabled';
  static const _keyHapticsEnabled = 'settings.haptics_enabled';
  static const _keyAutoLockEnabled = 'settings.auto_lock_enabled';
  static const _keyAutoLockTimeoutSeconds = 'settings.auto_lock_timeout_seconds';
  static const _keyBiometricEnabled = 'settings.biometric_enabled';
  static const _keyLocale = 'settings.locale';

  // Defaults, used until something is saved. Dark Mode is an on/off switch, so the default is light
  // (not "follow the system").
  static const _defaultThemeMode = ThemeMode.light;
  static const _defaultAnimationsEnabled = true; // on, as in the design
  static const _defaultSoundEnabled = true;
  static const _defaultHapticsEnabled = true;
  static const _defaultAutoLockEnabled = false; // off by default
  static const _defaultAutoLockTimeoutSeconds = 300; // 5 minutes
  static const _defaultBiometricEnabled = false; // off by default
  // Default language code.
  static const _defaultLocale = 'en';

  /// Languages with translations, the only ones that can be picked.
  static const _selectableLocales = {'en', 'ar'};

  final SharedPreferences _prefs;

  ThemeMode _themeMode;
  bool _animationsEnabled;
  bool _soundEnabled;
  bool _hapticsEnabled;
  bool _autoLockEnabled;
  int _autoLockTimeoutSeconds;
  bool _biometricEnabled;
  String _locale;

  ThemeMode get themeMode => _themeMode;
  bool get animationsEnabled => _animationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get autoLockEnabled => _autoLockEnabled;
  int get autoLockTimeoutSeconds => _autoLockTimeoutSeconds;
  bool get biometricEnabled => _biometricEnabled;

  /// 'en' or 'ar'. An old saved 'fr' or 'es' falls back to English on [load].
  String get locale => _locale;

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

  Future<void> setLocale(String value) async {
    _locale = value;
    notifyListeners();
    await _prefs.setString(_keyLocale, value);
  }

  /// Reads every saved value (or its default). Call once, before runApp().
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
      locale: _selectableLocales.contains(prefs.getString(_keyLocale)) ? prefs.getString(_keyLocale)! : _defaultLocale,
    );
  }

  static ThemeMode? _themeModeFromName(String? name) {
    if (name == null) return null;
    for (final mode in ThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return null; // an unknown saved value falls back to the default
  }
}
