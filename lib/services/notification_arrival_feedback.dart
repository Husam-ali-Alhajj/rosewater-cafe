import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'notification_prefs.dart';

/// Plays a chime and vibrates when a notification arrives while the app is open.
///
/// Both switches must be on: Notifications > "Sound & Vibration", and App Settings > "Sound" (for
/// the chime) or "Haptic Feedback" (for vibration). The notification switch is read fresh each
/// time; if it can't be read, it counts as on.
///
/// Everything is passed in so this can be tested; [NotificationArrivalFeedback.live] uses the real
/// ones.
class NotificationArrivalFeedback {
  final Future<bool> Function() loadSoundPref;
  final Future<void> Function() playChime;
  final Future<void> Function() vibrate;

  const NotificationArrivalFeedback({required this.loadSoundPref, required this.playChime, required this.vibrate});

  factory NotificationArrivalFeedback.live() {
    final player = AudioPlayer();
    return NotificationArrivalFeedback(
      loadSoundPref: () async => (await const SupabaseNotificationPrefs().load()).isOn(NotificationSetting.sound),
      // Made for this app (assets/sounds/).
      playChime: () => player.play(AssetSource('sounds/notification_chime.wav')),
      vibrate: HapticFeedback.vibrate,
    );
  }

  Future<void> onArrived({required bool appSoundOn, required bool appHapticsOn}) async {
    if (!appSoundOn && !appHapticsOn) return; // nothing would play, so skip the check
    bool notificationSoundOn;
    try {
      notificationSoundOn = await loadSoundPref();
    } catch (_) {
      notificationSoundOn = NotificationSetting.sound.defaultValue;
    }
    if (!notificationSoundOn) return;
    // Handled separately, so a blocked sound doesn't stop the vibration.
    if (appSoundOn) {
      try {
        await playChime();
      } catch (_) {}
    }
    if (appHapticsOn) {
      try {
        await vibrate();
      } catch (_) {}
    }
  }
}
