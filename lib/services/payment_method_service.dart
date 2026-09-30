import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_method.dart';
import 'supabase_client.dart';

/// A card error with a message safe to show.
class PaymentMethodFailure implements Exception {
  final String message;
  const PaymentMethodFailure(this.message);
}

/// The user's saved cards: brand, last 4, expiry and default flag.
///
/// Users can read and change only their own rows. The "one default card" rule lives in the database
/// (an index plus triggers that set the first card as default and pick a new one when the default
/// is deleted), so this class never unsets an old default itself.
///
/// [add] has no parameter for the full number or CVV, so they can't be saved by mistake.
class PaymentMethodService {
  const PaymentMethodService();

  /// The user's cards, default first, then newest.
  Future<List<PaymentMethod>> list() async {
    final rows = await supabase
        .from('payment_methods')
        .select()
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(PaymentMethod.fromJson).toList();
  }

  /// Saves a card. The first card always becomes the default, whatever [makeDefault] says.
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

  /// Makes [id] the default; the database unsets the old one in the same step.
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

  /// Deletes [id]. If it was the default, the database picks the newest remaining card.
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
      case '23505': // another request set a default at the same moment
        return const PaymentMethodFailure("That didn't go through. Please try again.");
      case '23514': // invalid last 4, month or year
      case '22001': // a value too long for its column
        return const PaymentMethodFailure("Those card details aren't valid.");
    }
    return const PaymentMethodFailure('Something went wrong. Please try again.');
  }
}
