import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/notification_arrival_feedback.dart';
import '../services/settings_provider.dart';

/// Sound and vibration feedback, used in a few places only:
///
/// - [triggerButtonPress]: a main button was pressed (vibration only).
/// - [triggerSuccess]: payment done, door opened, reservation confirmed.
/// - [triggerError]: sign-in or payment failed.
/// - [triggerNotificationArrived]: a notification arrived (see NotificationArrivalFeedback).
///
/// Sound and vibration follow their own App Settings switches separately. Both count as on when
/// there's no SettingsProvider (for example, in tests).
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

  Future<void> triggerNotificationArrived(NotificationArrivalFeedback feedback) {
    final settings = _settings(this);
    return feedback.onArrived(
      appSoundOn: settings?.soundEnabled ?? true,
      appHapticsOn: settings?.hapticsEnabled ?? true,
    );
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
