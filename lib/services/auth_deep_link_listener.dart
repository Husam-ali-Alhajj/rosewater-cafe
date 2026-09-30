import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/set_new_password_screen.dart';
import '../widgets/app_page_route.dart';
import 'supabase_client.dart';

/// Set when a password-reset link arrives before the app can navigate (common on web).
/// AppEntryPoint checks it on start and opens Set New Password.
bool pendingPasswordRecovery = false;

/// Listens for Supabase's password-recovery event, fired when a reset link is opened.
///
/// On web this happens inside Supabase.initialize(), before any screen exists, so there are two
/// cases: if navigation is ready, go straight to Set New Password; if not, set
/// [pendingPasswordRecovery] for AppEntryPoint.
///
/// Call once in main(), before awaiting Supabase.initialize(). The subscription lives as long as
/// the app.
StreamSubscription<AuthState> listenForPasswordRecovery(GlobalKey<NavigatorState> navigatorKey) {
  return supabase.auth.onAuthStateChange.listen((data) {
    if (data.event != AuthChangeEvent.passwordRecovery) return;
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      pendingPasswordRecovery = true;
      return;
    }
    // The navigator's context is a real context inside the app, so screens opened from here can
    // read the settings.
    navigator.pushAndRemoveUntil(appRoute(navigator.context, (_) => const SetNewPasswordScreen()), (route) => false);
  });
}
