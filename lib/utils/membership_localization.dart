import '../l10n/app_localizations.dart';
import '../models/membership_plan.dart';

/// A plan's benefit bullets in the user's language. The extra perks come from the database; known
/// ones are translated, and an unknown perk is shown as stored instead of being dropped.
List<String> localizedFeatureBullets(MembershipPlan plan, AppLocalizations l10n) {
  return [
    plan.hookahLimit == null ? l10n.unlimitedHookahFeature : l10n.hookahSessionsPerMonth(plan.hookahLimit!),
    plan.drinksLimit == null ? l10n.unlimitedDrinksFeature : l10n.drinksIncludedCount(plan.drinksLimit!),
    plan.maxGuests == 1 ? l10n.bringGuestBulletSingular : l10n.bringGuestBulletPlural(plan.maxGuests),
    for (final feature in plan.features) _localizedFeature(feature, l10n),
  ];
}

String _localizedFeature(String raw, AppLocalizations l10n) {
  switch (raw) {
    case 'Standard seating':
      return l10n.planFeatureStandardSeating;
    case 'Member discounts':
      return l10n.planFeatureMemberDiscounts;
    case 'Priority seating':
      return l10n.planFeaturePrioritySeating;
    case 'Weekend access':
      return l10n.planFeatureWeekendAccess;
    case 'Private booth':
      return l10n.planFeaturePrivateBooth;
    case '24/7 access':
      return l10n.planFeature247Access;
    case 'Event priority':
      return l10n.planFeatureEventPriority;
    case 'Exclusive menu':
      return l10n.planFeatureExclusiveMenu;
    default:
      return raw; // unknown perk: show it as stored
  }
}
