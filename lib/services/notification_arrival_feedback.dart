import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'notification_prefs.dart';

/// What happens the moment a new notification arrives while the app is
/// open (notifications roadmap step 4, decision #71): a short chime and a
/// vibration -- the "Sound & Vibration" toggle's real job ("Play sound
/// when notifications arrive").
///
/// Both switches must allow it (user's decision): the notification's own
/// "Sound & Vibration" toggle AND the app-wide App Settings switch --
/// "Sound" for the chime, "Haptic Feedback" for the vibration. Turning app
/// sound off always means silence.
///
/// The toggle is re-read from the database on every arrival rather than
/// cached, so flipping it takes effect immediately. If it can't be read,
/// the toggle's default (on) applies -- the app switches still gate it.
///
/// Every dependency is a parameter so the rule is unit-testable;
/// [NotificationArrivalFeedback.live] wires up the real ones.
class NotificationArrivalFeedback {
  final Future<bool> Function() loadSoundPref;
  final Future<void> Function() playChime;
  final Future<void> Function() vibrate;

  const NotificationArrivalFeedback({required this.loadSoundPref, required this.playChime, required this.vibrate});

  factory NotificationArrivalFeedback.live() {
    final player = AudioPlayer();
    return NotificationArrivalFeedback(
      loadSoundPref: () async =>
          (await const SupabaseNotificationPrefs().load()).isOn(NotificationSetting.sound),
      // Generated for this app (assets/sounds/), no third-party audio.
      playChime: () => player.play(AssetSource('sounds/notification_chime.wav')),
      vibrate: HapticFeedback.vibrate,
    );
  }

  Future<void> onArrived({required bool appSoundOn, required bool appHapticsOn}) async {
    if (!appSoundOn && !appHapticsOn) return; // nothing could happen -- skip the query
    bool notificationSoundOn;
    try {
      notificationSoundOn = await loadSoundPref();
    } catch (_) {
      notificationSoundOn = NotificationSetting.sound.defaultValue;
    }
    if (!notificationSoundOn) return;
    // Independent of each other: a failed chime (e.g. the browser refusing
    // to play audio) must not also cancel the vibration.
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
