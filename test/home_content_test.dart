import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/models/membership_plan.dart';
import 'package:rosewater_cafe/models/profile.dart';
import 'package:rosewater_cafe/models/usage_allowance.dart';
import 'package:rosewater_cafe/screens/home/home_screen.dart';
import 'package:rosewater_cafe/services/subscription_service.dart';

MembershipPlan _plan(String name, {int? hookah = 20, int? drinks = 20, int maxGuests = 2}) => MembershipPlan(
  id: 'plan-$name',
  name: name,
  priceCents: 19900,
  hookahLimit: hookah,
  drinksLimit: drinks,
  maxGuests: maxGuests,
  isPopular: false,
  features: const ['Priority seating', 'Weekend access', 'Member discounts'],
);

ActiveMembership _membership(MembershipPlan plan) =>
    ActiveMembership(plan: plan, validUntil: DateTime.utc(2026, 2, 13, 10));

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
  MembershipPlan? plan,
  UsageAllowance usage = const UsageAllowance(hookahUsed: 15, drinksUsed: 18),
  DateTime? now,
  bool logoutEnabled = true,
  Size size = const Size(800, 3000),
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final calls = _Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: HomeContent(
          profile: profile,
          membership: _membership(plan ?? _plan('Premium')),
          usage: usage,
          now: now ?? DateTime(2026, 9, 20, 14),
          onGoToQrCode: calls.rec('qr'),
          onGoToEvents: calls.rec('events'),
          onNotifications: calls.rec('notifications'),
          onLogout: logoutEnabled ? calls.rec('logout') : null,
        ),
      ),
    ),
  );
  return calls;
}

/// Loads Roboto from the Flutter SDK so text has real widths (the default
/// test font makes every glyph a full-width square, so everything wraps).
/// Returns false if the SDK's font files can't be found.
Future<bool> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return false;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf']) {
    final file = File('$dir/$f');
    if (!file.existsSync()) return false;
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
  return true;
}

Rect _rect(WidgetTester tester, String type, [int i = 0]) =>
    tester.getRect(find.byWidgetPredicate((w) => w.runtimeType.toString() == type).at(i));

