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

class SubscriptionService {
  const SubscriptionService();

  /// Whether the current user has a subscription with status 'active'.
  /// Used right after sign-in to decide Home vs. Choose Membership — a
  /// signed-up-but-never-paid user has no active row and resumes at
  /// Choose Membership instead.
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
        .limit(1);
    return rows.isNotEmpty;
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
