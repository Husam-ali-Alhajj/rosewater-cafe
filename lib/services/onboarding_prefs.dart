import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this device whether onboarding was already shown, so it only appears once.
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
