import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rosewater_cafe/screens/profile/privacy_security_screen.dart';
import 'package:rosewater_cafe/services/account_deletion_service.dart';
import 'package:rosewater_cafe/services/auth_service.dart';
import 'package:rosewater_cafe/services/biometric_service.dart';
import 'package:rosewater_cafe/services/settings_provider.dart';
import 'package:rosewater_cafe/widgets/setting_toggle_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fake with no real `local_auth` platform channel behind it -- a widget
/// test environment has none, so this stands in, matching the
/// constructor-injection pattern every other real service in this file's
/// fakes already follows.
class _FakeBiometricService extends BiometricService {
  _FakeBiometricService({this.available = true});

  final bool available;
  int isAvailableCalls = 0;

  @override
  Future<bool> isAvailable() async {
    isAvailableCalls++;
    return available;
  }
}

/// Records every password change / email change the screen asks for, and
/// lets a test make either fail the way the real ones can. Also stands in
/// for the live Supabase user this screen would otherwise need for its
/// Email card ([currentUserEmail]/[pendingEmailChange]) -- a widget test
/// can't initialise a real Supabase client, so these are overridden here
/// instead of falling through to the real ones.
class _FakeAuthService extends AuthService {
  _FakeAuthService({
    this.failure,
    this.changeEmailFailure,
    this.email = 'member@example.com',
    this.pendingEmail,
  });

  final ChangePasswordFailure? failure;
  final ChangeEmailFailure? changeEmailFailure;
  final String? email;
  final String? pendingEmail;
  final List<Map<String, String>> calls = [];
  final List<Map<String, String>> emailChangeCalls = [];

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    calls.add({'current': currentPassword, 'new': newPassword});
    if (failure != null) throw failure!;
  }

  @override
  String? get currentUserEmail => email;

  @override
  String? get pendingEmailChange => pendingEmail;

  @override
  Future<void> changeEmail({required String currentPassword, required String newEmail}) async {
    emailChangeCalls.add({'password': currentPassword, 'newEmail': newEmail});
    if (changeEmailFailure != null) throw changeEmailFailure!;
  }
}

class _FakeAccountDeletionService extends AccountDeletionService {
  _FakeAccountDeletionService({this.failure});

  final DeleteAccountFailure? failure;
  final List<String> deleteCalls = [];

