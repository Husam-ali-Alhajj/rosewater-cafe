import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/screens/auth/sign_in_screen.dart';

/// Sprint 8 Task 6 -- i18n + RTL. `SignInScreen` doesn't take an injectable
/// `AuthService` (a pre-existing gap, not this task's to fix), so this only
/// covers what doesn't need a live backend: rendering in both locales, the
/// RTL-specific fixes (the back arrow's direction, `Directionality` itself),
/// and the one client-side validator this screen owns.
Future<void> _pump(WidgetTester tester, {String locale = 'en'}) async {
  // A generous canvas, same convention every other screen test in this
  // suite uses (e.g. home_content_test.dart, privacy_security_screen_test.dart)
  // -- narrow-width responsiveness is a separate, pre-existing concern from
  // this task's actual scope (i18n/RTL), and testing at ~400px surfaces a
  // RenderFlex overflow in BOTH languages equally (confirmed independently
  // -- not an RTL-specific regression), which would conflate the two.
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SignInScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('English', () {
    testWidgets('shows every real string, LTR, back arrow pointing left', (tester) async {
      await _pump(tester);

      for (final text in [
        'Welcome Back',
        'Sign in to your account',
        'Email Address',
        'Password',
        'Remember me',
        'Forgot Password?',
        'Sign In',
        "Don't have an account?",
        'Create Account',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }

      final context = tester.element(find.byType(SignInScreen));
      expect(Directionality.of(context), TextDirection.ltr);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('an empty password shows the real validator message, client-side, no network call', (tester) async {
      await _pump(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'member@example.com');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });
  });

  group('Arabic -- the real test of correctness, not just translation', () {
    testWidgets('shows every string translated, flips to RTL, back arrow points right', (tester) async {
      await _pump(tester, locale: 'ar');

      for (final text in [
        'مرحبًا بعودتك',
        'سجّل الدخول إلى حسابك',
        'البريد الإلكتروني',
        'كلمة المرور',
        'تذكرني',
        'هل نسيت كلمة المرور؟',
        'تسجيل الدخول',
        'ليس لديك حساب؟',
        'إنشاء حساب',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }

      // No missing-key fallback to English anywhere.
      for (final englishText in ['Welcome Back', 'Sign In', 'Remember me']) {
        expect(find.text(englishText), findsNothing, reason: englishText);
      }

      final context = tester.element(find.byType(SignInScreen));
      expect(Directionality.of(context), TextDirection.rtl);
      // The RTL-specific fix: a directional icon needs to point the other
      // way, not just have its neighboring text translated.
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('the password validator message is translated too', (tester) async {
      await _pump(tester, locale: 'ar');

      await tester.enterText(find.widgetWithText(TextFormField, 'البريد الإلكتروني'), 'member@example.com');
      await tester.tap(find.text('تسجيل الدخول'));
      await tester.pumpAndSettle();

      expect(find.text('كلمة المرور مطلوبة'), findsOneWidget);
    });
  });
}
