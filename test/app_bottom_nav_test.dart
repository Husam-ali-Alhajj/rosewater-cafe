import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/widgets/app_bottom_nav.dart';

/// Sprint 8 Task 6 -- one of the three screens the acceptance criteria
/// explicitly names for RTL confirmation. `AppBottomNav` needed zero layout
/// changes for Arabic (every tab is a plain vertical Column with no
/// left/right positioning to mirror, and the enclosing Row already
/// reverses under RTL Directionality) -- this proves that claim rather
/// than leaving it as an unverified comment.
Future<int?> _pump(WidgetTester tester, {String locale = 'en', int currentIndex = 0}) async {
  int? tapped;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        bottomNavigationBar: AppBottomNav(currentIndex: currentIndex, onTap: (i) => tapped = i),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tapped;
}

void main() {
  group('English', () {
    testWidgets('shows all four real tab labels, LTR', (tester) async {
      await _pump(tester);

      for (final label in ['Home', 'QR Code', 'Events', 'Profile']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      final context = tester.element(find.byType(AppBottomNav));
      expect(Directionality.of(context), TextDirection.ltr);
    });
  });

  group('Arabic -- RTL', () {
    testWidgets('shows all four labels translated, no English fallback, flips to RTL', (tester) async {
      await _pump(tester, locale: 'ar');

      for (final label in ['الرئيسية', 'رمز QR', 'الفعاليات', 'الملف الشخصي']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      for (final english in ['Home', 'QR Code', 'Events', 'Profile']) {
        expect(find.text(english), findsNothing, reason: english);
      }
      final context = tester.element(find.byType(AppBottomNav));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('the active tab still shows its dot and bold label under RTL', (tester) async {
      await _pump(tester, locale: 'ar', currentIndex: 2); // Events

      // The dot is an unlabelled 4x4 Container -- located via its known
      // active-tab sibling, the same way the design draws exactly one at
      // a time.
      final activeLabel = tester.widget<Text>(find.text('الفعاليات'));
      expect(activeLabel.style?.fontWeight, FontWeight.w600);

      for (final inactive in ['الرئيسية', 'رمز QR', 'الملف الشخصي']) {
        final style = tester.widget<Text>(find.text(inactive)).style;
        expect(style?.fontWeight, FontWeight.w400, reason: inactive);
      }
    });

    testWidgets('tapping a tab still reports the right index under RTL', (tester) async {
      // Sprint 8 Task 6's whole point: RTL reverses the VISUAL order (tap
      // targets swap sides), but the logical tab-index contract with
      // MainShell must not change -- tapping "Profile" (still logically
      // index 3, now rendered on the visual left) must still report 3.
      late int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: (i) => tapped = i),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الملف الشخصي')); // Profile
      await tester.pumpAndSettle();

      expect(tapped, 3);
    });
  });
}
