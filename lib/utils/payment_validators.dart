/// Card field checks for the payment form. There's no real payment processor, so these only make
/// the form behave realistically; the values are never sent anywhere.
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
    final expiryEnd = DateTime(year, month + 1); // the card stops being valid at this moment
    if (!expiryEnd.isAfter(reference)) return 'Card has expired';
    return null;
  }

  static String? cvv(String? value) {
    if (!RegExp(r'^\d{3}$').hasMatch(value ?? '')) return 'Enter a 3-digit CVV';
    return null;
  }
}
