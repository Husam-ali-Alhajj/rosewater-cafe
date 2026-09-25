import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/auth_service.dart';
import 'package:rosewater_cafe/services/biometric_service.dart';
import 'package:rosewater_cafe/widgets/app_lock_screen.dart';

/// A fake with no real `local_auth` platform channel behind it.
class _FakeBiometricService extends BiometricService {
  _FakeBiometricService({this.result = true});

  final bool result;
  int authenticateCalls = 0;

  @override
  Future<bool> authenticate({required String reason}) async {
    authenticateCalls++;
    return result;
  }
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.failure});

  final ReauthenticationFailure? failure;
  final List<String> verifyCalls = [];

  @override
  Future<void> verifyCurrentPassword(String currentPassword) async {
    verifyCalls.add(currentPassword);
    if (failure != null) throw failure!;
  }
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool biometricEnabled,
    required VoidCallback onUnlocked,
    BiometricService? biometricService,
    AuthService? authService,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppLockScreen(
          biometricEnabled: biometricEnabled,
          onUnlocked: onUnlocked,
          biometricService: biometricService ?? _FakeBiometricService(),
          authService: authService ?? _FakeAuthService(),
        ),
      ),
    );
  }

  group('Biometric enabled', () {
    testWidgets('attempts biometric automatically on first show, and unlocks on success', (tester) async {
      var unlocked = false;
      final biometrics = _FakeBiometricService(result: true);
      await pump(tester, biometricEnabled: true, onUnlocked: () => unlocked = true, biometricService: biometrics);
      await tester.pumpAndSettle();

      expect(biometrics.authenticateCalls, 1);
      expect(unlocked, isTrue);
    });

    testWidgets('a failed attempt leaves the lock screen up, with Try Again and Use Password Instead both visible', (
      tester,
    ) async {
      var unlocked = false;
      final biometrics = _FakeBiometricService(result: false);
      await pump(tester, biometricEnabled: true, onUnlocked: () => unlocked = true, biometricService: biometrics);
      await tester.pumpAndSettle();

      expect(unlocked, isFalse);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Use Password Instead'), findsOneWidget);
    });

    testWidgets('"Use Password Instead" reveals the password field, and it unlocks on the right password', (
      tester,
    ) async {
      var unlocked = false;
      final auth = _FakeAuthService();
      await pump(
        tester,
        biometricEnabled: true,
        onUnlocked: () => unlocked = true,
        biometricService: _FakeBiometricService(result: false),
        authService: auth,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use Password Instead'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'correct-password');
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(auth.verifyCalls, ['correct-password']);
      expect(unlocked, isTrue);
    });

    testWidgets('"Use Biometric Instead" switches back from the password field', (tester) async {
      await pump(
        tester,
        biometricEnabled: true,
        onUnlocked: () {},
        biometricService: _FakeBiometricService(result: false),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use Password Instead'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

      await tester.tap(find.text('Use Biometric Instead'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Password'), findsNothing);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });

  group('Biometric disabled -- password only', () {
    testWidgets('never attempts biometric, shows the password field immediately', (tester) async {
      final biometrics = _FakeBiometricService(result: true);
      await pump(tester, biometricEnabled: false, onUnlocked: () {}, biometricService: biometrics);
      await tester.pumpAndSettle();

      expect(biometrics.authenticateCalls, 0);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(find.text('Use Password Instead'), findsNothing); // already showing it -- nothing to switch to
    });

    testWidgets('an empty password is rejected before any request', (tester) async {
      final auth = _FakeAuthService();
      await pump(tester, biometricEnabled: false, onUnlocked: () {}, authService: auth);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(auth.verifyCalls, isEmpty);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('a wrong password is shown under the field, and the app stays locked', (tester) async {
      var unlocked = false;
      final auth = _FakeAuthService(failure: const ReauthenticationFailure('Current password is incorrect.'));
      await pump(tester, biometricEnabled: false, onUnlocked: () => unlocked = true, authService: auth);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(unlocked, isFalse);
      expect(find.text('Current password is incorrect.'), findsOneWidget);
    });
  });
}
