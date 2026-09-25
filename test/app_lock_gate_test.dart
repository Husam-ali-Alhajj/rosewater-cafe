import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rosewater_cafe/services/settings_provider.dart';
import 'package:rosewater_cafe/widgets/app_lock_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 8 Task 5 -- Auto-Lock's actual triggering logic: does resuming
/// from background show the lock screen or not, for every combination the
/// acceptance criteria and the task's own scoping decisions call for. The
/// unlock interaction itself (biometric attempt, password fallback) is
/// AppLockScreen's own responsibility, tested separately in
/// app_lock_screen_test.dart -- this file only covers whether/when
/// AppLockGate decides to show it.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpGate(
    WidgetTester tester, {
    required SettingsProvider settings,
    required DateTime Function() now,
    bool hasSession = true,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          home: AppLockGate(
            now: now,
            hasSession: () => hasSession,
            child: const Scaffold(body: Text('screen content')),
          ),
        ),
      ),
    );
  }

  void pause(WidgetTester tester) => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  void resume(WidgetTester tester) => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

  testWidgets('shows nothing extra before any lifecycle change', (tester) async {
    final settings = await SettingsProvider.load();
    await settings.setAutoLockEnabled(true);
    await pumpGate(tester, settings: settings, now: () => DateTime(2026, 1, 1));

    expect(find.text('screen content'), findsOneWidget);
    expect(find.text('App Locked'), findsNothing);
  });

  testWidgets('locks on resume when elapsed time exceeds the timeout, Auto-Lock on, signed in', (tester) async {
    final settings = await SettingsProvider.load();
    await settings.setAutoLockEnabled(true);
    await settings.setAutoLockTimeoutSeconds(60);
    var clock = DateTime(2026, 1, 1, 12, 0, 0);
    await pumpGate(tester, settings: settings, now: () => clock);

    pause(tester);
    clock = clock.add(const Duration(minutes: 5)); // well past the 60s timeout
    resume(tester);
    await tester.pump();

    expect(find.text('App Locked'), findsOneWidget);
  });

  testWidgets('does NOT lock when elapsed time is under the timeout', (tester) async {
    final settings = await SettingsProvider.load();
    await settings.setAutoLockEnabled(true);
    await settings.setAutoLockTimeoutSeconds(300);
    var clock = DateTime(2026, 1, 1, 12, 0, 0);
    await pumpGate(tester, settings: settings, now: () => clock);

    pause(tester);
    clock = clock.add(const Duration(seconds: 30)); // under the 300s timeout
    resume(tester);
    await tester.pump();

    expect(find.text('App Locked'), findsNothing);
  });

  testWidgets('does NOT lock when Auto-Lock is off, no matter how long elapsed', (tester) async {
    final settings = await SettingsProvider.load(); // autoLockEnabled defaults to false
    var clock = DateTime(2026, 1, 1, 12, 0, 0);
    await pumpGate(tester, settings: settings, now: () => clock);

    pause(tester);
    clock = clock.add(const Duration(hours: 1));
    resume(tester);
    await tester.pump();

    expect(find.text('App Locked'), findsNothing);
  });

  testWidgets('does NOT lock when there is no signed-in session', (tester) async {
    final settings = await SettingsProvider.load();
    await settings.setAutoLockEnabled(true);
    await settings.setAutoLockTimeoutSeconds(60);
    var clock = DateTime(2026, 1, 1, 12, 0, 0);
    await pumpGate(tester, settings: settings, now: () => clock, hasSession: false);

    pause(tester);
    clock = clock.add(const Duration(minutes: 5));
    resume(tester);
    await tester.pump();

    expect(find.text('App Locked'), findsNothing);
  });

  testWidgets('a resume with no matching paused (e.g. a transient inactive blip) does not lock', (tester) async {
    final settings = await SettingsProvider.load();
    await settings.setAutoLockEnabled(true);
    await settings.setAutoLockTimeoutSeconds(0); // would lock instantly if it engaged at all
    await pumpGate(tester, settings: settings, now: () => DateTime(2026, 1, 1));

    resume(tester); // resumed without ever having paused
    await tester.pump();

    expect(find.text('App Locked'), findsNothing);
  });

  testWidgets('the lock screen shows the password fallback when Biometric is off', (tester) async {
    final settings = await SettingsProvider.load();
    await settings.setAutoLockEnabled(true);
    await settings.setAutoLockTimeoutSeconds(60);
    var clock = DateTime(2026, 1, 1, 12, 0, 0);
    await pumpGate(tester, settings: settings, now: () => clock);

    pause(tester);
    clock = clock.add(const Duration(minutes: 5));
    resume(tester);
    await tester.pump();

    expect(find.text('App Locked'), findsOneWidget);
    expect(find.text('Enter your password to continue.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
  });
}
