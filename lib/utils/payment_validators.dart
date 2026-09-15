/// Client-side-only shape validation for the mock Payment screen's card
/// fields. This is a training project with no real payment processor (see
/// docs/decisions.md #4) — these checks exist purely so the form behaves
/// realistically, not to actually verify a card. None of these values are
/// ever sent anywhere; kept as pure functions (rather than private State
/// methods) specifically so they're unit-testable on their own.
class PaymentValidators {
  PaymentValidators._();

  static String? cardNumber(String? value) {
    final digits = (value ?? '').replaceAll(' ', '');
    if (!RegExp(r'^\d{16}$').hasMatch(digits)) {
      return 'Enter a 16-digit card number';
    }
    return null;
  }

  static String? expiry(String? value, {DateTime? now}) {
    final text = value ?? '';
    final match = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(text);
    if (match == null) return 'Use MM/YY';
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    final reference = now ?? DateTime.now();
    final expiryEnd = DateTime(year, month + 1); // first moment the card is no longer valid
    if (!expiryEnd.isAfter(reference)) return 'Card has expired';
    return null;
  }

  static String? cvv(String? value) {
    if (!RegExp(r'^\d{3}$').hasMatch(value ?? '')) return 'Enter a 3-digit CVV';
    return null;
  }
}
