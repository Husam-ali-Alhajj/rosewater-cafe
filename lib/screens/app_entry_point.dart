import 'package:flutter/material.dart';
import '../services/onboarding_prefs.dart';
import '../services/subscription_service.dart';
import '../services/supabase_client.dart';
import '../theme/app_colors.dart';
import '../widgets/coming_soon_screen.dart';
import 'auth/auth_landing_screen.dart';
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
    final session = supabase.auth.currentSession;
    Widget destination;
    if (session != null) {
      final hasActive = await const SubscriptionService().hasActiveSubscription();
      destination = hasActive
          ? const ComingSoonScreen(label: 'Home', showSignOut: true)
          : const ChooseMembershipScreen();
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
