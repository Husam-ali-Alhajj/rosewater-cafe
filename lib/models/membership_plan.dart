/// A row of `membership_plans`. [features] holds the extra perks (seating, hours...) from the
/// database.
class MembershipPlan {
  final String id;
  final String name;
  final int priceCents;
  final int? hookahLimit;
  final int? drinksLimit;
  final int maxGuests;
  final bool isPopular;
  final List<String> features;

  const MembershipPlan({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.hookahLimit,
    required this.drinksLimit,
    required this.maxGuests,
    required this.isPopular,
    required this.features,
  });

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      priceCents: json['price_cents'] as int,
      hookahLimit: json['hookah_limit'] as int?,
      drinksLimit: json['drinks_limit'] as int?,
      maxGuests: json['max_guests'] as int,
      isPopular: json['is_popular'] as bool,
      features: (json['features'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }

  int get priceDollars => priceCents ~/ 100;

  // Bullet text is built in utils/membership_localization.dart, since it needs translations.
}
