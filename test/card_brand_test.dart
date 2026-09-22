import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/models/payment_method.dart';
import 'package:rosewater_cafe/utils/card_brand.dart';

void main() {
  group('CardBrand.detect (display-only guess from the leading digits)', () {
    test('Visa starts with 4', () {
      expect(CardBrand.detect('4242424242424242'), 'Visa');
    });

    test('Mastercard: 51-55 and 2221-2720', () {
      expect(CardBrand.detect('5105105105105100'), 'Mastercard');
      expect(CardBrand.detect('5555555555554444'), 'Mastercard');
      expect(CardBrand.detect('2221000000000009'), 'Mastercard'); // start of the 2-series
      expect(CardBrand.detect('2720999999999999'), 'Mastercard'); // end of the 2-series
    });

    test('Mastercard boundaries: 50, 56, 2220 and 2721 are not', () {
      expect(CardBrand.detect('5000000000000000'), 'Card');
      expect(CardBrand.detect('5600000000000000'), 'Card');
      expect(CardBrand.detect('2220999999999999'), 'Card');
      expect(CardBrand.detect('2721000000000000'), 'Card');
    });

    test('Discover: 6011, 644-649, 65', () {
      expect(CardBrand.detect('6011000000000004'), 'Discover');
      expect(CardBrand.detect('6440000000000000'), 'Discover');
      expect(CardBrand.detect('6490000000000000'), 'Discover');
      expect(CardBrand.detect('6500000000000000'), 'Discover');
    });

    test('anything else is a generic "Card"', () {
      expect(CardBrand.detect('9999999999999999'), 'Card');
      expect(CardBrand.detect('1234567812345678'), 'Card');
    });

    test('ignores spaces and short input without throwing', () {
      expect(CardBrand.detect('4242 4242 4242 4242'), 'Visa');
      expect(CardBrand.detect(''), 'Card');
      expect(CardBrand.detect('5'), 'Card');
      expect(CardBrand.detect('55'), 'Mastercard');
    });
  });

  group('CardBrand.lastFour', () {
    test('returns the last four digits', () {
      expect(CardBrand.lastFour('4242424242421111'), '1111');
      expect(CardBrand.lastFour('4242 4242 4242 9876'), '9876');
    });

    test('is null with fewer than four digits', () {
      expect(CardBrand.lastFour('123'), isNull);
      expect(CardBrand.lastFour(''), isNull);
    });
  });

  group('PaymentMethod', () {
    test('maps a row, and formats the masked number and MM/YY expiry', () {
      final method = PaymentMethod.fromJson({
        'id': 'pm-1',
        'card_brand': 'Visa',
        'last4': '4242',
        'exp_month': 5,
        'exp_year': 2027,
        'is_default': true,
        'user_id': 'ignored',
      });
      expect(method.brand, 'Visa');
      expect(method.isDefault, isTrue);
      expect(method.maskedNumber, '•••• •••• •••• 4242');
      expect(method.expiryLabel, 'Expires 05/27');
    });
  });
}
