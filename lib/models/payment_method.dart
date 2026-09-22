/// Mirrors a row of `public.payment_methods`. Metadata only -- brand, last 4,
/// expiry and the default flag. There is no field for a full card number or
/// CVV anywhere, because the table has no column for them either.
class PaymentMethod {
  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      brand: json['card_brand'] as String,
      last4: json['last4'] as String,
      expMonth: json['exp_month'] as int,
      expYear: json['exp_year'] as int,
      isDefault: json['is_default'] as bool,
    );
  }

  /// "•••• •••• •••• 4242", as the design shows it.
  String get maskedNumber => '•••• •••• •••• $last4';

  /// "Expires 12/25" (MM/YY), as the design shows it.
  String get expiryLabel {
    final month = expMonth.toString().padLeft(2, '0');
    final year = (expYear % 100).toString().padLeft(2, '0');
    return 'Expires $month/$year';
  }
}
