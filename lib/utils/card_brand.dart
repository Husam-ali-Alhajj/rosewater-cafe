/// Works out a card's brand and last 4 digits from the typed number, just for showing it ("Visa
/// •••• 4242"). There's no payment processor yet, so the brand is guessed from the first digits.
/// Only the brand and last 4 are ever saved.
class CardBrand {
  CardBrand._();

  static const visa = 'Visa';
  static const mastercard = 'Mastercard';
  static const discover = 'Discover';

  /// Used when the brand isn't recognised.
  static const unknown = 'Card';

  static String _digits(String cardNumber) => cardNumber.replaceAll(RegExp(r'\D'), '');

  /// Visa 4...; Mastercard 51-55 or 2221-2720; Discover 6011, 644-649, 65.
  static String detect(String cardNumber) {
    final d = _digits(cardNumber);
    if (d.startsWith('4')) return visa;

    final two = d.length >= 2 ? int.parse(d.substring(0, 2)) : -1;
    final four = d.length >= 4 ? int.parse(d.substring(0, 4)) : -1;
    if ((two >= 51 && two <= 55) || (four >= 2221 && four <= 2720)) return mastercard;

    final three = d.length >= 3 ? int.parse(d.substring(0, 3)) : -1;
    if (d.startsWith('6011') || d.startsWith('65') || (three >= 644 && three <= 649)) return discover;

    return unknown;
  }

  /// The last four digits, or null if fewer than four were typed.
  static String? lastFour(String cardNumber) {
    final d = _digits(cardNumber);
    return d.length < 4 ? null : d.substring(d.length - 4);
  }
}
