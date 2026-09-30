import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this device whether the last sign-in ticked "Remember me". If not, AppEntryPoint
/// signs out on the next app start (there's no reliable "app closed" event on mobile).
class RememberMePrefs {
  const RememberMePrefs();

  static const _key = 'remember_me';

  /// Defaults to true, so a new sign-up stays signed in.
  Future<bool> isRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  Future<void> setRemembered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
