import 'package:shared_preferences/shared_preferences.dart';

/// Tracks, locally on-device, whether the last successful sign-in asked to
/// be "remembered" (decision #56, replacing the decorative checkbox
/// decision #15 originally left as a placeholder).
///
/// Supabase always persists a session on sign-in regardless of this
/// checkbox -- that part of decision #15 doesn't change, since a signed-in
/// mobile app staying signed in by default is still the normal expectation.
/// What this actually gates is checked at `AppEntryPoint`'s EXISTING
/// session check, on the next cold app start -- not at sign-in or sign-out
/// time, and not "on close": a mobile OS can kill a process with no
/// callback firing to act on, so a cold start is the only reliable place to
/// honor "don't keep me signed in" from the previous launch.
///
/// Deliberately local-only, not backend/account state: this is a per-device
/// preference about how long a session should stick around on THIS device,
/// not something that should follow the user to another one.
class RememberMePrefs {
  const RememberMePrefs();

  static const _key = 'remember_me';

  /// Defaults to `true` (remembered) when nothing has been stored yet --
  /// matches decision #15's original, unconditional "stay signed in"
  /// behavior, and covers every path that never shows this checkbox at all
  /// (Create Account, for one -- a fresh signup is remembered by default,
  /// same as before this decision).
  Future<bool> isRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  Future<void> setRemembered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
