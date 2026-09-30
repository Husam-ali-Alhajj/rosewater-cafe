import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/notification_arrival_feedback.dart';

/// Records what would have played, with a configurable "Sound & Vibration" switch.
class _Rig {
  final List<String> log = [];
  final Object? prefOrError; // bool, or something to throw
  final bool chimeFails;

  _Rig({this.prefOrError = true, this.chimeFails = false});

  late final feedback = NotificationArrivalFeedback(
    loadSoundPref: () async {
      log.add('read-pref');
      final p = prefOrError;
      if (p is bool) return p;
      throw p!;
    },
    playChime: () async {
      log.add('chime');
      if (chimeFails) throw StateError('autoplay blocked');
    },
    vibrate: () async => log.add('vibrate'),
  );

  List<String> get played => log.where((e) => e != 'read-pref').toList();
}

void main() {
  test('everything on: chime and vibration', () async {
    final rig = _Rig();
    await rig.feedback.onArrived(appSoundOn: true, appHapticsOn: true);
    expect(rig.played, ['chime', 'vibrate']);
  });

  test('notification Sound & Vibration off: nothing at all', () async {
    final rig = _Rig(prefOrError: false);
    await rig.feedback.onArrived(appSoundOn: true, appHapticsOn: true);
    expect(rig.played, isEmpty);
  });

  test('app Sound off: no chime, still vibrates', () async {
    final rig = _Rig();
    await rig.feedback.onArrived(appSoundOn: false, appHapticsOn: true);
    expect(rig.played, ['vibrate']);
  });

  test('app Haptic off: chime, no vibration', () async {
    final rig = _Rig();
    await rig.feedback.onArrived(appSoundOn: true, appHapticsOn: false);
    expect(rig.played, ['chime']);
  });

  test('both app switches off: nothing, and the toggle is not even read', () async {
    final rig = _Rig();
    await rig.feedback.onArrived(appSoundOn: false, appHapticsOn: false);
    expect(rig.log, isEmpty);
  });

  test("the toggle can't be read: its default (on) applies", () async {
    final rig = _Rig(prefOrError: StateError('offline'));
    await rig.feedback.onArrived(appSoundOn: true, appHapticsOn: true);
    expect(rig.played, ['chime', 'vibrate']);
  });

  test('a chime that fails to play still vibrates', () async {
    final rig = _Rig(chimeFails: true);
    await rig.feedback.onArrived(appSoundOn: true, appHapticsOn: true);
    expect(rig.played, ['chime', 'vibrate']);
  });
}
