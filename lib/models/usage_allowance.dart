/// How much of this period's hookah and drinks the member has used. The limits come from the plan.
class UsageAllowance {
  final int hookahUsed;
  final int drinksUsed;
  const UsageAllowance({required this.hookahUsed, required this.drinksUsed});

  factory UsageAllowance.fromJson(Map<String, dynamic> json) {
    return UsageAllowance(hookahUsed: json['hookah_used'] as int, drinksUsed: json['drinks_used'] as int);
  }
}
