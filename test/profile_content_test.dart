import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/models/membership_plan.dart';
import 'package:rosewater_cafe/models/profile.dart';
import 'package:rosewater_cafe/screens/profile/profile_screen.dart';
import 'package:rosewater_cafe/services/subscription_service.dart';

MembershipPlan _plan(String name, {int maxGuests = 2}) => MembershipPlan(
  id: 'plan-$name',
  name: name,
  priceCents: 19900,
  hookahLimit: 20,
  drinksLimit: 20,
  maxGuests: maxGuests,
  isPopular: false,
  features: const [],
);

ActiveMembership _membership(String name, {int maxGuests = 2}) => ActiveMembership(
  plan: _plan(name, maxGuests: maxGuests),
  validUntil: DateTime.utc(2026, 2, 13, 10),
);

const _profile = Profile(
  id: 'user-1',
  fullName: 'Layla Hassan',
  email: 'layla@example.com',
  phone: '+966 55 123 4567',
  memberId: 'RC-000031',
);

class _Calls {
  final List<String> log = [];
  VoidCallback rec(String name) => () => log.add(name);
}

Future<_Calls> _pump(
  WidgetTester tester, {
  Profile? profile = _profile,
  ActiveMembership? membership,
  bool signOutEnabled = true,
}) async {
  // Tall enough that nothing needs scrolling, so taps land on-screen.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final calls = _Calls();
  await tester.pumpWidget(
    MaterialApp(
      // Sprint 8 Task 6 Phase 2: this screen now reads AppLocalizations
      // throughout (see profile_screen.dart).
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProfileContent(
          profile: profile,
          membership: membership ?? _membership('Premium'),
          onRetry: calls.rec('retry'),
          onEditProfile: calls.rec('edit'),
          onUpgradeMembership: calls.rec('upgrade'),
          onPaymentMethods: calls.rec('payment'),
          onNotifications: calls.rec('notifications'),
          onPrivacySecurity: calls.rec('privacy'),
          onHelpSupport: calls.rec('help'),
          onAppSettings: calls.rec('settings'),
          onSignOut: signOutEnabled ? calls.rec('signout') : null,
        ),
      ),
    ),
  );
  return calls;
}

void main() {
  testWidgets('shows the real profile and membership data', (tester) async {
    await _pump(tester);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Layla Hassan'), findsOneWidget);
    expect(find.text('layla@example.com'), findsOneWidget);
    expect(find.text('+966 55 123 4567'), findsOneWidget);
    expect(find.text('Member ID: RC-000031'), findsOneWidget);

    expect(find.text('Membership Details'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('Valid Until'), findsOneWidget);
    expect(find.text('2/13/2026'), findsOneWidget); // M/D/YYYY, no leading zeros
    expect(find.text('Max Guests'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('badge is built from the real plan name, not hardcoded', (tester) async {
    await _pump(tester, membership: _membership('Premium'));
    expect(find.text('PREMIUM Member'), findsOneWidget);

    await _pump(tester, membership: _membership('Basic', maxGuests: 1));
    expect(find.text('BASIC Member'), findsOneWidget);
    expect(find.text('PREMIUM Member'), findsNothing);
    expect(find.text('1'), findsOneWidget); // Max Guests follows the plan too

    await _pump(tester, membership: _membership('VIP'));
    expect(find.text('VIP Member'), findsOneWidget);
  });

  testWidgets('hides the phone / member ID rows when the profile has none', (tester) async {
    await _pump(
      tester,
      profile: const Profile(
        id: 'user-2',
        fullName: 'No Phone',
        email: 'nophone@example.com',
        phone: null,
        memberId: null,
      ),
    );

    expect(find.text('nophone@example.com'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.byIcon(Icons.credit_card_outlined), findsOneWidget); // only Settings > Payment Methods
    expect(find.textContaining('Member ID'), findsNothing);
  });

  testWidgets('shows every settings row, the version line, and both actions', (tester) async {
    await _pump(tester);

    for (final label in [
      'Settings',
      'Payment Methods',
      'Notifications',
      'Privacy & Security',
      'Help & Support',
      'App Settings',
      'Edit Profile',
      'Upgrade Membership',
      'Sign Out',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Version 1.0.0 • Rosewater Café'), findsOneWidget);
  });

  testWidgets('every row and button fires its own callback', (tester) async {
    final calls = await _pump(tester);

    for (final label in [
      'Edit Profile',
      'Upgrade Membership',
      'Payment Methods',
      'Notifications',
      'Privacy & Security',
      'Help & Support',
      'App Settings',
      'Sign Out',
    ]) {
      await tester.tap(find.text(label));
    }

    expect(calls.log, [
      'edit',
      'upgrade',
      'payment',
      'notifications',
      'privacy',
      'help',
      'settings',
      'signout',
    ]);
  });

  testWidgets('a failed profile load shows a retry, but the rest (incl. Sign Out) still works', (tester) async {
    final calls = await _pump(tester, profile: null);

    expect(find.text("Couldn't load your profile."), findsOneWidget);
    expect(find.text('Layla Hassan'), findsNothing);
    // Sections that don't depend on the profile are still there.
    expect(find.text('PREMIUM Member'), findsNothing); // badge lives in the profile card
    expect(find.text('Membership Details'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.tap(find.text('Sign Out'));
    expect(calls.log, ['retry', 'signout']);
  });

  testWidgets('Sign Out does nothing while a sign-out is already in progress', (tester) async {
    final calls = await _pump(tester, signOutEnabled: false);

    await tester.tap(find.text('Sign Out'));
    expect(calls.log, isEmpty);
  });
}
