import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/membership_plan.dart';
import 'supabase_client.dart';

/// Which start-subscription error this is.
enum StartSubscriptionErrorCode { notAuthenticated, activeSubscriptionExists, pendingSubscriptionExists, unknown }

/// A start-subscription error with a message safe to show.
class StartSubscriptionFailure implements Exception {
  final StartSubscriptionErrorCode code;
  final String message;
  const StartSubscriptionFailure(this.code, this.message);
}

/// The user's active membership: the plan plus its end date.
class ActiveMembership {
  final MembershipPlan plan;
  final DateTime validUntil;
  const ActiveMembership({required this.plan, required this.validUntil});

  String get planName => plan.name;
  int? get hookahLimit => plan.hookahLimit;
  int? get drinksLimit => plan.drinksLimit;
}

class SubscriptionService {
  const SubscriptionService();

  /// Whether the user has an active membership that hasn't ended. Used after sign-in to pick Home
  /// or Choose Membership.
  ///
  /// We also check `valid_until` because the expiry job only runs once a day.
  Future<bool> hasActiveSubscription() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;
    final rows = await supabase
        .from('subscriptions')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'active')
        .gt('valid_until', DateTime.now().toUtc().toIso8601String())
        .limit(1);
    return rows.isNotEmpty;
  }

  /// The active membership, or null if there isn't one (same checks as [hasActiveSubscription]).
  Future<ActiveMembership?> fetchActiveMembership() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await supabase
        .from('subscriptions')
        .select('valid_until, membership_plans(*)')
        .eq('user_id', userId)
        .eq('status', 'active')
        .gt('valid_until', DateTime.now().toUtc().toIso8601String())
        .maybeSingle();
    if (row == null) return null;
    final planJson = row['membership_plans'] as Map<String, dynamic>?;
    final validUntilRaw = row['valid_until'] as String?;
    if (planJson == null || validUntilRaw == null) return null;
    return ActiveMembership(plan: MembershipPlan.fromJson(planJson), validUntil: DateTime.parse(validUntilRaw));
  }

  /// All plans, cheapest first.
  Future<List<MembershipPlan>> fetchPlans() async {
    final rows = await supabase.from('membership_plans').select().order('price_cents', ascending: true);
    return rows.map(MembershipPlan.fromJson).toList();
  }

  /// Whether any plan costs more than [currentPriceCents]. Decides if Profile shows "Upgrade
  /// Membership".
  Future<bool> hasUpgradeOption(int currentPriceCents) async {
    final rows = await supabase.from('membership_plans').select('id').gt('price_cents', currentPriceCents).limit(1);
    return rows.isNotEmpty;
  }

  /// The plan of a given subscription, used by ID upload.
  Future<MembershipPlan?> fetchPlanForSubscription(String subscriptionId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await supabase
        .from('subscriptions')
        .select('membership_plans(*)')
        .eq('id', subscriptionId)
        .eq('user_id', userId)
        .maybeSingle();
    final planJson = row?['membership_plans'] as Map<String, dynamic>?;
    if (planJson == null) return null;
    return MembershipPlan.fromJson(planJson);
  }

  /// Calls start_subscription and returns the new subscription id. This is the only way the app
  /// creates a subscription.
  Future<String> startSubscription(String planId) async {
    try {
      final result = await supabase.rpc('start_subscription', params: {'p_plan_id': planId});
      return result as String;
    } on PostgrestException catch (e) {
      throw _startSubscriptionFailureFor(e);
    }
  }

  StartSubscriptionFailure _startSubscriptionFailureFor(PostgrestException e) {
    switch (e.message) {
      case 'not_authenticated':
        return const StartSubscriptionFailure(
          StartSubscriptionErrorCode.notAuthenticated,
          'Your session expired. Please sign in again.',
        );
      case 'active_subscription_exists':
        return const StartSubscriptionFailure(
          StartSubscriptionErrorCode.activeSubscriptionExists,
          'You already have an active membership.',
        );
      case 'pending_subscription_exists':
        return const StartSubscriptionFailure(
          StartSubscriptionErrorCode.pendingSubscriptionExists,
          'You already have a membership request in progress.',
        );
    }
    return StartSubscriptionFailure(StartSubscriptionErrorCode.unknown, e.message);
  }

  /// Calls cancel_subscription to back out of a pending (unpaid) subscription ("Back to Plans").
  Future<void> cancelSubscription(String subscriptionId) async {
    await supabase.rpc('cancel_subscription', params: {'p_subscription_id': subscriptionId});
  }

  /// Calls confirm_subscription_payment, which activates the subscription and creates its usage
  /// row. Only the subscription id is sent, never card details.
  Future<void> confirmSubscriptionPayment(String subscriptionId) async {
    try {
      await supabase.rpc('confirm_subscription_payment', params: {'p_subscription_id': subscriptionId});
    } on PostgrestException catch (e) {
      throw _confirmPaymentFailureFor(e);
    }
  }

  ConfirmPaymentFailure _confirmPaymentFailureFor(PostgrestException e) {
    switch (e.message) {
      case 'not_authenticated':
        return const ConfirmPaymentFailure('Your session expired. Please sign in again.');
      case 'subscription_not_found_or_not_pending':
        return const ConfirmPaymentFailure('This subscription is no longer waiting for payment.');
    }
    return ConfirmPaymentFailure(e.message);
  }

  /// Calls upgrade_subscription, which cancels the current membership and starts the new plan with
  /// a fresh period, all on the server. The server finds the user's membership itself.
  Future<DateTime> upgradeSubscription(String newPlanId) async {
    try {
      final result = await supabase.rpc('upgrade_subscription', params: {'p_new_plan_id': newPlanId});
      return DateTime.parse(result as String);
    } on PostgrestException catch (e) {
      throw _upgradeSubscriptionFailureFor(e);
    }
  }

  UpgradeSubscriptionFailure _upgradeSubscriptionFailureFor(PostgrestException e) {
    switch (e.message) {
      case 'not_authenticated':
        return const UpgradeSubscriptionFailure('Your session expired. Please sign in again.');
      case 'no_active_subscription':
        return const UpgradeSubscriptionFailure("You don't have an active membership to upgrade.");
      case 'plan_not_found':
        return const UpgradeSubscriptionFailure('That plan is no longer available.');
      case 'downgrade_not_supported':
        return const UpgradeSubscriptionFailure('You can only upgrade to a higher-priced plan.');
    }
    return UpgradeSubscriptionFailure(e.message);
  }
}

/// A payment error with a message safe to show.
class ConfirmPaymentFailure implements Exception {
  final String message;
  const ConfirmPaymentFailure(this.message);
}

/// An upgrade error with a message safe to show. Separate from [ConfirmPaymentFailure] because the
/// two fail for different reasons.
class UpgradeSubscriptionFailure implements Exception {
  final String message;
  const UpgradeSubscriptionFailure(this.message);
}