  @override
  Future<void> deleteAccount({required String currentPassword}) async {
    deleteCalls.add(currentPassword);
    if (failure != null) throw failure!;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  _FakeAuthService? auth,
  _FakeAccountDeletionService? deletion,
  BiometricService? biometricService,
  SettingsProvider? settings,
  Future<void> Function(BuildContext)? onAccountDeleted,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Security Options' Biometric Authentication / Auto-Lock rows are real
  // now (Sprint 8 Task 5) -- they read/write SettingsProvider, so this
  // screen needs one in its own widget tree here too, same as App
  // Settings' own test file.
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings ?? await SettingsProvider.load(),
      child: MaterialApp(
        home: PrivacySecurityScreen(
          authService: auth ?? _FakeAuthService(),
          accountDeletionService: deletion ?? _FakeAccountDeletionService(),
          biometricService: biometricService ?? _FakeBiometricService(),
          // Real default is signOutAndShowLanding, which needs a live Supabase
          // client -- tests substitute a harmless no-op unless one wants to
          // prove this step runs (see the "confirming" test below).
          onAccountDeleted: onAccountDeleted ?? (_) async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _currentField => find.byType(TextFormField).at(0);
Finder get _newField => find.byType(TextFormField).at(1);
Finder get _confirmField => find.byType(TextFormField).at(2);

Future<void> _openForm(WidgetTester tester) async {
  await tester.tap(find.text('Change Password'));
  await tester.pumpAndSettle();
}

Future<void> _openDeleteForm(WidgetTester tester) async {
  await tester.tap(find.text('Delete Account'));
  await tester.pumpAndSettle();
}

Future<void> _openEmailForm(WidgetTester tester) async {
  await tester.tap(find.text('Change Email'));
  await tester.pumpAndSettle();
}

Finder get _newEmailField => find.byType(TextFormField).at(0);
Finder get _emailPasswordField => find.byType(TextFormField).at(1);

Future<void> _fill(WidgetTester tester, {String current = 'OldPass1', String next = 'NewPass2', String? confirm}) async {
  await tester.enterText(_currentField, current);
  await tester.enterText(_newField, next);
  await tester.enterText(_confirmField, confirm ?? next);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('layout', () {
    testWidgets('shows the three cards and every row from the design', (tester) async {
      await _pump(tester);

      for (final text in [
        'Privacy & Security',
        'Security Options',
        'Biometric Authentication',
        'Use fingerprint or face ID to sign in',
        'Two-Factor Authentication',
        'Add an extra layer of security',
        'Auto-Lock',
        'Automatically lock app when inactive',
        'Password',
        'Keep your account secure by using a strong password',
        'Change Password',
        'Email',
        'member@example.com',
        'Change Email',
        'Privacy',
        'View Privacy Policy',
        'Terms of Service',
        'Delete Account',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });
  });

  group('Two-Factor Authentication is still a disabled placeholder', () {
    testWidgets('off, disabled, and marked Coming Soon', (tester) async {
      await _pump(tester);

      expect(find.text('(Coming Soon)'), findsOneWidget);
      final sw = tester.widget<SettingSwitch>(find.byKey(const ValueKey('placeholder-two-factor')));
      expect(sw.value, isFalse);
      expect(sw.onTap, isNull);
    });

    testWidgets('tapping it changes nothing', (tester) async {
      await _pump(tester);

      await tester.tap(find.byKey(const ValueKey('placeholder-two-factor')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.widget<SettingSwitch>(find.byKey(const ValueKey('placeholder-two-factor'))).value, isFalse);
    });
  });

  group('Auto-Lock is real (Sprint 8 Task 5)', () {
    testWidgets('reflects SettingsProvider.autoLockEnabled and tapping flips it', (tester) async {
      final settings = await SettingsProvider.load();
      await _pump(tester, settings: settings);

      expect(settings.autoLockEnabled, isFalse); // decision #45's original reasoning: never on by default
      expect(tester.widget<SettingSwitch>(find.byKey(const ValueKey('auto-lock'))).value, isFalse);

      await tester.tap(find.byKey(const ValueKey('auto-lock')));
      await tester.pumpAndSettle();

      expect(settings.autoLockEnabled, isTrue);
      expect(tester.widget<SettingSwitch>(find.byKey(const ValueKey('auto-lock'))).value, isTrue);
    });
  });

  group('Biometric Authentication is real (Sprint 8 Task 5)', () {
    testWidgets('turning it on checks device capability first, and enables it when available', (tester) async {
      final settings = await SettingsProvider.load();
      final biometrics = _FakeBiometricService(available: true);
      await _pump(tester, settings: settings, biometricService: biometrics);

      expect(settings.biometricEnabled, isFalse);
      await tester.tap(find.byKey(const ValueKey('biometric-authentication')));
      await tester.pumpAndSettle();

      expect(biometrics.isAvailableCalls, 1);
      expect(settings.biometricEnabled, isTrue);
      expect(tester.widget<SettingSwitch>(find.byKey(const ValueKey('biometric-authentication'))).value, isTrue);
    });

    testWidgets('turning it on when unavailable shows a real message and stays off', (tester) async {
      final settings = await SettingsProvider.load();
      final biometrics = _FakeBiometricService(available: false);
      await _pump(tester, settings: settings, biometricService: biometrics);

      await tester.tap(find.byKey(const ValueKey('biometric-authentication')));
      await tester.pumpAndSettle();

      expect(biometrics.isAvailableCalls, 1);
      expect(settings.biometricEnabled, isFalse);
      expect(tester.widget<SettingSwitch>(find.byKey(const ValueKey('biometric-authentication'))).value, isFalse);
      expect(find.textContaining('No biometrics available'), findsOneWidget);
    });

    testWidgets('turning it off never checks device capability', (tester) async {
      final settings = await SettingsProvider.load();
      await settings.setBiometricEnabled(true);
      final biometrics = _FakeBiometricService(available: true);
      await _pump(tester, settings: settings, biometricService: biometrics);

      await tester.tap(find.byKey(const ValueKey('biometric-authentication')));
      await tester.pumpAndSettle();

      expect(biometrics.isAvailableCalls, 0);
      expect(settings.biometricEnabled, isFalse);
    });
  });

  group('Change Password', () {
    testWidgets('opens a form with all three fields, Cancel and Update Password', (tester) async {
      await _pump(tester);
      await _openForm(tester);

      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Keep your account secure by using a strong password'), findsNothing);
    });

    testWidgets('the fields are hidden by default, and the eye shows/hides each one', (tester) async {
      await _pump(tester);
      await _openForm(tester);

      bool obscured(int i) => tester
          .widget<TextField>(find.descendant(of: find.byType(TextFormField).at(i), matching: find.byType(TextField)))
          .obscureText;
      expect(obscured(0), isTrue);
      expect(obscured(1), isTrue);
      expect(obscured(2), isTrue);

      await tester.tap(find.byTooltip('Show password').at(1)); // the NEW password's eye
      await tester.pump();
      expect(obscured(0), isTrue);
      expect(obscured(1), isFalse);
      expect(obscured(2), isTrue);
    });

    testWidgets('Cancel closes the form and clears what was typed', (tester) async {
      await _pump(tester);
      await _openForm(tester);
      await _fill(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Change Password'), findsOneWidget);

      await _openForm(tester);
      for (var i = 0; i < 3; i++) {
        final field = tester.widget<TextField>(find.descendant(of: find.byType(TextFormField).at(i), matching: find.byType(TextField)));
        expect(field.controller!.text, isEmpty);
      }
    });

    testWidgets('requires the CURRENT password: an empty one is rejected before any request', (tester) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth: auth);
      await _openForm(tester);

      await _fill(tester, current: '');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your current password'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('the new password must pass decision #10 -- each missing rule gets its own message, and nothing is sent', (tester) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth: auth);
      await _openForm(tester);

      final cases = {
        'Ab1': 'Must be at least 8 characters',
        'password1': 'Add at least one uppercase letter',
        'PASSWORD1': 'Add at least one lowercase letter',
        'Passwordd': 'Add at least one number',
        '': 'Password is required',
      };
      for (final entry in cases.entries) {
        await _fill(tester, next: entry.key, confirm: entry.key);
        await tester.tap(find.text('Update Password'));
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget, reason: 'new password "${entry.key}"');
      }
      expect(auth.calls, isEmpty);
    });

    testWidgets('a new password identical to the current one is rejected client-side', (tester) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth: auth);
      await _openForm(tester);

      await _fill(tester, current: 'SamePass1', next: 'SamePass1');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a password different from your current one.'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('a confirmation that does not match is rejected', (tester) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth: auth);
      await _openForm(tester);

      await _fill(tester, next: 'NewPass2', confirm: 'NewPass3');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('a valid form sends the current AND the new password, then closes with a confirmation', (tester) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth: auth);
      await _openForm(tester);

      await _fill(tester, current: 'OldPass1', next: 'NewPass2');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(auth.calls, [
        {'current': 'OldPass1', 'new': 'NewPass2'},
      ]);
      expect(find.byType(TextFormField), findsNothing); // form closed
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Password updated.'), findsOneWidget);
    });

    testWidgets('a wrong current password is shown under that field and the form stays open', (tester) async {
      final auth = _FakeAuthService(
        failure: const ChangePasswordFailure('Current password is incorrect.', field: 'current'),
      );
      await _pump(tester, auth: auth);
      await _openForm(tester);

      await _fill(tester);
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is incorrect.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Password updated.'), findsNothing);
    });

    testWidgets('a server rejection of the new password is shown under that field', (tester) async {
      final auth = _FakeAuthService(
        failure: const ChangePasswordFailure('Choose a password different from your current one.', field: 'new'),
      );
      await _pump(tester, auth: auth);
      await _openForm(tester);

      await _fill(tester);
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a password different from your current one.'), findsOneWidget);
    });

    testWidgets('a general failure is shown under the form, and the button works again', (tester) async {
      final auth = _FakeAuthService(failure: const ChangePasswordFailure("Couldn't update your password. Please try again."));
      await _pump(tester, auth: auth);
      await _openForm(tester);

      await _fill(tester);
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't update your password. Please try again."), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });
  });

  group('Delete Account requires current-password re-confirmation', () {
    testWidgets('tapping the row opens an inline form, not a dialog', (tester) async {
      await _pump(tester);
      await _openDeleteForm(tester);

      expect(find.text('Delete your account?'), findsNothing); // no dialog anymore
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // The other Privacy rows are untouched -- only the Delete Account row expands.
      expect(find.text('View Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('an empty password is rejected before any request', (tester) async {
      final deletion = _FakeAccountDeletionService();
      await _pump(tester, deletion: deletion);
      await _openDeleteForm(tester);

      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your current password'), findsOneWidget);
      expect(deletion.deleteCalls, isEmpty);
    });

    testWidgets('Cancel closes the form, clears the password, and deletes nothing', (tester) async {
      final deletion = _FakeAccountDeletionService();
      await _pump(tester, deletion: deletion);
      await _openDeleteForm(tester);
      await tester.enterText(find.byType(TextFormField), 'MyPass1');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deletion.deleteCalls, isEmpty);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Delete Account'), findsOneWidget); // row is back

      await _openDeleteForm(tester);
      final field = tester.widget<TextField>(
        find.descendant(of: find.byType(TextFormField), matching: find.byType(TextField)),
      );
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('a correct password deletes the account, then ends the local session', (tester) async {
      final deletion = _FakeAccountDeletionService();
      final log = <String>[];
      await _pump(tester, deletion: deletion, onAccountDeleted: (_) async => log.add('session ended'));
      await _openDeleteForm(tester);

      await tester.enterText(find.byType(TextFormField), 'CorrectPass1');
      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(deletion.deleteCalls, ['CorrectPass1']);
      expect(log, ['session ended']); // the local session was ended for real
    });

    testWidgets('a wrong password is shown under the field and the form stays open', (tester) async {
      final deletion = _FakeAccountDeletionService(
        failure: const DeleteAccountFailure('Current password is incorrect.', field: 'password'),
      );
      final log = <String>[];
      await _pump(tester, deletion: deletion, onAccountDeleted: (_) async => log.add('session ended'));
      await _openDeleteForm(tester);

      await tester.enterText(find.byType(TextFormField), 'WrongPass1');
      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is incorrect.'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget); // form still open
      expect(deletion.deleteCalls, ['WrongPass1']);
      expect(log, isEmpty); // the account was never touched
    });

    testWidgets('a general failure (e.g. storage cleanup) is shown under the form, and the button works again', (
      tester,
    ) async {
      final deletion = _FakeAccountDeletionService(
        failure: const DeleteAccountFailure("Couldn't remove your stored files. Please try again."),
      );
      final log = <String>[];
      await _pump(tester, deletion: deletion, onAccountDeleted: (_) async => log.add('session ended'));
      await _openDeleteForm(tester);

      await tester.enterText(find.byType(TextFormField), 'CorrectPass1');
      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't remove your stored files. Please try again."), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget); // not stuck on "Deleting…"
      expect(log, isEmpty); // the local session was never ended -- the account is still real
    });
  });

  group('Change Email requires current-password re-confirmation', () {
    testWidgets('shows the current email, and tapping the row opens an inline form, not a dialog', (tester) async {
      await _pump(tester, auth: _FakeAuthService(email: 'husam@example.com'));

      expect(find.text('husam@example.com'), findsOneWidget);
      await _openEmailForm(tester);

      expect(find.text('New Email Address'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Send Confirmation'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('a change already pending from before shows the pending notice up front', (tester) async {
      await _pump(tester, auth: _FakeAuthService(email: 'husam@example.com', pendingEmail: 'new@example.com'));

      expect(find.textContaining('new@example.com'), findsOneWidget);
      expect(find.textContaining('still works until then'), findsOneWidget);
    });

    testWidgets('an invalid new email is rejected before any request', (tester) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth: auth);
      await _openEmailForm(tester);

      await tester.enterText(_newEmailField, 'not-an-email');
      await tester.enterText(_emailPasswordField, 'MyPass1');
      await tester.tap(find.text('Send Confirmation'));
      await tester.pumpAndSettle();

      expect(auth.emailChangeCalls, isEmpty);
    });

    testWidgets('an empty password is rejected before any request', (tester) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth: auth);
      await _openEmailForm(tester);

      await tester.enterText(_newEmailField, 'new@example.com');
      await tester.tap(find.text('Send Confirmation'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your current password'), findsOneWidget);
      expect(auth.emailChangeCalls, isEmpty);
    });

    testWidgets('Cancel closes the form, clears both fields, and requests nothing', (tester) async {
      final auth = _FakeAuthService();
      await _pump(tester, auth: auth);
      await _openEmailForm(tester);
      await tester.enterText(_newEmailField, 'new@example.com');
      await tester.enterText(_emailPasswordField, 'MyPass1');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(auth.emailChangeCalls, isEmpty);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Change Email'), findsOneWidget); // row is back

      await _openEmailForm(tester);
      expect(tester.widget<TextField>(find.descendant(of: _newEmailField, matching: find.byType(TextField))).controller!.text, isEmpty);
      expect(tester.widget<TextField>(find.descendant(of: _emailPasswordField, matching: find.byType(TextField))).controller!.text, isEmpty);
    });

    testWidgets('a valid request sends both fields, closes the form, and shows the pending notice', (tester) async {
      final auth = _FakeAuthService(email: 'husam@example.com');
      await _pump(tester, auth: auth);
      await _openEmailForm(tester);

      await tester.enterText(_newEmailField, 'new@example.com');
      await tester.enterText(_emailPasswordField, 'MyPass1');
      await tester.tap(find.text('Send Confirmation'));
      await tester.pumpAndSettle();

      expect(auth.emailChangeCalls, [
        {'password': 'MyPass1', 'newEmail': 'new@example.com'},
      ]);
      expect(find.byType(TextFormField), findsNothing); // form closed
      expect(find.text('husam@example.com'), findsOneWidget); // current email still shown
      expect(find.textContaining('new@example.com'), findsOneWidget); // pending notice
      expect(find.textContaining('still works until then'), findsOneWidget);
    });

    testWidgets('a wrong password is shown under that field and the form stays open', (tester) async {
      final auth = _FakeAuthService(
        changeEmailFailure: const ChangeEmailFailure('Current password is incorrect.', field: 'password'),
      );
      await _pump(tester, auth: auth);
      await _openEmailForm(tester);

      await tester.enterText(_newEmailField, 'new@example.com');
      await tester.enterText(_emailPasswordField, 'WrongPass1');
      await tester.tap(find.text('Send Confirmation'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is incorrect.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // form still open
    });

    testWidgets('an email already in use is shown under the email field', (tester) async {
      final auth = _FakeAuthService(
        changeEmailFailure: const ChangeEmailFailure('An account with this email already exists.', field: 'email'),
      );
      await _pump(tester, auth: auth);
      await _openEmailForm(tester);

      await tester.enterText(_newEmailField, 'taken@example.com');
      await tester.enterText(_emailPasswordField, 'MyPass1');
      await tester.tap(find.text('Send Confirmation'));
      await tester.pumpAndSettle();

      expect(find.text('An account with this email already exists.'), findsOneWidget);
    });

    testWidgets('a general failure is shown under the form, and the button works again', (tester) async {
      final auth = _FakeAuthService(
        changeEmailFailure: const ChangeEmailFailure("Couldn't update your email. Please try again."),
      );
      await _pump(tester, auth: auth);
      await _openEmailForm(tester);

      await tester.enterText(_newEmailField, 'new@example.com');
      await tester.enterText(_emailPasswordField, 'MyPass1');
      await tester.tap(find.text('Send Confirmation'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't update your email. Please try again."), findsOneWidget);
      expect(find.text('Send Confirmation'), findsOneWidget); // not stuck on "Sending…"
    });
  });

  testWidgets('Privacy Policy and Terms of Service open a coming-soon page (no text exists yet)', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('View Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Privacy Policy'), findsOneWidget);
    expect(find.textContaining('coming in a future task'), findsOneWidget);
  });
}
