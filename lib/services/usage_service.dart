import '../models/usage_allowance.dart';
import 'supabase_client.dart';

class UsageService {
  const UsageService();

  /// The usage row of the user's active membership, or null if there's no active membership (so a
  /// lapsed member doesn't see old numbers).
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
