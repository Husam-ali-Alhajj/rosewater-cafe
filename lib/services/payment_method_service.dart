import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_method.dart';
import 'supabase_client.dart';

/// Thrown by [PaymentMethodService] with a message that's already safe to show
/// the user directly -- never the raw Postgres exception.
class PaymentMethodFailure implements Exception {
  final String message;
  const PaymentMethodFailure(this.message);
}

/// A user's saved payment methods -- brand, last 4, expiry, default flag.
///
/// **Plain table access, no RPC:** `payment_methods` is fully self-owned (RLS
/// select/insert/update/delete `auth.uid() = user_id`), exactly the kind of
/// write decision #3 always allowed. What RLS can't express is the rule
/// *between* rows -- a user has at most one default -- and that lives in the
/// database, not here: a partial unique index is the hard guarantee, and
/// triggers make "set default" one atomic step, make a user's first card the
/// default, and promote another card when the default is deleted (see
/// supabase/migrations/20260923100000_payment_methods_default_enforcement.sql).
/// So this class never unchecks an old default itself.
///
/// **Never the full number or CVV:** [add] takes only brand/last4/expiry --
/// there is no parameter for anything more, so the number can't be passed by
/// accident. (Brand and last4 are derived from the typed number by the caller;
/// see `CardBrand`.)
class PaymentMethodService {
  const PaymentMethodService();

  /// The caller's cards, default first, then newest first. (RLS already limits
  /// this to the caller's own rows.)
  Future<List<PaymentMethod>> list() async {
    final rows = await supabase
        .from('payment_methods')
        .select()
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(PaymentMethod.fromJson).toList();
  }

  /// Saves a card's metadata. [makeDefault] asks for it to become the default;
  /// the database decides the rest -- a user's first card is the default
  /// whatever is passed.
  Future<PaymentMethod> add({
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
    bool makeDefault = false,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const PaymentMethodFailure('Your session expired. Please sign in again.');
    }
    try {
      final row = await supabase
          .from('payment_methods')
          .insert({
            'user_id': userId,
            'card_brand': brand,
            'last4': last4,
            'exp_month': expMonth,
            'exp_year': expYear,
            'is_default': makeDefault,
          })
          .select()
          .single();
      return PaymentMethod.fromJson(row);
    } on PostgrestException catch (e) {
      throw _failureFor(e);
    }
  }

  /// Makes [id] the default with a single UPDATE; the database clears the old
  /// default in the same step.
  Future<void> setDefault(String id) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const PaymentMethodFailure('Your session expired. Please sign in again.');
    }
    try {
      final rows = await supabase
          .from('payment_methods')
          .update({'is_default': true})
          .eq('id', id)
          .eq('user_id', userId)
          .select('id');
      if (rows.isEmpty) {
        throw const PaymentMethodFailure('That card is no longer available.');
      }
    } on PostgrestException catch (e) {
      throw _failureFor(e);
    }
  }

  /// Deletes [id]. If it was the default, the database promotes the newest
  /// remaining card.
  Future<void> delete(String id) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const PaymentMethodFailure('Your session expired. Please sign in again.');
    }
    try {
      await supabase.from('payment_methods').delete().eq('id', id).eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw _failureFor(e);
    }
  }

  PaymentMethodFailure _failureFor(PostgrestException e) {
    if (e.message.contains('card_expired')) {
      return const PaymentMethodFailure('That card has expired.');
    }
    switch (e.code) {
      case '23505': // the one-default-per-user index lost a race
        return const PaymentMethodFailure("That didn't go through. Please try again.");
      case '23514': // a CHECK constraint (bad last 4 / month / year)
      case '22001': // a value too long for its column
        return const PaymentMethodFailure("Those card details aren't valid.");
    }
    return const PaymentMethodFailure('Something went wrong. Please try again.');
  }
}
