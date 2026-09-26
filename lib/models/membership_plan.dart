/// Mirrors a row of `public.membership_plans`. The numeric bullets
/// (hookah/drinks/guests) are derived from real columns; `features` holds
/// the rest of the design's perk list (seating tier, venue hours, etc.) as
/// a real database column rather than hardcoded per-plan-name copy in the
/// app — see docs/decisions.md.
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

  // The English-only bullet list this getter used to build (Unlimited
  // Hookah/Drinks, "Bring N guest(s)", plus the raw `features` strings
  // verbatim) is gone -- every caller needs real Arabic text now, and this
  // is a plain data model with no BuildContext to translate through.
  // See `utils/membership_localization.dart`'s `localizedFeatureBullets`,
  // which both of this getter's two call sites (Choose Membership, Home's
  // Benefits card) now use instead.
}
