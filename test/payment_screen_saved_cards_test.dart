import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/models/membership_plan.dart';
import 'package:rosewater_cafe/models/payment_method.dart';
import 'package:rosewater_cafe/screens/membership/payment_screen.dart';
import 'package:rosewater_cafe/screens/membership/payment_success_screen.dart';
import 'package:rosewater_cafe/services/payment_method_service.dart';
import 'package:rosewater_cafe/services/subscription_service.dart';

const _vip = MembershipPlan(
  id: 'plan-vip',
  name: 'VIP',
  priceCents: 39900,
  hookahLimit: null,
  drinksLimit: null,
  maxGuests: 2,
  isPopular: false,
  features: [],
);

PaymentMethod _card(String id, String last4, {bool isDefault = false, int expYear = 2030, int expMonth = 12}) =>
    PaymentMethod(id: id, brand: 'Visa', last4: last4, expMonth: expMonth, expYear: expYear, isDefault: isDefault);

/// Records every call so each test can assert the order of events.
final _log = <String>[];

class _FakeCards extends PaymentMethodService {
  final List<PaymentMethod> cards;
  const _FakeCards(this.cards);

  @override
  Future<List<PaymentMethod>> list() async => cards;

  @override
  Future<PaymentMethod> add({
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
    bool makeDefault = false,
  }) async {
    _log.add('save:$brand/$last4/$expMonth/$expYear');
    return _card('new', last4);
  }
}

class _FakeSubscriptions extends SubscriptionService {
  final bool fail;
  const _FakeSubscriptions({this.fail = false});

  @override
  Future<DateTime> upgradeSubscription(String newPlanId) async {
    _log.add('upgrade:$newPlanId');
    if (fail) throw const UpgradeSubscriptionFailure('You can only upgrade to a higher-priced plan.');
    return DateTime(2026, 10, 28);
  }
}

Future<void> _pump(WidgetTester tester, List<PaymentMethod> cards, {bool failPayment = false}) async {
  _log.clear();
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PaymentScreen.upgrade(
        plan: _vip,
        paymentMethodService: _FakeCards(cards),
        subscriptionService: _FakeSubscriptions(fail: failPayment),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _cardNumberField => find.text('1234 5678 9012 3456'); // the card-number hint
Future<void> _tapPay(WidgetTester tester) async {
  await tester.tap(find.text(r'Pay $399'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no saved cards: the plain card form, exactly as before', (tester) async {
    await _pump(tester, const []);
    expect(find.text('Pay with'), findsNothing);
    expect(_cardNumberField, findsOneWidget);
    expect(find.text('Save this card for next time'), findsOneWidget);
  });

  testWidgets('saved cards are listed, default preselected, no card form to fill', (tester) async {
    await _pump(tester, [_card('c1', '4242', isDefault: true), _card('c2', '8888')]);
    expect(find.text('Pay with'), findsOneWidget);
    expect(find.text('Visa •••• 4242'), findsOneWidget);
    expect(find.text('Visa •••• 8888'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(_cardNumberField, findsNothing); // default is selected -> nothing to type
  });

  testWidgets('paying with a saved card goes straight through, saving nothing', (tester) async {
    await _pump(tester, [_card('c1', '4242', isDefault: true)]);
    await _tapPay(tester);
    expect(_log, ['upgrade:plan-vip']);
    expect(find.byType(PaymentSuccessScreen), findsOneWidget);
  });

  testWidgets('"Use a new card" shows the form, which is validated before paying', (tester) async {
    await _pump(tester, [_card('c1', '4242', isDefault: true)]);
    await tester.tap(find.text('Use a new card'));
    await tester.pumpAndSettle();
    expect(_cardNumberField, findsOneWidget);

    await _tapPay(tester); // empty form
    expect(_log, isEmpty); // never reached the payment
  });

  testWidgets('a new card is saved only AFTER the payment succeeds, when ticked', (tester) async {
    await _pump(tester, const []);
    await tester.enterText(find.byType(TextFormField).at(0), '4111111111111111');
    await tester.enterText(find.byType(TextFormField).at(1), '1229');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.tap(find.text('Save this card for next time'));
    await tester.pumpAndSettle();
    await _tapPay(tester);
    expect(_log, ['upgrade:plan-vip', 'save:Visa/1111/12/2029']);
  });

  testWidgets('not ticked: the new card is not saved', (tester) async {
    await _pump(tester, const []);
    await tester.enterText(find.byType(TextFormField).at(0), '4111111111111111');
    await tester.enterText(find.byType(TextFormField).at(1), '1229');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await _tapPay(tester);
    expect(_log, ['upgrade:plan-vip']);
  });

  testWidgets('a failed payment never saves the card', (tester) async {
    await _pump(tester, const [], failPayment: true);
    await tester.enterText(find.byType(TextFormField).at(0), '4111111111111111');
    await tester.enterText(find.byType(TextFormField).at(1), '1229');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.tap(find.text('Save this card for next time'));
    await tester.pumpAndSettle();
    await _tapPay(tester);
    expect(_log, ['upgrade:plan-vip']);
    expect(find.text('You can only upgrade to a higher-priced plan.'), findsOneWidget);
  });

  testWidgets('an expired saved card is shown but cannot be picked', (tester) async {
    await _pump(tester, [_card('old', '1111', expYear: 2020, expMonth: 1), _card('c2', '8888')]);
    expect(find.text('Expired'), findsOneWidget);
    await tester.tap(find.text('Visa •••• 1111'));
    await tester.pumpAndSettle();
    await _tapPay(tester); // still paying with the valid card, not the expired one
    expect(_log, ['upgrade:plan-vip']);
  });

  testWidgets('only an expired saved card: the new-card form is preselected', (tester) async {
    await _pump(tester, [_card('old', '1111', expYear: 2020, expMonth: 1)]);
    expect(_cardNumberField, findsOneWidget);
  });
}
