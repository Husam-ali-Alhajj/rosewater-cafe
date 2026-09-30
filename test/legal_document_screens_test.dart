import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/widgets/legal_document_screen.dart';
import 'package:rosewater_cafe/screens/profile/privacy_policy_screen.dart';
import 'package:rosewater_cafe/screens/profile/terms_of_service_screen.dart';

Future<void> _pump(WidgetTester tester, Widget child, {String locale = 'en'}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('Sprint 9 Task 5: Privacy Policy / Terms of Service are real screens', () {
    testWidgets('Privacy Policy renders real section content, not a blank/coming-soon stub', (tester) async {
      await _pump(tester, const PrivacyPolicyScreen());

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.textContaining('Coming soon'), findsNothing);
      expect(find.text('1. Introduction'), findsOneWidget);
      expect(find.textContaining('delete_own_account', findRichText: true), findsNothing);
      // Names a real table-backed data category, not generic filler.
      expect(find.textContaining('Identity Verification Documents'), findsOneWidget);
      // The account-deletion section accurately reflects decision #52: immediate,
      // self-service, no request queue -- not the old queued-request behavior.
      expect(find.textContaining('no staff-processed request queue'), findsOneWidget);
    });

    testWidgets('Privacy Policy shows the draft/not-legal-advice disclaimer', (tester) async {
      await _pump(tester, const PrivacyPolicyScreen());

      expect(find.textContaining('not written or reviewed by a lawyer'), findsOneWidget);
      expect(find.textContaining('not final legal coverage'), findsOneWidget);
    });

    testWidgets('Terms of Service renders real section content, not a blank/coming-soon stub', (tester) async {
      await _pump(tester, const TermsOfServiceScreen());

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.textContaining('Coming soon'), findsNothing);
      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
      // States this app's actual upgrade-only rule (decision #75), not a generic
      // "you may change plans" line that wouldn't be true here.
      expect(find.textContaining('does not currently support self-service'), findsOneWidget);
    });

    testWidgets('Terms of Service shows the draft/not-legal-advice disclaimer', (tester) async {
      await _pump(tester, const TermsOfServiceScreen());

      expect(find.textContaining('not written or reviewed by a lawyer'), findsOneWidget);
    });

    testWidgets('back button pops both screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Privacy Policy'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Privacy Policy'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('Arabic versions', () {
    List<LegalSection> sectionsOf(WidgetTester tester) =>
        tester.widget<LegalDocumentScreen>(find.byType(LegalDocumentScreen)).sections;

    testWidgets('Privacy Policy is shown in Arabic when the app is in Arabic', (tester) async {
      await _pump(tester, const PrivacyPolicyScreen(), locale: 'ar');
      expect(find.text('1. مقدمة'), findsOneWidget);
      expect(find.textContaining('مستندات التحقق من الهوية'), findsOneWidget);
      expect(find.textContaining('الخصوصية والأمان ← حذف الحساب'), findsOneWidget); // the real Arabic menu names
      expect(find.text('1. Introduction'), findsNothing);
      expect(find.textContaining('لم تتم كتابته أو مراجعته من قبل محامٍ'), findsOneWidget); // draft banner
    });

    testWidgets('Terms of Service is shown in Arabic when the app is in Arabic', (tester) async {
      await _pump(tester, const TermsOfServiceScreen(), locale: 'ar');
      expect(find.text('1. قبول الشروط'), findsOneWidget);
      expect(find.textContaining('لا يدعم التطبيق حاليًا الانتقال الذاتي'), findsOneWidget); // upgrade-only rule
      expect(find.text('1. Acceptance of Terms'), findsNothing);
    });

    testWidgets('each Arabic document has exactly as many sections as its English one', (tester) async {
      for (final screen in const [PrivacyPolicyScreen(), TermsOfServiceScreen()]) {
        await _pump(tester, screen);
        final english = sectionsOf(tester);
        await _pump(tester, screen, locale: 'ar');
        final arabic = sectionsOf(tester);
        expect(arabic.length, english.length, reason: '${screen.runtimeType}');
        for (var i = 0; i < english.length; i++) {
          // Same numbering, section by section ("3. ..." <-> "3. ...").
          expect(arabic[i].heading.split('.').first, english[i].heading.split('.').first);
        }
      }
    });
  });
}
