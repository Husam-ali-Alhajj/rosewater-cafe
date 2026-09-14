import 'package:shared_preferences/shared_preferences.dart';

/// Tracks, locally on-device, whether the onboarding carousel has already
/// been shown — so a returning user who signed out (or never signed up)
/// lands on Auth Landing instead of seeing onboarding again every launch.
/// Deliberately local-only (not stored in the backend): this is a
/// per-device UI preference, not account data, and should still remember
/// "seen" even for a user who's currently signed out.
class OnboardingPrefs {
  const OnboardingPrefs();

  static const _seenKey = 'has_seen_onboarding';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
