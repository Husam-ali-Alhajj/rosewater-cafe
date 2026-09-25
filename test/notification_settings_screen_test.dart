import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/screens/profile/notification_settings_screen.dart';
import 'package:rosewater_cafe/services/notification_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefs = NotificationPrefs(userId: 'u1');

/// Fails every write, to prove the switch doesn't keep lying about a value
/// that wasn't saved.
class _FailingPrefs extends NotificationPrefs {
  const _FailingPrefs() : super(userId: 'u1');

  @override
  Future<void> set(NotificationSetting setting, bool value) => throw StateError('disk full');
}

Future<void> _pump(WidgetTester tester, {NotificationPrefs prefs = _prefs}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      // Sprint 8 Task 6 Phase 2: ScreenHeader now reads AppLocalizations for
      // its back button -- this screen's own strings aren't localized yet.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NotificationSettingsScreen(prefs: prefs),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _switch(NotificationSetting s) => find.byKey(ValueKey('toggle-${s.name}'));

/// Whether the switch is showing "on" -- the design's red `#EC003F` track.
bool _isOn(WidgetTester tester, NotificationSetting s) {
  final track = tester.widget<AnimatedContainer>(
    find.descendant(of: _switch(s), matching: find.byType(AnimatedContainer)),
  );
  return (track.decoration! as BoxDecoration).color == const Color(0xFFEC003F);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows both cards, every label and description, and Done', (tester) async {
    await _pump(tester);

    for (final text in [
      'Notifications',
      'Communication Preferences',
      'Choose how you want to be notified',
      'Push Notifications',
      'Receive notifications on your device',
      'Email Notifications',
      'Get updates via email',
      'SMS Notifications',
      'Receive text messages for important updates',
      'Sound & Vibration',
      'Play sound when notifications arrive',
      'Notification Types',
      'Event Reminders',
      'Get reminded about your upcoming reservations',
      'Allowance Alerts',
      'Notify when allowances are running low',
      'Promotions & Offers',
      'Receive special deals and member benefits',
      'Done',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('starts in the design state: SMS off, all six others on', (tester) async {
    await _pump(tester);

    for (final s in NotificationSetting.values) {
      expect(_isOn(tester, s), s != NotificationSetting.sms, reason: s.name);
    }
  });

  testWidgets('tapping a switch flips it and saves it to the device', (tester) async {
    await _pump(tester);

    await tester.tap(_switch(NotificationSetting.sms));
    await tester.pumpAndSettle();
    await tester.tap(_switch(NotificationSetting.push));
    await tester.pumpAndSettle();

    expect(_isOn(tester, NotificationSetting.sms), isTrue);
    expect(_isOn(tester, NotificationSetting.push), isFalse);
    final stored = await SharedPreferences.getInstance();
    expect(stored.getBool('notification_settings.u1.sms'), isTrue);
    expect(stored.getBool('notification_settings.u1.push'), isFalse);
  });

  testWidgets('the toggles are still as left after the app is closed and reopened', (tester) async {
    await _pump(tester);
    await tester.tap(_switch(NotificationSetting.sms));
    await tester.pumpAndSettle();
    await tester.tap(_switch(NotificationSetting.eventReminders));
    await tester.pumpAndSettle();

    // "Close the app": tear down the screen and drop the in-memory cache.
    await tester.pumpWidget(const SizedBox());
    SharedPreferences.resetStatic();

    // "Reopen": a brand-new screen reads what's on the device.
    await _pump(tester);
    expect(_isOn(tester, NotificationSetting.sms), isTrue); // was off by default
    expect(_isOn(tester, NotificationSetting.eventReminders), isFalse); // was on by default
    expect(_isOn(tester, NotificationSetting.email), isTrue); // untouched
  });

  testWidgets("another user's saved choices don't show here", (tester) async {
    await const NotificationPrefs(userId: 'someone-else').set(NotificationSetting.sound, false);

    await _pump(tester);
    expect(_isOn(tester, NotificationSetting.sound), isTrue);
  });

  testWidgets('a failed save puts the switch back and says so', (tester) async {
    await _pump(tester, prefs: const _FailingPrefs());

    await tester.tap(_switch(NotificationSetting.push));
    await tester.pumpAndSettle();

    expect(_isOn(tester, NotificationSetting.push), isTrue); // reverted to what's actually stored
    expect(find.text("Couldn't save that setting. Please try again."), findsOneWidget);
  });

  testWidgets('Done and the back arrow both leave the screen', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> open() async {
      await tester.pumpWidget(
        MaterialApp(
          // Sprint 8 Task 6 Phase 2: ScreenHeader now reads AppLocalizations
          // for its back button -- this screen isn't localized yet.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen(prefs: _prefs)),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    await open();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
