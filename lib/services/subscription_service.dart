import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/membership_plan.dart';
import 'supabase_client.dart';

/// Which of start_subscription's checked failure cases this is — lets the
/// UI react differently (e.g. a specific message) without string-matching
/// `message` itself outside this service.
enum StartSubscriptionErrorCode {
  notAuthenticated,
  activeSubscriptionExists,
  pendingSubscriptionExists,
  unknown,
}

/// Thrown by [SubscriptionService.startSubscription] with a message that's
/// already safe to show the user directly.
class StartSubscriptionFailure implements Exception {
  final StartSubscriptionErrorCode code;
  final String message;
  const StartSubscriptionFailure(this.code, this.message);
}

/// The Home dashboard's membership data: the plan itself (wrapped, not
/// copied field-by-field) plus this specific subscription's `validUntil`.
///
/// Wrapping the real [MembershipPlan] -- rather than re-declaring
/// `hookahLimit`/`drinksLimit`/`features` a second time on this class --
/// is deliberate: Task 7 needs the exact same benefits list Choose
/// Membership already renders via `localizedFeatureBullets`
/// (utils/membership_localization.dart), and the only way to guarantee
/// the two screens can never drift apart is for both to call the same
/// helper on the same model, not two independently maintained copies of
/// the same logic.
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

  /// Whether the current user has a subscription with status 'active' AND
  /// still within its `valid_until`. Used right after sign-in to decide
  /// Home vs. Choose Membership — a signed-up-but-never-paid user has no
  /// active row and resumes at Choose Membership instead.
  ///
  /// The `valid_until > now()` half is deliberate defense in depth, not
  /// redundant: `expire_subscriptions()` (see supabase/migrations/
  /// 20260916090000_expire_subscriptions_cron.sql) only flips the stored
  /// `status` to 'expired' once a day, so a row can sit with a stale
  /// `status = 'active'` for up to ~24h after its `valid_until` has
  /// actually passed. Checking `valid_until` here too means every live
  /// read is correct immediately, without depending on cron timing — see
  /// docs/decisions.md #25.
  ///
  /// The explicit `.eq('user_id', ...)` filter is redundant with RLS (which
  /// already restricts subscriptions to the caller's own rows) but is kept
  /// anyway as defense in depth — this query's correctness shouldn't
  /// silently depend on RLS alone.
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

  /// The Home membership status card's data, or null if there is none --
  /// same `status = 'active' AND valid_until > now()` defensive check as
  /// [hasActiveSubscription] (see docs/decisions.md #25 and #27), so a
  /// lapsed row can never come back here and get rendered as a stale
  /// "Active" card. Home treats null as "bounce to Choose Membership"
  /// rather than showing broken data -- belt-and-suspenders on top of the
  /// same check already gating entry to Home at sign-in/app-start, for the
  /// rare case a subscription expires out from under an already-open
  /// session (accepted as "catch it next navigation", not live-updated --
  /// see decision #27).
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
    return ActiveMembership(
      plan: MembershipPlan.fromJson(planJson),
      validUntil: DateTime.parse(validUntilRaw),
    );
  }

  /// The membership plans to show on Choose Membership, cheapest first.
  Future<List<MembershipPlan>> fetchPlans() async {
    final rows = await supabase.from('membership_plans').select().order('price_cents', ascending: true);
    return rows.map(MembershipPlan.fromJson).toList();
  }

  /// Whether any plan is priced strictly higher than [currentPriceCents] --
  /// Sprint 9 Task 4: decides whether Profile's "Upgrade Membership" entry
  /// point shows at all. A VIP member (already the most expensive plan)
  /// must see it hidden entirely, not a button into an empty screen -- a
  /// `.limit(1)` existence check rather than [fetchPlans], since Profile
  /// only needs a yes/no here, not the plan rows themselves.
  Future<bool> hasUpgradeOption(int currentPriceCents) async {
    final rows = await supabase
        .from('membership_plans')
        .select('id')
        .gt('price_cents', currentPriceCents)
        .limit(1);
    return rows.isNotEmpty;
  }

  /// The plan behind a given subscription — used by ID Upload to show the
  /// plan the user just selected without needing it passed through
  /// navigation, so this screen works the same whether it was reached by a
  /// fresh selection or by resuming a pending subscription on cold start.
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

  /// Calls the start_subscription RPC (see supabase/migrations/
  /// 20260914090100_subscription_two_rpc_pattern.sql) and returns the new
  /// subscription's id. This is the ONLY way a subscription row gets
  /// created from the client — there is no INSERT policy on `subscriptions`.
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

  /// Calls the cancel_subscription RPC (see supabase/migrations/
  /// 20260915100000_cancel_subscription.sql), backing out of a pending
  /// subscription the user started but didn't finish — this is what makes
  /// "Back to Plans" on ID Upload actually work, instead of resuming the
  /// same subscription forever.
  Future<void> cancelSubscription(String subscriptionId) async {
    await supabase.rpc('cancel_subscription', params: {'p_subscription_id': subscriptionId});
  }

  /// Calls the confirm_subscription_payment RPC (see supabase/migrations/
  /// 20260914090100_subscription_two_rpc_pattern.sql) — flips the
  /// subscription to 'active' and creates the first usage_allowances row.
  /// Deliberately takes only the subscription id: no card details are ever
  /// part of this call, or any call this app makes — see PaymentScreen for
  /// why card fields never leave the device at all.
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

  /// Calls the upgrade_subscription RPC (see supabase/migrations/
  /// 20260930150000_upgrade_subscription.sql, hardened by
  /// .../20260930160000_upgrade_subscription_same_day_fix.sql) --
  /// cancels the caller's current active subscription and replaces it
  /// with a new active one on [newPlanId], with a fresh valid_until and
  /// usage_allowances row, all server-side in one transaction. Takes
  /// only the target plan id, unlike [confirmSubscriptionPayment]'s
  /// subscription id -- there's no separate pending row to confirm here;
  /// the RPC finds the caller's own current active row itself
  /// (`auth.uid()`), the same way every other RPC in this project never
  /// trusts a caller-supplied id for who it's acting on.
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

/// Thrown by [SubscriptionService.confirmSubscriptionPayment] with a
/// message that's already safe to show the user directly.
class ConfirmPaymentFailure implements Exception {
  final String message;
  const ConfirmPaymentFailure(this.message);
}

/// Thrown by [SubscriptionService.upgradeSubscription] with a message
/// that's already safe to show the user directly. Deliberately a separate
/// type from [ConfirmPaymentFailure] rather than reusing it -- the two
/// RPCs fail for different reasons (`downgrade_not_supported`,
/// `no_active_subscription`, `plan_not_found` have no equivalent on the
/// signup-payment side), so a shared type would either need a generic
/// message for cases the other RPC can't produce, or an enum matching one
/// RPC's cases exposed on the other's failure type -- same one-type-per-RPC
/// shape [StartSubscriptionFailure] already established.
class UpgradeSubscriptionFailure implements Exception {
  final String message;
  const UpgradeSubscriptionFailure(this.message);
}
