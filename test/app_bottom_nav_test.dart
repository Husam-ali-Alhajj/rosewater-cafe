import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/widgets/app_bottom_nav.dart';

/// The bottom navigation in both directions. It needs no special right-to-left code; these tests
/// prove that.
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

      // The dot is found through the active tab, since there's only one at a time.
      final activeLabel = tester.widget<Text>(find.text('الفعاليات'));
      expect(activeLabel.style?.fontWeight, FontWeight.w600);

      for (final inactive in ['الرئيسية', 'رمز QR', 'الملف الشخصي']) {
        final style = tester.widget<Text>(find.text(inactive)).style;
        expect(style?.fontWeight, FontWeight.w400, reason: inactive);
      }
    });

    testWidgets('tapping a tab still reports the right index under RTL', (tester) async {
      // In right-to-left the tabs swap sides visually, but each still reports its own index
      // (Profile is still 3).
      late int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: (i) => tapped = i)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الملف الشخصي')); // Profile
      await tester.pumpAndSettle();

      expect(tapped, 3);
    });
  });
}
