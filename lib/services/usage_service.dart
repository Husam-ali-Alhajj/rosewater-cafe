import '../models/usage_allowance.dart';
import 'supabase_client.dart';

class UsageService {
  const UsageService();

  /// The current billing period's usage row, or null if there is none --
  /// no active subscription at all (never subscribed, or lapsed and not
  /// renewed/upgraded).
  ///
  /// Sprint 10 Task 1: this used to just take whichever of the user's
  /// `usage_allowances` rows had the latest `period_start` (decision #28).
  /// That happened to work while a user only ever had one row, but breaks
  /// the moment they don't -- a lapsed member's last real period would
  /// still have the newest `period_start` on record and get shown as
  /// "current" even though there's no active subscription behind it
  /// anymore. Going through the caller's actual active `subscription_id`
  /// instead means a lapsed member correctly gets `null` here (no usage
  /// card at all), not stale numbers from a membership that already ended.
  Future<UsageAllowance?> fetchCurrentUsage() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final subscription = await supabase
        .from('subscriptions')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'active')
        .gt('valid_until', DateTime.now().toUtc().toIso8601String())
        .maybeSingle();
    final subscriptionId = subscription?['id'] as String?;
    if (subscriptionId == null) return null;

    final row = await supabase
        .from('usage_allowances')
        .select('hookah_used, drinks_used')
        .eq('subscription_id', subscriptionId)
        .maybeSingle();
    if (row == null) return null;
    return UsageAllowance.fromJson(row);
  }
}
