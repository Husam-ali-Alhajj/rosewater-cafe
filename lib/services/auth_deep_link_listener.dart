import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/set_new_password_screen.dart';
import 'supabase_client.dart';

/// Set the moment `AuthChangeEvent.passwordRecovery` fires, if it fires
/// before any widget exists to navigate anywhere -- see [listenForPasswordRecovery]
/// for why that's the common case on web, not an edge case. `AppEntryPoint`
/// checks this once, itself, right after `Supabase.initialize()` has
/// finished (i.e. on the very first frame) and routes to
/// [SetNewPasswordScreen] directly if it's true -- a fallback for exactly
/// the moment [listenForPasswordRecovery]'s own `navigatorKey` isn't ready
/// yet to act on the event itself.
bool pendingPasswordRecovery = false;

/// Listens for `AuthChangeEvent.passwordRecovery` -- the signal Supabase
/// fires the moment a password-recovery deep link is opened. This is NOT
/// something polled for: `supabase_flutter`'s own deep-link observer
/// (`app_links` under the hood, wired up automatically inside
/// `Supabase.initialize()`) detects the incoming link on startup or while
/// the app is running, exchanges its token for a short-lived recovery
/// session, and fires this event the moment that's done.
///
/// **On Flutter Web, that whole exchange -- and this event -- happens
/// INSIDE `Supabase.initialize()`'s own awaited chain, before `runApp()`
/// builds a single widget** (confirmed live: an earlier version of this
/// function used `navigatorKey.currentState?.pushAndRemoveUntil(...)` here
/// and nothing happened -- `currentState` was still null when the event
/// fired, so the `?.` silently no-opped, and the app fell through to
/// `AppEntryPoint`'s normal session-based routing instead). So this
/// function covers BOTH cases:
///
/// - The Navigator already exists (the event fires later, e.g. a second
///   recovery link opened while the app is already running): navigate
///   straight there.
/// - The Navigator doesn't exist yet (the web cold-start case, which is
///   the NORMAL case, not the exception): set [pendingPasswordRecovery]
///   instead, for `AppEntryPoint` to notice on its very first resolve.
///
/// Call this once, right after calling (not yet awaiting) `Supabase
/// .initialize()` in `main()` -- see that file's comment for why the timing
/// there matters too. The returned subscription is meant to live for the
/// app's whole lifetime -- there's nothing that ever needs to cancel it.
StreamSubscription<AuthState> listenForPasswordRecovery(GlobalKey<NavigatorState> navigatorKey) {
  return supabase.auth.onAuthStateChange.listen((data) {
    if (data.event != AuthChangeEvent.passwordRecovery) return;
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      pendingPasswordRecovery = true;
      return;
    }
    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SetNewPasswordScreen()), (route) => false);
  });
}
