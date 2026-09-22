import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// Thrown by [DeletionRequestService] with a message that's already safe to
/// show the user directly.
class DeletionRequestFailure implements Exception {
  final String message;
  const DeletionRequestFailure(this.message);
}

/// A member's open request to have their account deleted.
class DeletionRequest {
  final String id;
  final DateTime requestedAt;

  const DeletionRequest({required this.id, required this.requestedAt});

  factory DeletionRequest.fromJson(Map<String, dynamic> json) {
    return DeletionRequest(
      id: json['id'] as String,
      requestedAt: DateTime.parse(json['requested_at'] as String),
    );
  }
}

/// "Delete Account" as a **request queue** (decision #45).
///
/// Supabase's client SDK deliberately can't delete an auth user, and a
/// client-callable function with power over the auth schema is more risk than
/// this project should take. So the button only **records a request** in
/// `deletion_requests` for a person to process manually. Making a request
/// deletes nothing, deactivates nothing and signs nobody out -- the account and
/// all its data stay exactly as they were until staff act on it.
///
/// Plain table access, no RPC: RLS lets a user insert a request for themselves
/// (only as 'pending') and read their own; there is no update or delete policy,
/// so a request can't be edited or hidden from the app. A partial unique index
/// allows at most one open request per user.
class DeletionRequestService {
  const DeletionRequestService();

  /// The caller's open (pending) request, or null if they haven't made one.
  Future<DeletionRequest?> fetchOpenRequest() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await supabase
        .from('deletion_requests')
        .select('id, requested_at')
        .eq('user_id', userId)
        .eq('status', 'pending')
        .maybeSingle();
    if (row == null) return null;
    return DeletionRequest.fromJson(row);
  }

  /// Records a request to delete the caller's account. If one is already open
  /// (a double tap, or a second device) that one is returned instead -- the
  /// database allows only one, so this can never queue duplicates.
  Future<DeletionRequest> request() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const DeletionRequestFailure('Your session expired. Please sign in again.');
    }
    try {
      final row = await supabase
          .from('deletion_requests')
          .insert({'user_id': userId})
          .select('id, requested_at')
          .single();
      return DeletionRequest.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Already requested -- show that request rather than an error.
        final existing = await fetchOpenRequest();
        if (existing != null) return existing;
      }
      throw const DeletionRequestFailure("Couldn't send your request. Please try again.");
    }
  }
}
