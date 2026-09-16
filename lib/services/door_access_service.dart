import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Which of log_door_access's checked failure cases this is -- lets the
/// UI react differently without string-matching `message` outside this
/// service.
enum LogDoorAccessErrorCode {
  notAuthenticated,
  noActiveSubscription,
  guestCountExceedsPlanLimit,
  unknown,
}

/// Thrown by [DoorAccessService.logDoorAccess] with a message that's
/// already safe to show the user directly -- never the raw Postgres
/// exception (see docs/decisions.md #35: an expired membership or an
/// out-of-range guest count must surface as a friendly sentence here, not
/// a stack trace).
class LogDoorAccessFailure implements Exception {
  final LogDoorAccessErrorCode code;
  final String message;
  const LogDoorAccessFailure(this.code, this.message);
}

class DoorAccessService {
  const DoorAccessService();

  /// Calls the log_door_access RPC (see supabase/migrations/
  /// 20260916100000_log_door_access.sql) and returns the new
  /// door_access_logs row's id. All the real validation -- active
  /// membership, guest count within the caller's own plan's max_guests --
  /// happens server-side; this call never trusts the client's own guest
  /// stepper limit.
  Future<String> logDoorAccess(int guestCount) async {
    try {
      final result = await supabase.rpc('log_door_access', params: {'p_guest_count': guestCount});
      return result as String;
    } on PostgrestException catch (e) {
      throw _failureFor(e);
    }
  }

  LogDoorAccessFailure _failureFor(PostgrestException e) {
    switch (e.message) {
      case 'not_authenticated':
        return const LogDoorAccessFailure(
          LogDoorAccessErrorCode.notAuthenticated,
          'Your session expired. Please sign in again.',
        );
      case 'no_active_subscription':
        return const LogDoorAccessFailure(
          LogDoorAccessErrorCode.noActiveSubscription,
          "Your membership isn't active right now, so door access isn't available.",
        );
      case 'guest_count_exceeds_plan_limit':
        return const LogDoorAccessFailure(
          LogDoorAccessErrorCode.guestCountExceedsPlanLimit,
          "That's more guests than your plan allows.",
        );
    }
    return LogDoorAccessFailure(LogDoorAccessErrorCode.unknown, 'Something went wrong. Please try again.');
  }
}
