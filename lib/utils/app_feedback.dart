import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/settings_provider.dart';

/// Sprint 8 Task 4 -- Sound & Haptic Feedback. A small, fixed set of real
/// trigger points (not every tap), matching what the design's own copy
/// implies ("Play sound when notifications arrive", "Vibrate on button
/// presses"):
///
/// - [triggerButtonPress] -- a primary button (`GradientButton`) was
///   pressed. Haptic only; sound is reserved for success/error below, not
///   every tap.
/// - [triggerSuccess] -- a successful action completed: payment confirmed,
///   door opened, reservation confirmed.
/// - [triggerError] -- an action failed: sign-in failed, payment failed.
///
/// Sound and haptics are gated **independently** by
/// `SettingsProvider.soundEnabled`/`.hapticsEnabled` -- sound off with
/// haptics on still vibrates, and vice versa, per the task's own
/// acceptance criterion. Falls back to both enabled when no
/// [SettingsProvider] is in the tree, the same fallback `context.colors`/
/// `context.animDuration` already use, so existing widget tests that pump
/// a screen directly keep working unchanged.
extension AppFeedbackX on BuildContext {
  void triggerButtonPress() => _haptic(this, HapticFeedback.lightImpact);

  void triggerSuccess() {
    _haptic(this, HapticFeedback.mediumImpact);
    _sound(this, SystemSoundType.click);
  }

  void triggerError() {
    _haptic(this, HapticFeedback.mediumImpact);
    _sound(this, SystemSoundType.alert);
  }
}

void _haptic(BuildContext context, Future<void> Function() impact) {
  if (_settings(context)?.hapticsEnabled ?? true) impact();
}

void _sound(BuildContext context, SystemSoundType type) {
  if (_settings(context)?.soundEnabled ?? true) SystemSound.play(type);
}

SettingsProvider? _settings(BuildContext context) {
  try {
    return context.read<SettingsProvider>();
  } on ProviderNotFoundException {
    return null;
  }
}
