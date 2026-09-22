import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/models/payment_method.dart';
import 'package:rosewater_cafe/screens/profile/add_payment_method_screen.dart';
import 'package:rosewater_cafe/screens/profile/payment_methods_screen.dart';
import 'package:rosewater_cafe/services/payment_method_service.dart';

PaymentMethod _card(String id, String brand, String last4, {bool isDefault = false, int month = 12, int year = 2030}) =>
    PaymentMethod(id: id, brand: brand, last4: last4, expMonth: month, expYear: year, isDefault: isDefault);

/// Stands in for the real service. It keeps its own "server" list, and how it
/// reacts to setDefault/delete is decided by the test -- so the UI tests can
/// prove the screen shows what the SERVER ended up with, not what a naive
/// client-side reorder would have produced.
class _FakeService extends PaymentMethodService {
  _FakeService(this.cards, {this.failLoad = false, this.failure});

  List<PaymentMethod> cards;
  bool failLoad;
  final PaymentMethodFailure? failure;

  final List<String> setDefaultCalls = [];
  final List<String> deleteCalls = [];
  final List<Map<String, Object?>> addCalls = [];
  int listCalls = 0;

  /// What the "database" does when a delete removes the default card.
  String? promoteOnDeleteId;

  @override
  Future<List<PaymentMethod>> list() async {
    listCalls++;
    if (failLoad) throw StateError('offline');
    return List.of(cards);
  }

  @override
  Future<void> setDefault(String id) async {
    setDefaultCalls.add(id);
    if (failure != null) throw failure!;
    // the server swaps the default atomically
    cards = [
      for (final c in cards) _card(c.id, c.brand, c.last4, isDefault: c.id == id, month: c.expMonth, year: c.expYear),
    ];
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls.add(id);
    if (failure != null) throw failure!;
    final removed = cards.firstWhere((c) => c.id == id);
    cards = cards.where((c) => c.id != id).toList();
    if (removed.isDefault && promoteOnDeleteId != null) {
      cards = [
        for (final c in cards)
          _card(c.id, c.brand, c.last4, isDefault: c.id == promoteOnDeleteId, month: c.expMonth, year: c.expYear),
      ];
    }
  }

  @override
  Future<PaymentMethod> add({
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
    bool makeDefault = false,
  }) async {
    addCalls.add({
      'brand': brand,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
      'makeDefault': makeDefault,
    });
    if (failure != null) throw failure!;
    return _card('new', brand, last4, month: expMonth, year: expYear, isDefault: makeDefault);
  }
}

Future<void> _pumpList(WidgetTester tester, _FakeService service) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: PaymentMethodsScreen(service: service)));
  await tester.pumpAndSettle();
}

/// Opens Add Payment Method from a host screen so a test can see what it
/// pops with (`true` once saved).
class _AddResult {
  bool? popped;
  bool didPop = false;
}

