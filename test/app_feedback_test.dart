import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rosewater_cafe/services/settings_provider.dart';
import 'package:rosewater_cafe/utils/app_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 8 Task 4 -- Sound & Haptic Feedback. Proves the acceptance
/// criterion directly: sound and haptics are gated INDEPENDENTLY (sound off
/// + haptics on still vibrates, and vice versa) -- by recording the actual
/// platform-channel calls `context.triggerButtonPress`/`.triggerSuccess`/
/// `.triggerError` make, rather than trusting the wiring by inspection.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Records every `HapticFeedback`/`SystemSound` platform-channel call
  /// made during [body], instead of letting them silently no-op against
  /// the test binding's default (unmocked) handler.
  Future<List<String>> recordPlatformCalls(
    WidgetTester tester, {
    required SettingsProvider settings,
    required void Function(BuildContext) body,
  }) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          home: Builder(builder: (context) {
            body(context);
            return const SizedBox();
          }),
        ),
      ),
    );
    return calls;
  }

  group('triggerButtonPress', () {
    testWidgets('vibrates (light impact) when haptics is on', (tester) async {
      final settings = await SettingsProvider.load();
      final calls = await recordPlatformCalls(
        tester,
        settings: settings,
        body: (context) => context.triggerButtonPress(),
      );
      expect(calls, contains('HapticFeedback.vibrate'));
    });

    testWidgets('does nothing when haptics is off', (tester) async {
      final settings = await SettingsProvider.load();
      await settings.setHapticsEnabled(false);
      final calls = await recordPlatformCalls(
        tester,
        settings: settings,
        body: (context) => context.triggerButtonPress(),
      );
      // Not `isEmpty` -- MaterialApp itself makes unrelated platform calls
      // (e.g. SystemChrome.setApplicationSwitcherDescription) on this same
      // channel during startup; only the specific call this triggers is
      // the point of the test.
      expect(calls, isNot(contains('HapticFeedback.vibrate')));
    });
  });

  group('triggerSuccess / triggerError -- sound and haptics gate independently', () {
    testWidgets('sound OFF + haptics ON: still vibrates, no sound', (tester) async {
      final settings = await SettingsProvider.load();
      await settings.setSoundEnabled(false);
      final calls = await recordPlatformCalls(
        tester,
        settings: settings,
        body: (context) => context.triggerSuccess(),
      );
      expect(calls, contains('HapticFeedback.vibrate'));
      expect(calls, isNot(contains('SystemSound.play')));
    });

    testWidgets('sound ON + haptics OFF: still plays a sound, no vibration', (tester) async {
      final settings = await SettingsProvider.load();
      await settings.setHapticsEnabled(false);
      final calls = await recordPlatformCalls(
        tester,
        settings: settings,
        body: (context) => context.triggerSuccess(),
      );
      expect(calls, isNot(contains('HapticFeedback.vibrate')));
      expect(calls, contains('SystemSound.play'));
    });

    testWidgets('both ON: vibrates AND plays a sound', (tester) async {
      final settings = await SettingsProvider.load();
      final calls = await recordPlatformCalls(
        tester,
        settings: settings,
        body: (context) => context.triggerSuccess(),
      );
      expect(calls, contains('HapticFeedback.vibrate'));
      expect(calls, contains('SystemSound.play'));
    });

    testWidgets('both OFF: neither', (tester) async {
      final settings = await SettingsProvider.load();
      await settings.setSoundEnabled(false);
      await settings.setHapticsEnabled(false);
      final calls = await recordPlatformCalls(
        tester,
        settings: settings,
        body: (context) => context.triggerError(),
      );
      expect(calls, isNot(contains('HapticFeedback.vibrate')));
      expect(calls, isNot(contains('SystemSound.play')));
    });

    testWidgets('triggerError also gates independently', (tester) async {
      final settings = await SettingsProvider.load();
      await settings.setSoundEnabled(false);
      final calls = await recordPlatformCalls(
        tester,
        settings: settings,
        body: (context) => context.triggerError(),
      );
      expect(calls, contains('HapticFeedback.vibrate'));
      expect(calls, isNot(contains('SystemSound.play')));
    });
  });

  group('no SettingsProvider in the tree', () {
    testWidgets('falls back to both enabled, same as context.colors/context.animDuration', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call.method);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          context.triggerSuccess();
          return const SizedBox();
        }),
      ));

      expect(calls, contains('HapticFeedback.vibrate'));
      expect(calls, contains('SystemSound.play'));
    });
  });
}
