import 'supabase_client.dart';

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
}