Future<_AddResult> _openAdd(WidgetTester tester, _FakeService service, {required bool isFirstCard}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final result = _AddResult();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result.popped = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddPaymentMethodScreen(isFirstCard: isFirstCard, service: service),
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

Finder get _cardNumberField => find.byType(TextFormField).at(0);
Finder get _expiryField => find.byType(TextFormField).at(1);
Finder get _cvvField => find.byType(TextFormField).at(2);

Future<void> _fillValidCard(WidgetTester tester, {String number = '4242424242424242'}) async {
  await tester.enterText(_cardNumberField, number);
  await tester.enterText(_expiryField, '1299'); // formatted to 12/99
  await tester.enterText(_cvvField, '123');
}

void main() {
  group('Payment Methods list', () {
    testWidgets('shows each real card: brand, masked number, expiry, and the Default badge', (tester) async {
      final service = _FakeService([
        _card('1', 'Visa', '4242', isDefault: true, month: 12, year: 2025),
        _card('2', 'Mastercard', '8888', month: 8, year: 2026),
      ]);
      await _pumpList(tester, service);

      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Add New Payment Method'), findsOneWidget);
      expect(find.text('Visa'), findsOneWidget);
      expect(find.text('•••• •••• •••• 4242'), findsOneWidget);
      expect(find.text('Expires 12/25'), findsOneWidget);
      expect(find.text('Mastercard'), findsOneWidget);
      expect(find.text('•••• •••• •••• 8888'), findsOneWidget);
      expect(find.text('Expires 08/26'), findsOneWidget);
      // Exactly one card carries the badge.
      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('default card has only Delete; other cards also get Set as default', (tester) async {
      final service = _FakeService([
        _card('1', 'Visa', '4242', isDefault: true),
        _card('2', 'Mastercard', '8888'),
      ]);
      await _pumpList(tester, service);

      expect(find.byTooltip('Delete'), findsNWidgets(2));
      expect(find.byTooltip('Set as default'), findsOneWidget); // only the non-default card
    });

    testWidgets('empty state when there are no cards', (tester) async {
      await _pumpList(tester, _FakeService([]));

      expect(find.text("You haven't added a payment method yet."), findsOneWidget);
      expect(find.text('Add New Payment Method'), findsOneWidget);
    });

    testWidgets('a failed load shows a retry, and retrying loads the cards', (tester) async {
      final service = _FakeService([_card('1', 'Visa', '4242', isDefault: true)], failLoad: true);
      await _pumpList(tester, service);

      expect(find.text("Couldn't load your payment methods."), findsOneWidget);

      service.failLoad = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Visa'), findsOneWidget);
      expect(find.text("Couldn't load your payment methods."), findsNothing);
    });

    testWidgets('Set as default asks the server once and shows what the server returns', (tester) async {
      final service = _FakeService([
        _card('1', 'Visa', '4242', isDefault: true),
        _card('2', 'Mastercard', '8888'),
      ]);
      await _pumpList(tester, service);
      final loadsBefore = service.listCalls;

      await tester.tap(find.byTooltip('Set as default'));
      await tester.pumpAndSettle();

      // One request, for the tapped card -- the client never unchecks the old
      // default itself; the database does that.
      expect(service.setDefaultCalls, ['2']);
      expect(service.listCalls, loadsBefore + 1); // reloaded from the server
      // The Default badge is now on the Mastercard's card, and only there.
      expect(find.text('Default'), findsOneWidget);
      expect(find.byTooltip('Set as default'), findsOneWidget); // now on the Visa
    });

    testWidgets('delete asks for confirmation first, and Cancel deletes nothing', (tester) async {
      final service = _FakeService([_card('1', 'Visa', '4242', isDefault: true)]);
      await _pumpList(tester, service);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Remove this card?'), findsOneWidget);
      expect(find.text('Visa ending in 4242 will be removed from your account.'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(service.deleteCalls, isEmpty);
      expect(find.text('Visa'), findsOneWidget);
    });

    testWidgets('confirming a delete removes it, and shows the card the SERVER promoted', (tester) async {
      // Three cards; the default is deleted and the server promotes the middle
      // one -- not the first in the list, which is what a naive client-side
      // "make the next card default" would have picked.
      final service = _FakeService([
        _card('1', 'Visa', '4242', isDefault: true),
        _card('2', 'Mastercard', '8888'),
        _card('3', 'Discover', '0004'),
      ])..promoteOnDeleteId = '3';
      await _pumpList(tester, service);

      await tester.tap(find.byTooltip('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(service.deleteCalls, ['1']);
      expect(find.text('Visa'), findsNothing);
      expect(find.text('Default'), findsOneWidget);
      // The Discover (id 3) holds the badge: it has no "Set as default" button,
      // the remaining Mastercard does.
      expect(find.byTooltip('Set as default'), findsOneWidget);
    });

    testWidgets('a failed action shows a message and the list stays consistent', (tester) async {
      final service = _FakeService(
        [_card('1', 'Visa', '4242', isDefault: true), _card('2', 'Mastercard', '8888')],
        failure: const PaymentMethodFailure("That didn't go through. Please try again."),
      );
      await _pumpList(tester, service);

      await tester.tap(find.byTooltip('Set as default'));
      await tester.pumpAndSettle();

      expect(find.text("That didn't go through. Please try again."), findsOneWidget);
      // Nothing changed: the Visa is still the default.
      expect(find.text('Default'), findsOneWidget);
    });
  });

  group('Add Payment Method', () {
    testWidgets('invalid card details are rejected client-side, before the service is called', (tester) async {
      final service = _FakeService([]);
      final result = await _openAdd(tester, service, isFirstCard: true);

      await tester.enterText(_cardNumberField, '424242424242424'); // 15 digits
      await tester.enterText(_expiryField, '0120'); // 01/20: in the past
      await tester.enterText(_cvvField, '12'); // 2 digits
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a 16-digit card number'), findsOneWidget);
      expect(find.text('Card has expired'), findsOneWidget);
      expect(find.text('Enter a 3-digit CVV'), findsOneWidget);
      expect(service.addCalls, isEmpty);
      expect(result.didPop, isFalse);
    });

    testWidgets('a valid card saves ONLY brand / last 4 / expiry -- never the number or CVV', (tester) async {
      final service = _FakeService([]);
      final result = await _openAdd(tester, service, isFirstCard: true);

      await _fillValidCard(tester, number: '4242424242429876');
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      expect(service.addCalls, hasLength(1));
      final call = service.addCalls.single;
      expect(call, {
        'brand': 'Visa',
        'last4': '9876',
        'expMonth': 12,
        'expYear': 2099,
        'makeDefault': true, // the first card is always the default
      });
      // Nothing in what was sent contains the full number or the CVV.
      expect(call.values.join(' '), isNot(contains('4242424242429876')));
      expect(call.values.join(' '), isNot(contains('123')));
      expect(result.didPop, isTrue);
      expect(result.popped, isTrue);
    });

    testWidgets('derives the brand from the number (Mastercard)', (tester) async {
      final service = _FakeService([]);
      await _openAdd(tester, service, isFirstCard: true);

      await _fillValidCard(tester, number: '5555555555554444');
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      expect(service.addCalls.single['brand'], 'Mastercard');
      expect(service.addCalls.single['last4'], '4444');
    });

    testWidgets('the first card has no "default" checkbox', (tester) async {
      await _openAdd(tester, _FakeService([]), isFirstCard: true);

      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Set as default payment method'), findsNothing);
    });

    testWidgets('a later card with the checkbox left unchecked is NOT asked to be default', (tester) async {
      final service = _FakeService([_card('1', 'Visa', '4242', isDefault: true)]);
      await _openAdd(tester, service, isFirstCard: false);

      expect(find.text('Set as default payment method'), findsOneWidget);
      await _fillValidCard(tester);
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      expect(service.addCalls.single['makeDefault'], isFalse);
    });

    testWidgets('a later card with the checkbox ticked IS asked to be default', (tester) async {
      final service = _FakeService([_card('1', 'Visa', '4242', isDefault: true)]);
      await _openAdd(tester, service, isFirstCard: false);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await _fillValidCard(tester);
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      expect(service.addCalls.single['makeDefault'], isTrue);
    });

    testWidgets('a failed save shows the message and stays on the screen', (tester) async {
      final service = _FakeService([], failure: const PaymentMethodFailure('That card has expired.'));
      final result = await _openAdd(tester, service, isFirstCard: true);

      await _fillValidCard(tester);
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      expect(find.text('That card has expired.'), findsOneWidget);
      expect(result.didPop, isFalse);
    });

    testWidgets('Cancel discards the form without saving', (tester) async {
      final service = _FakeService([]);
      final result = await _openAdd(tester, service, isFirstCard: true);

      await _fillValidCard(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(service.addCalls, isEmpty);
      expect(result.didPop, isTrue);
      expect(result.popped, isNull);
    });
  });
}
