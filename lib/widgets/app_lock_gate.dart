import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_provider.dart';
import '../services/supabase_client.dart';
import 'app_lock_screen.dart';

/// Sprint 8 Task 5 -- wraps the whole app (via `MaterialApp.builder` in
/// `main.dart`) so Auto-Lock can show its lock screen over whatever screen
/// happens to be on top of the navigation stack when the app resumes, not
/// just at cold start. `AppEntryPoint`'s session-based routing (decision
/// #15) still decides what's UNDER this gate; this only ever decides
/// whether that content is currently hidden.
///
/// Tracks [AppLifecycleState.paused]/`.resumed` specifically -- not
/// `.inactive`, which can flicker on and off during perfectly normal use
/// (a system permission dialog, an incoming call banner) without the app
/// ever having actually left the foreground.
///
/// Scoped to signed-in sessions only: nothing sensitive exists before
/// sign-in, and locking Onboarding/Sign In itself would be a dead end, not
/// a security feature.
class AppLockGate extends StatefulWidget {
  final Widget child;

  /// Overridable so a test can control elapsed time without actually
  /// waiting on it -- defaults to the real clock.
  final DateTime Function() now;

  /// Overridable so a test doesn't need a real signed-in Supabase session
  /// to prove the "only when signed in" scoping -- defaults to the real
  /// check.
  final bool Function() hasSession;

  AppLockGate({
    super.key,
    required this.child,
    DateTime Function()? now,
    bool Function()? hasSession,
  }) : now = now ?? DateTime.now,
       hasSession = hasSession ?? (() => supabase.auth.currentSession != null);

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  DateTime? _pausedAt;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = widget.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null) return; // resumed without a matching paused (e.g. straight from `inactive`)
    if (!widget.hasSession()) return;

    final settings = context.read<SettingsProvider>();
    if (!settings.autoLockEnabled) return;

    final elapsed = widget.now().difference(pausedAt);
    if (elapsed >= Duration(seconds: settings.autoLockTimeoutSeconds)) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final biometricEnabled = context.watch<SettingsProvider>().biometricEnabled;
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: AppLockScreen(
              biometricEnabled: biometricEnabled,
              onUnlocked: () => setState(() => _locked = false),
            ),
          ),
      ],
    );
  }
}
