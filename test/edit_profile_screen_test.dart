import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/models/membership_plan.dart';
import 'package:rosewater_cafe/models/profile.dart';
import 'package:rosewater_cafe/screens/profile/edit_profile_screen.dart';
import 'package:rosewater_cafe/services/profile_service.dart';
import 'package:rosewater_cafe/services/subscription_service.dart';

const _profile = Profile(
  id: 'user-1',
  fullName: 'Layla Hassan',
  email: 'layla@example.com',
  phone: '+966 55 123 4567',
  memberId: 'RC-000031',
);

final _membership = ActiveMembership(
  plan: const MembershipPlan(
    id: 'p',
    name: 'Premium',
    priceCents: 19900,
    hookahLimit: 20,
    drinksLimit: 20,
    maxGuests: 2,
    isPopular: true,
    features: [],
  ),
  validUntil: DateTime.utc(2026, 2, 13),
);

/// Stands in for the real service so the screen can be tested with no
/// Supabase connection -- and so a test can prove the screen did (or, for an
/// invalid form, did NOT) call it at all.
class _FakeProfileService extends ProfileService {
  _FakeProfileService({this.failure});

  final Object? failure;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<Profile> updateProfile({
    required String fullName,
    required String phone,
    String? avatarPath,
  }) async {
    calls.add({'fullName': fullName, 'phone': phone, 'avatarPath': avatarPath});
    final f = failure;
    if (f != null) throw f;
    return Profile(
      id: _profile.id,
      fullName: fullName,
      email: _profile.email,
      phone: phone,
      memberId: _profile.memberId,
    );
  }
}

class _Result {
  Profile? popped;
  bool didPop = false;
}

/// Opens Edit Profile from a host screen (as Profile does) so a test can see
/// what it pops with.
Future<_Result> _open(WidgetTester tester, _FakeProfileService service) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final result = _Result();
  await tester.pumpWidget(
    MaterialApp(
      // Sprint 8 Task 6 Phase 2: this screen now reads AppLocalizations
      // throughout (see edit_profile_screen.dart).
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result.popped = await Navigator.of(context).push<Profile>(
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(profile: _profile, membership: _membership, profileService: service),
                ),
              );
              result.didPop = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

Finder get _nameField => find.byType(TextFormField).at(0);
Finder get _phoneField => find.byType(TextFormField).at(1);

void main() {
  testWidgets('shows the real values, with email as read-only text (not a field)', (tester) async {
    await _open(tester, _FakeProfileService());

    expect(find.text('Edit Profile'), findsOneWidget);
    // Exactly two inputs -- name and phone. Email is NOT a text field.
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Layla Hassan'), findsOneWidget);
    expect(find.text('+966 55 123 4567'), findsOneWidget);
    expect(find.text('layla@example.com'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text("Your email can't be changed in the app."), findsOneWidget);

    expect(find.text('Member ID'), findsOneWidget);
    expect(find.text('RC-000031'), findsOneWidget);
    expect(find.text('Subscription Type'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('Contact support to change membership type'), findsOneWidget);
    expect(find.text('Tap camera icon to change photo'), findsOneWidget);
  });

  testWidgets('tapping the email does not open an editor or take input', (tester) async {
    await _open(tester, _FakeProfileService());

    await tester.tap(find.text('layla@example.com'));
    await tester.pump();

    // Nothing is focused, and there's no field to type into.
    expect(FocusManager.instance.primaryFocus?.context?.widget is EditableText, isFalse);
    expect(find.byType(EditableText), findsNWidgets(2)); // still just name + phone
  });

  testWidgets('an invalid phone is rejected client-side, before any network call', (tester) async {
    final service = _FakeProfileService();
    final result = await _open(tester, service);

    await tester.enterText(_phoneField, '5551234567'); // no country code
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Include your country code, e.g. +1 or +966'), findsOneWidget);
    expect(service.calls, isEmpty); // the service was never reached
    expect(result.didPop, isFalse); // and we're still on Edit Profile
  });

  testWidgets('rejects each invalid-phone shape from decision #10 without calling the service', (tester) async {
    final service = _FakeProfileService();
    await _open(tester, service);

    final cases = {
      '': 'Phone number is required',
      '+1555abc4567': 'Enter a valid phone number',
      '+1234567': 'Enter a valid phone number with country code', // 7 digits
      '+1234567890123456': 'Enter a valid phone number with country code', // 16 digits
    };
    for (final entry in cases.entries) {
      await tester.enterText(_phoneField, entry.key);
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: 'phone "${entry.key}"');
    }
    expect(service.calls, isEmpty);
  });

  testWidgets('a blank name is rejected client-side', (tester) async {
    final service = _FakeProfileService();
    await _open(tester, service);

    await tester.enterText(_nameField, '   ');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(service.calls, isEmpty);
  });

  testWidgets('saving valid changes sends only name/phone (trimmed) and returns the saved profile', (tester) async {
    final service = _FakeProfileService();
    final result = await _open(tester, service);

    await tester.enterText(_nameField, '  Layla H. Hassan ');
    await tester.enterText(_phoneField, ' +1 (555) 123-4567 ');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(service.calls, [
      {'fullName': 'Layla H. Hassan', 'phone': '+1 (555) 123-4567', 'avatarPath': null},
    ]);
    expect(result.didPop, isTrue);
    expect(result.popped?.fullName, 'Layla H. Hassan');
    expect(result.popped?.phone, '+1 (555) 123-4567');
    // Email is never sent, and comes back unchanged.
    expect(result.popped?.email, 'layla@example.com');
  });

  testWidgets('saving with nothing changed skips the network and pops with null', (tester) async {
    final service = _FakeProfileService();
    final result = await _open(tester, service);

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(service.calls, isEmpty);
    expect(result.didPop, isTrue);
    expect(result.popped, isNull);
  });

  testWidgets('a failed save shows the message and stays on the screen', (tester) async {
    final service = _FakeProfileService(failure: const ProfileUpdateFailure("Couldn't save your changes. Please try again."));
    final result = await _open(tester, service);

    await tester.enterText(_nameField, 'New Name');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't save your changes. Please try again."), findsOneWidget);
    expect(result.didPop, isFalse);
    // The button is usable again.
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('an unexpected error becomes a friendly message, not a crash', (tester) async {
    final service = _FakeProfileService(failure: StateError('boom'));
    await _open(tester, service);

    await tester.enterText(_nameField, 'New Name');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't save your changes"), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
  });

  testWidgets('Cancel discards edits and pops with null', (tester) async {
    final service = _FakeProfileService();
    final result = await _open(tester, service);

    await tester.enterText(_nameField, 'Something Else');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(service.calls, isEmpty);
    expect(result.didPop, isTrue);
    expect(result.popped, isNull);
  });

  testWidgets('the back arrow pops without saving', (tester) async {
    final service = _FakeProfileService();
    final result = await _open(tester, service);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(service.calls, isEmpty);
    expect(result.didPop, isTrue);
    expect(result.popped, isNull);
  });
}
