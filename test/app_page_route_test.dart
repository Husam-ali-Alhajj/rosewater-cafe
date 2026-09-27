import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rosewater_cafe/services/settings_provider.dart';
import 'package:rosewater_cafe/utils/app_animations.dart';
import 'package:rosewater_cafe/widgets/app_page_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 8 Task 3 -- Animations toggle. Covers the two mechanisms every
/// screen in the app was switched onto: [AppPageRoute]/[appRoute] for
/// screen-to-screen navigation, and the [AnimationDurationX.animDuration]
/// extension for everything else (switches, the FAQ chevron, the dots
/// indicator). The acceptance criterion itself ("compare a screen-to-screen
/// navigation with it on vs off") is the first group below.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AppPageRoute', () {
    test('transition duration is the normal ~300ms with animations on', () {
      final route = AppPageRoute<void>(builder: (_) => const SizedBox(), animationsEnabled: true);
      expect(route.transitionDuration, const Duration(milliseconds: 300));
      expect(route.reverseTransitionDuration, const Duration(milliseconds: 300));
    });

    test('transition duration collapses to near-zero, NOT literally zero, with animations off', () {
      final route = AppPageRoute<void>(builder: (_) => const SizedBox(), animationsEnabled: false);
      // The acceptance criterion's own explicit requirement: 1ms, not 0 --
      // a real, completing animation, not one some widget could choke on.
      expect(route.transitionDuration, isNot(Duration.zero));
      expect(route.transitionDuration, const Duration(milliseconds: 1));
      expect(route.reverseTransitionDuration, const Duration(milliseconds: 1));
    });
  });

  group('appRoute()', () {
    testWidgets('reads SettingsProvider.animationsEnabled at push time: on', (tester) async {
      final settings = await SettingsProvider.load(); // fresh install: animations on by default
      late Route<dynamic> pushed;
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: MaterialApp(
            navigatorObservers: [
              _CapturingObserver((route) => pushed = route),
            ],
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(appRoute(context, (_) => const SizedBox())),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();

      final route = pushed as AppPageRoute;
      expect(route.animationsEnabled, isTrue);
      expect(route.transitionDuration, const Duration(milliseconds: 300));
    });

    testWidgets('reads SettingsProvider.animationsEnabled at push time: off', (tester) async {
      final settings = await SettingsProvider.load();
      await settings.setAnimationsEnabled(false);
      late Route<dynamic> pushed;
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: MaterialApp(
            navigatorObservers: [
              _CapturingObserver((route) => pushed = route),
            ],
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(appRoute(context, (_) => const SizedBox())),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();

      final route = pushed as AppPageRoute;
      expect(route.animationsEnabled, isFalse);
      expect(route.transitionDuration, const Duration(milliseconds: 1));
    });

    testWidgets('falls back to animations-on when no SettingsProvider is in the tree', (tester) async {
      // The same fallback context.colors already relies on -- most of this
      // app's existing screen tests pump a screen directly without
      // registering SettingsProvider, and shouldn't all need to.
      late Route<dynamic> pushed;
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [
            _CapturingObserver((route) => pushed = route),
          ],
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(appRoute(context, (_) => const SizedBox())),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();

      expect((pushed as AppPageRoute).animationsEnabled, isTrue);
    });
  });

  group('context.animDuration', () {
    Widget appWith({required bool animationsEnabled, required Widget Function(BuildContext) builder}) {
      return FutureBuilder<SettingsProvider>(
        future: SettingsProvider.load().then((s) async {
          if (!animationsEnabled) await s.setAnimationsEnabled(false);
          return s;
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          return ChangeNotifierProvider<SettingsProvider>.value(
            value: snapshot.data!,
            child: MaterialApp(home: Builder(builder: builder)),
          );
        },
      );
    }

    testWidgets('returns the normal duration with animations on', (tester) async {
      Duration? result;
      await tester.pumpWidget(appWith(
        animationsEnabled: true,
        builder: (context) {
          result = context.animDuration(const Duration(milliseconds: 150));
          return const SizedBox();
        },
      ));
      await tester.pumpAndSettle();
      expect(result, const Duration(milliseconds: 150));
    });

    testWidgets('returns instantAnimationDuration (1ms, not 0) with animations off', (tester) async {
      Duration? result;
      await tester.pumpWidget(appWith(
        animationsEnabled: false,
        builder: (context) {
          result = context.animDuration(const Duration(milliseconds: 150));
          return const SizedBox();
        },
      ));
      await tester.pumpAndSettle();
      expect(result, instantAnimationDuration);
      expect(result, isNot(Duration.zero));
    });

    testWidgets('falls back to the normal duration when no SettingsProvider is in the tree', (tester) async {
      Duration? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          result = context.animDuration(const Duration(milliseconds: 150));
          return const SizedBox();
        }),
      ));
      expect(result, const Duration(milliseconds: 150));
    });
  });
}

class _CapturingObserver extends NavigatorObserver {
  _CapturingObserver(this.onPush);
  final void Function(Route<dynamic>) onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // The very first route is MaterialApp's own `home` route (a plain
    // PageRouteBuilder, not ours) -- only capture the one this test itself
    // pushes via `appRoute`.
    if (route is AppPageRoute) onPush(route);
  }
}
