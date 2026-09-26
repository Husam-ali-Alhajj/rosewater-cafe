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
}

/// Thrown by [SubscriptionService.confirmSubscriptionPayment] with a
/// message that's already safe to show the user directly.
class ConfirmPaymentFailure implements Exception {
  final String message;
  const ConfirmPaymentFailure(this.message);
}
