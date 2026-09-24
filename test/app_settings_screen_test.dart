import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rosewater_cafe/screens/profile/app_settings_screen.dart';
import 'package:rosewater_cafe/services/app_settings_service.dart';
import 'package:rosewater_cafe/services/settings_provider.dart';
import 'package:rosewater_cafe/widgets/setting_toggle_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records calls instead of touching the real image cache / SharedPreferences
/// singleton, so the screen's own logic (confirm dialog, ordering, disabled
/// state while clearing) can be tested in isolation from AppSettingsService's
/// own already-covered behaviour (test/app_settings_service_test.dart).
class _FakeService extends AppSettingsService {
  _FakeService({this.bytes = 0});

  int bytes;
  int clearImageCacheCalls = 0;
  int clearLocalPreferencesCalls = 0;

  @override
  int cacheSizeBytes() => bytes;

  @override
  void clearImageCache() {
    clearImageCacheCalls++;
    bytes = 0;
  }

  @override
  Future<void> clearLocalPreferences() async {
    clearLocalPreferencesCalls++;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  AppSettingsService? service,
  Future<void> Function(BuildContext)? onDataCleared,
  SettingsProvider? settings,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // The Dark Mode row is real now (Sprint 8 Task 2): it reads/writes
  // `SettingsProvider`, the same provider `main.dart` registers above
  // `MaterialApp` for real -- so this screen needs one in its own widget
  // tree here too, the same way `main.dart` provides it.
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings ?? await SettingsProvider.load(),
      child: MaterialApp(
        home: AppSettingsScreen(service: service ?? _FakeService(), onDataCleared: onDataCleared ?? (_) async {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _isOn(WidgetTester tester, String key) =>
    tester.widget<SettingSwitch>(find.byKey(ValueKey(key))).value;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('layout matches the design', () {
    testWidgets('shows every section and row from the design', (tester) async {
      await _pump(tester);

      for (final text in [
        'App Settings',
        'Appearance',
        'Dark Mode',
        'Switch to dark theme',
        'Animations',
        'Enable smooth animations throughout the app',
        'Language',
        'English',
        'Arabic',
        'French',
        'Spanish',
        'Interactions',
        'Sound Effects',
        'Play sounds for actions and notifications',
        'Haptic Feedback',
        'Vibrate on button presses and interactions',
        'Data & Storage',
        'Cache Size',
        'Clear Cache',
        'Clear All App Data',
        'Rosewater Café',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('shows the real app version/build, not the design\'s mock build date', (tester) async {
      await _pump(tester);

      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(find.text('Build 1'), findsOneWidget);
      expect(find.textContaining('2024.01.14'), findsNothing); // the mock's fabricated date
    });
  });

  group('Dark Mode is real (Sprint 8 Task 2)', () {
    testWidgets('reflects SettingsProvider.themeMode and tapping flips it', (tester) async {
      final settings = await SettingsProvider.load();
      await _pump(tester, settings: settings);

      expect(settings.themeMode, ThemeMode.light);
      expect(_isOn(tester, 'dark-mode'), isFalse);

      await tester.tap(find.byKey(const ValueKey('dark-mode')));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.dark);
      expect(_isOn(tester, 'dark-mode'), isTrue);

      await tester.tap(find.byKey(const ValueKey('dark-mode')));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.light);
      expect(_isOn(tester, 'dark-mode'), isFalse);
    });

    testWidgets('starts on when SettingsProvider already has dark mode set', (tester) async {
      SharedPreferences.setMockInitialValues({'settings.theme_mode': 'dark'});
      final settings = await SettingsProvider.load();
      await _pump(tester, settings: settings);

      expect(_isOn(tester, 'dark-mode'), isTrue);
    });
  });

  group('decision #5: Language is visual only, never functional', () {
    testWidgets('only English shows selected, and no language row is tappable', (tester) async {
      await _pump(tester);

      expect(find.byIcon(Icons.check), findsOneWidget); // exactly one selected row

      // Tapping "Arabic" does nothing -- still only English selected.
      await tester.tap(find.text('Arabic'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('Animations / Sound Effects / Haptic Feedback: drawn at the design state, inert', () {
    testWidgets('all three are on and not tappable', (tester) async {
      await _pump(tester);

      for (final key in ['placeholder-animations', 'placeholder-sound-effects', 'placeholder-haptic-feedback']) {
        final sw = tester.widget<SettingSwitch>(find.byKey(ValueKey(key)));
        expect(sw.value, isTrue, reason: key);
        expect(sw.onTap, isNull, reason: key);
      }
    });
  });

  group('Data & Storage is real', () {
    testWidgets('Cache Size shows the real number from the service, not the design\'s fake "12.5 MB"', (tester) async {
      await _pump(tester, service: _FakeService(bytes: 2048));

      expect(find.text('2.0 KB'), findsOneWidget);
      expect(find.text('12.5 MB'), findsNothing);
    });

    testWidgets('Clear Cache calls the real service and updates the shown size', (tester) async {
      final service = _FakeService(bytes: 4096);
      await _pump(tester, service: service);
      expect(find.text('4.0 KB'), findsOneWidget);

      await tester.tap(find.text('Clear Cache'));
      await tester.pumpAndSettle();

      expect(service.clearImageCacheCalls, 1);
      expect(find.text('0 B'), findsOneWidget);
      expect(find.text('Cache cleared.'), findsOneWidget);
    });

    testWidgets('Clear All App Data asks for confirmation first', (tester) async {
      final service = _FakeService();
      await _pump(tester, service: service);

      await tester.tap(find.text('Clear All App Data'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all app data?'), findsOneWidget);
      expect(service.clearLocalPreferencesCalls, 0);
    });

    testWidgets('Cancel on the confirmation clears nothing', (tester) async {
      final service = _FakeService();
      await _pump(tester, service: service);

      await tester.tap(find.text('Clear All App Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(service.clearLocalPreferencesCalls, 0);
      expect(service.clearImageCacheCalls, 0);
    });

    testWidgets('confirming clears the image cache AND local preferences, THEN runs the post-clear step, in that order', (tester) async {
      final service = _FakeService(bytes: 999);
      final log = <String>[];
      await _pump(
        tester,
        service: service,
        onDataCleared: (_) async => log.add('signed out'),
      );

      await tester.tap(find.text('Clear All App Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear & Sign Out'));
      await tester.pumpAndSettle();

      expect(service.clearImageCacheCalls, 1);
      expect(service.clearLocalPreferencesCalls, 1);
      expect(log, ['signed out']);
    });

    testWidgets('with no onDataCleared override, real prefs are really wiped (the default path only fakes the sign-out)', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      final realService = AppSettingsService();

      await _pump(tester, service: realService, onDataCleared: (_) async {});
      await tester.tap(find.text('Clear All App Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear & Sign Out'));
      await tester.pumpAndSettle();

      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });
  });
}
