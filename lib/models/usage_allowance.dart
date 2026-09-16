/// Mirrors a row of `public.usage_allowances` -- how much of the current
/// billing period's hookah/drinks allotment this member has used so far.
/// Limits live on the plan, not here (see [ActiveMembership] in
/// subscription_service.dart) -- this is only the "used" half.
class UsageAllowance {
  final int hookahUsed;
  final int drinksUsed;
  const UsageAllowance({required this.hookahUsed, required this.drinksUsed});

  factory UsageAllowance.fromJson(Map<String, dynamic> json) {
    return UsageAllowance(
      hookahUsed: json['hookah_used'] as int,
      drinksUsed: json['drinks_used'] as int,
    );
  }
}
