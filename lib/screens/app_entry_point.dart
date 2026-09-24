import 'package:flutter/material.dart';
import '../services/auth_deep_link_listener.dart';
import '../services/onboarding_prefs.dart';
import '../services/remember_me_prefs.dart';
import '../services/subscription_service.dart';
import '../services/supabase_client.dart';
import '../theme/app_colors.dart';
import 'auth/auth_landing_screen.dart';
import 'auth/set_new_password_screen.dart';
import 'home/main_shell.dart';
import 'membership/choose_membership_screen.dart';
import 'onboarding/onboarding_screen.dart';

/// Decides the very first screen on app start, so a signed-in user is never
/// asked to sign in again after force-closing and reopening, and a
/// signed-out user only sees the onboarding carousel once.
///
/// `Supabase.initialize()` (awaited in main() before runApp()) already
/// recovers/refreshes any persisted session from SecureLocalStorage, so
/// `currentSession` here reflects the real signed-in state, not a stale
/// on-disk value.
///
/// **"Remember me" unchecked is also enforced right here** (decision #56):
/// a technically-valid session is signed out of on the spot if the last
/// sign-in asked not to be remembered, before this ever gets to the normal
/// Home/Choose Membership branch below. Checked (the default) changes
/// nothing -- this stays exactly the session-aware routing decision #15
/// originally built.
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    // A password-recovery link opened on Flutter Web fires its event
    // (auth_deep_link_listener.dart) INSIDE Supabase.initialize()'s own
    // awaited chain in main() -- before this widget, or any widget, exists.
    // The listener can't navigate anywhere at that point (no Navigator
    // yet), so it leaves this flag set instead; checked here, on the very
    // first resolve, before the normal session-based branching below gets
    // a say. Without this, a recovery link just logs the recovery session
    // in as if it were a normal one and lands on whatever the account's
    // subscription state would normally show -- confirmed live.
    if (pendingPasswordRecovery) {
      pendingPasswordRecovery = false;
      if (!mounted) return;
      setState(() => _destination = const SetNewPasswordScreen());
      return;
    }

    var session = supabase.auth.currentSession;
    // "Remember me" (decision #56): unchecked at the last sign-in forces a
    // sign-out here, on the next cold start -- not at sign-in or sign-out
    // time, and not "on close" (a mobile OS can kill a process with no
    // callback to act on). The session is technically still valid at this
    // point; this is the one place that's asked to actually end it.
    if (session != null && !await const RememberMePrefs().isRemembered()) {
      await supabase.auth.signOut();
      session = null;
    }

    Widget destination;
    if (session != null) {
      final hasActive = await const SubscriptionService().hasActiveSubscription();
      destination = hasActive ? const MainShell() : const ChooseMembershipScreen();
    } else {
      final seenOnboarding = await const OnboardingPrefs().hasSeenOnboarding();
      destination = seenOnboarding ? const AuthLandingScreen() : const OnboardingScreen();
    }
    if (!mounted) return;
    setState(() => _destination = destination);
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    if (destination == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return destination;
  }
}
