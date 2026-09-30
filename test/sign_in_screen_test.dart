import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/screens/auth/sign_in_screen.dart';

/// SignInScreen can't take a fake AuthService, so these tests cover what works without a backend:
/// both languages, right-to-left and the form validation.
Future<void> _pump(WidgetTester tester, {String locale = 'en'}) async {
  // A large screen size, like the other screen tests.
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
