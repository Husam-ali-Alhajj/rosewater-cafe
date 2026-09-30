import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_provider.dart';
import '../services/supabase_client.dart';
import 'app_lock_screen.dart';

/// Wraps the whole app so Auto-Lock can show the lock screen on top of any screen when the app
/// comes back after being away too long.
///
/// Uses the paused/resumed states (not "inactive", which also fires for things like permission
/// dialogs). Only locks signed-in sessions.
class AppLockGate extends StatefulWidget {
  final Widget child;

  /// The clock; replaceable in tests.
  final DateTime Function() now;

  /// Whether someone is signed in; replaceable in tests.
  final bool Function() hasSession;

  AppLockGate({super.key, required this.child, DateTime Function()? now, bool Function()? hasSession})
    : now = now ?? DateTime.now,
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
    if (pausedAt == null) return; // resumed without a pause first
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
            child: AppLockScreen(biometricEnabled: biometricEnabled, onUnlocked: () => setState(() => _locked = false)),
          ),
      ],
    );
  }
}
