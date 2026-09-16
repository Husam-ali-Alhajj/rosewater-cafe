import '../models/usage_allowance.dart';
import 'supabase_client.dart';

class UsageService {
  const UsageService();

  /// The current billing period's usage row, or null if there is none
  /// (e.g. no active subscription has ever been paid for). There is no
  /// renewal job yet (see docs/decisions.md #25), so a user only ever has
  /// one row today; ordering by `period_start` descending and taking the
  /// first is what still picks the right one once a renewal job exists
  /// and a user has more than one period on record.
  Future<UsageAllowance?> fetchCurrentUsage() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await supabase
        .from('usage_allowances')
        .select('hookah_used, drinks_used')
        .eq('user_id', userId)
        .order('period_start', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return UsageAllowance.fromJson(row);
  }
}
