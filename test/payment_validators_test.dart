import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/utils/payment_validators.dart';

void main() {
  group('cardNumber', () {
    test('accepts 16 digits with spaces (as the design formats it)', () {
      expect(PaymentValidators.cardNumber('1234 5678 9012 3456'), isNull);
    });

    test('accepts 16 digits with no spaces', () {
      expect(PaymentValidators.cardNumber('1234567890123456'), isNull);
    });

    test('rejects 15 digits', () {
      expect(PaymentValidators.cardNumber('123456789012345'), isNotNull);
    });

    test('rejects 17 digits', () {
      expect(PaymentValidators.cardNumber('12345678901234567'), isNotNull);
    });

    test('rejects non-digit characters', () {
      expect(PaymentValidators.cardNumber('1234-5678-9012-345a'), isNotNull);
    });

    test('rejects empty input', () {
      expect(PaymentValidators.cardNumber(''), isNotNull);
      expect(PaymentValidators.cardNumber(null), isNotNull);
    });
  });

  group('expiry', () {
    final referenceNow = DateTime(2026, 6, 15);

    test('accepts a future month/year', () {
      expect(PaymentValidators.expiry('12/26', now: referenceNow), isNull);
    });

    test('accepts the current month (still valid through its last day)', () {
      expect(PaymentValidators.expiry('06/26', now: referenceNow), isNull);
    });

    test('rejects a past month in the current year', () {
      expect(PaymentValidators.expiry('01/26', now: referenceNow), isNotNull);
    });

    test('rejects a past year entirely', () {
      expect(PaymentValidators.expiry('12/25', now: referenceNow), isNotNull);
    });

    test('rejects an invalid month (13)', () {
      expect(PaymentValidators.expiry('13/26', now: referenceNow), isNotNull);
    });

    test('rejects an invalid month (00)', () {
      expect(PaymentValidators.expiry('00/26', now: referenceNow), isNotNull);
    });

    test('rejects malformed input missing the slash', () {
      expect(PaymentValidators.expiry('1226', now: referenceNow), isNotNull);
    });

    test('rejects a 4-digit year', () {
      expect(PaymentValidators.expiry('12/2026', now: referenceNow), isNotNull);
    });
  });

  group('cvv', () {
    test('accepts exactly 3 digits', () {
      expect(PaymentValidators.cvv('123'), isNull);
    });

    test('rejects 2 digits', () {
      expect(PaymentValidators.cvv('12'), isNotNull);
    });

    test('rejects 4 digits', () {
      expect(PaymentValidators.cvv('1234'), isNotNull);
    });

    test('rejects non-digit characters', () {
      expect(PaymentValidators.cvv('12a'), isNotNull);
    });

    test('rejects empty input', () {
      expect(PaymentValidators.cvv(''), isNotNull);
      expect(PaymentValidators.cvv(null), isNotNull);
    });
  });
}