void main() {
  testWidgets('header greets the member by first name with their real member ID', (tester) async {
    await _pump(tester);

    expect(find.text('Welcome, Layla!'), findsOneWidget);
    expect(find.text('Member ID: RC-000031'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    // No unread badge -- notifications aren't built yet (decision #32).
    expect(find.text('2'), findsNothing);
  });

  testWidgets('greeting and member ID degrade without placeholders', (tester) async {
    await _pump(tester, profile: null);
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.textContaining('Member ID'), findsNothing);
    expect(find.textContaining('Demo'), findsNothing);

    await _pump(
      tester,
      profile: const Profile(id: 'u', fullName: '   ', email: 'a@b.co', phone: null, memberId: null),
    );
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.textContaining('Member ID'), findsNothing);
  });

  testWidgets('first name is the first word of the full name', (tester) async {
    await _pump(
      tester,
      profile: const Profile(id: 'u', fullName: '  Mary   Jane Watson ', email: 'a@b.co', phone: null, memberId: 'RC-000001'),
    );
    expect(find.text('Welcome, Mary!'), findsOneWidget);
  });

  testWidgets('status card shows the real plan, Active badge and valid-until', (tester) async {
    await _pump(tester, plan: _plan('Basic'));

    expect(find.text('Membership Status'), findsOneWidget);
    expect(find.text('Basic Member'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Valid until: 2/13/2026'), findsOneWidget);
  });

  testWidgets('usage cards show real used / limit, or Unlimited with no bar', (tester) async {
    await _pump(tester);
    expect(find.text('Hookah Sessions'), findsOneWidget);
    expect(find.text('15 / 20'), findsOneWidget);
    expect(find.text('15 used this month'), findsOneWidget);
    expect(find.text('Drinks'), findsOneWidget);
    expect(find.text('18 / 20'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));

    // VIP: limits are null -> "Unlimited", no bar, caption still shown.
    await _pump(tester, plan: _plan('VIP', hookah: null, drinks: null));
    expect(find.text('Unlimited'), findsNWidgets(2));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('15 used this month'), findsOneWidget);
    expect(find.text('18 used this month'), findsOneWidget);
  });

  testWidgets('progress bar fraction is used / limit', (tester) async {
    await _pump(tester, usage: const UsageAllowance(hookahUsed: 5, drinksUsed: 20));
    final bars = tester.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).toList();
    expect(bars[0].value, 0.25);
    expect(bars[1].value, 1.0);
  });

  testWidgets('service-hours status follows the clock', (tester) async {
    await _pump(tester, now: DateTime(2026, 9, 20, 14));
    expect(find.textContaining('Full service available', findRichText: true), findsOneWidget);

    await _pump(tester, now: DateTime(2026, 9, 20, 23, 30));
    expect(find.textContaining('Self-service hours', findRichText: true), findsWidgets);
    expect(find.textContaining('Full service available', findRichText: true), findsNothing);
  });

  testWidgets('benefits list is the plan\'s own featureBullets', (tester) async {
    final plan = _plan('Premium');
    await _pump(tester, plan: plan);

    expect(find.text('Membership Benefits'), findsOneWidget);
    for (final bullet in plan.featureBullets) {
      expect(find.text('• $bullet'), findsOneWidget, reason: bullet);
    }
  });

  testWidgets('quick actions, bell and Logout fire their own callbacks', (tester) async {
    final calls = await _pump(tester);

    await tester.tap(find.text('Access Café'));
    await tester.tap(find.text('Reserve Event'));
    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.tap(find.text('Logout'));

    expect(calls.log, ['qr', 'events', 'notifications', 'logout']);
  });

  testWidgets('Logout does nothing while a sign-out is already in progress', (tester) async {
    final calls = await _pump(tester, logoutEnabled: false);

    await tester.tap(find.text('Logout'));
    expect(calls.log, isEmpty);
  });

  testWidgets('layout follows the Figma frame (spacing and card heights at 374.98 wide)', (tester) async {
    if (!await _loadRoboto()) {
      markTestSkipped('Flutter SDK Roboto fonts not found (FLUTTER_ROOT unset?)');
      return;
    }
    await _pump(
      tester,
      profile: const Profile(id: 'u', fullName: 'Demo User', email: 'd@e.co', phone: null, memberId: '1768390004573'),
      size: const Size(374.98, 3000),
      theme: ThemeData(fontFamily: 'Roboto'),
    );
    await tester.pump();

    final status = _rect(tester, '_MembershipStatusCard');
    final quick0 = _rect(tester, '_QuickActionButton', 0);
    final quick1 = _rect(tester, '_QuickActionButton', 1);
    final usage0 = _rect(tester, '_UsageCard', 0);
    final usage1 = _rect(tester, '_UsageCard', 1);
    final service = _rect(tester, '_ServiceHoursCard');
    final benefits = _rect(tester, '_BenefitsCard');
    final header = _rect(tester, '_HomeHeader');

    double close(double v) => double.parse(v.toStringAsFixed(2));

    expect(header.top, 32); // frame top padding
    expect(close(status.top - header.bottom), 32); // header -> status card
    expect(close(status.height), 169.03); // Figma 342.98 x 169.03
    expect(close(status.width), 342.98);
    expect(close(quick0.top - status.bottom), 24);
    expect(quick0.height, 96);
    expect(close(quick1.top - quick0.bottom), 16); // gap between the two buttons
    expect(quick1.height, 96);
    expect(close(usage0.top - quick1.bottom), 24);
    expect(close(usage0.height), 197.03); // Figma usage card
    expect(close(usage1.top - usage0.bottom), 24);
    expect(close(usage1.height), 197.03);
    expect(close(service.top - usage1.bottom), 24);
    expect(close(benefits.top - service.bottom), 24);
    // 24 + 28 (title) + 40 + 6 bullets (20 each, 8 apart) + 24 + hairline border
    expect(close(benefits.height), 277.03);
  });
}
