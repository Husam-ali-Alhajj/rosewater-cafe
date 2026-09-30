import '../l10n/app_localizations.dart';
import '../models/membership_plan.dart';

/// [plan]'s perk bullets, translated for [l10n]'s language -- the same list
/// [MembershipPlan] used to build itself (Unlimited Hookah/Drinks, "Bring N
/// guest(s)", then `plan.features` verbatim) before Sprint 8 Task 6 made
/// that a real gap: everything else on Choose Membership and Home's
/// Benefits card was translated, but this list quietly stayed English no
/// matter the locale.
///
/// `plan.features` is real backend content (`membership_plans.features`,
/// added by the Task 2 migration specifically so plan copy lives in the
/// database, not hardcoded per-plan-name strings in the app) -- but its
/// *values* are a small, fixed catalog: that migration only ever seeds one
/// of the ~8 strings [_localizedFeature] matches on, not arbitrary text.
/// Translating by exact-string lookup is safe on that basis; anything the
/// lookup doesn't recognize (a perk added directly in Supabase later,
/// before the app ships a translation for it) still shows the raw English
/// value instead of disappearing or crashing.
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
      return raw; // unrecognized -- show the real DB value rather than drop it
  }
}
