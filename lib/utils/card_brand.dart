/// Derives a card's display brand and last 4 digits from what the user typed.
///
/// **A training-project simplification, on purpose** (same category as
/// `confirm_subscription_payment`, decisions #4/#16 -- not a new kind): with
/// no real payment processor, there is nothing to tell us the true brand, so
/// it's guessed from the number's leading digits, purely so a saved card can
/// be shown as "Visa •••• 4242". A real processor returns the brand and last
/// 4 alongside a token; this code goes away then. The result is display-only
/// -- never used to decide whether a card is valid.
///
/// The full number never leaves the form: only [detect]'s brand and
/// [lastFour] are ever passed on to the service and stored.
class CardBrand {
  CardBrand._();

  static const visa = 'Visa';
  static const mastercard = 'Mastercard';
  static const discover = 'Discover';

  /// Shown when the leading digits match none of the above.
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
