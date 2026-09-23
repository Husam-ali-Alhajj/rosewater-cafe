import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/screens/profile/privacy_security_screen.dart';
import 'package:rosewater_cafe/services/account_deletion_service.dart';
import 'package:rosewater_cafe/services/auth_service.dart';
import 'package:rosewater_cafe/widgets/setting_toggle_row.dart';

/// Records every password change the screen asks for, and lets a test make it
/// fail the way the real one can.
class _FakeAuthService extends AuthService {
  _FakeAuthService({this.failure});

  final ChangePasswordFailure? failure;
  final List<Map<String, String>> calls = [];

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    calls.add({'current': currentPassword, 'new': newPassword});
    if (failure != null) throw failure!;
  }
}

class _FakeAccountDeletionService extends AccountDeletionService {
  _FakeAccountDeletionService({this.failure});

  final DeleteAccountFailure? failure;
  int deleteCalls = 0;

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    if (failure != null) throw failure!;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  _FakeAuthService? auth,
  _FakeAccountDeletionService? deletion,
  Future<void> Function(BuildContext)? onAccountDeleted,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: PrivacySecurityScreen(
        authService: auth ?? _FakeAuthService(),
        accountDeletionService: deletion ?? _FakeAccountDeletionService(),
        // Real default is signOutAndShowLanding, which needs a live Supabase
        // client -- tests substitute a harmless no-op unless one wants to
        // prove this step runs (see the "confirming" test below).
        onAccountDeleted: onAccountDeleted ?? (_) async {},
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

Future<void> _fill(WidgetTester tester, {String current = 'OldPass1', String next = 'NewPass2', String? confirm}) async {
  await tester.enterText(_currentField, current);
  await tester.enterText(_newField, next);
  await tester.enterText(_confirmField, confirm ?? next);
}

void main() {
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
        'Privacy',
        'View Privacy Policy',
        'Terms of Service',
        'Delete Account',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });
  });

  group('Security Options are disabled placeholders', () {
    const keys = ['placeholder-biometric', 'placeholder-two-factor', 'placeholder-auto-lock'];

    testWidgets('all three are off, disabled, and marked Coming Soon', (tester) async {
      await _pump(tester);

      expect(find.text('(Coming Soon)'), findsNWidgets(3));
      for (final key in keys) {
        final sw = tester.widget<SettingSwitch>(find.byKey(ValueKey(key)));
        expect(sw.value, isFalse, reason: key); // even Auto-Lock, which the design draws on
        expect(sw.onTap, isNull, reason: key); // no handler: cannot be flipped
      }
    });

    testWidgets('tapping one changes nothing', (tester) async {
      await _pump(tester);

      for (final key in keys) {
        await tester.tap(find.byKey(ValueKey(key)), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(tester.widget<SettingSwitch>(find.byKey(ValueKey(key))).value, isFalse, reason: key);
      }
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

  group('Delete Account is real, immediate deletion', () {
    testWidgets('confirming deletes the account, then ends the local session', (tester) async {
      final auth = _FakeAuthService();
      final deletion = _FakeAccountDeletionService();
      final log = <String>[];
      await _pump(
        tester,
        auth: auth,
        deletion: deletion,
        onAccountDeleted: (_) async => log.add('session ended'),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);

      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(deletion.deleteCalls, 1);
      expect(log, ['session ended']); // the local session was ended for real
      expect(auth.calls, isEmpty); // nothing else was touched
    });

    testWidgets('Cancel on the confirmation deletes nothing', (tester) async {
      final deletion = _FakeAccountDeletionService();
      await _pump(tester, deletion: deletion);

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deletion.deleteCalls, 0);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('a failed deletion shows a message and leaves Delete Account available', (tester) async {
      final deletion = _FakeAccountDeletionService(
        failure: const DeleteAccountFailure("Couldn't delete your account. Please try again."),
      );
      final log = <String>[];
      await _pump(tester, deletion: deletion, onAccountDeleted: (_) async => log.add('session ended'));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't delete your account. Please try again."), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget); // still tappable, not stuck disabled
      expect(log, isEmpty); // the local session was never ended -- the account is still real
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
