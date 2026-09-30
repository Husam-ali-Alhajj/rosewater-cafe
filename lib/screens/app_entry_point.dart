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

/// Picks the first screen on app start: signed-in users skip sign-in, and onboarding is only shown
/// once.
///
/// If the last sign-in unticked "Remember me", the session is ended here.
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
    // On web, a password-reset link is handled before any widget exists, so the listener leaves a
    // flag for us to check here first.
    if (pendingPasswordRecovery) {
      pendingPasswordRecovery = false;
      if (!mounted) return;
      setState(() => _destination = const SetNewPasswordScreen());
      return;
    }

    var session = supabase.auth.currentSession;
    // "Remember me" was unticked: sign out on the next app start (there's no reliable "app closed"
    // event on mobile).
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
