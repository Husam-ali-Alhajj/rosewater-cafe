import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Which door-access error this is.
enum LogDoorAccessErrorCode { notAuthenticated, noActiveSubscription, guestCountExceedsPlanLimit, unknown }

/// A door-access error with a friendly message (for example, an expired membership).
class LogDoorAccessFailure implements Exception {
  final LogDoorAccessErrorCode code;
  final String message;
  const LogDoorAccessFailure(this.code, this.message);
}

class DoorAccessService {
  const DoorAccessService();

  /// Calls log_door_access and returns the new log id. The server checks the membership and the
  /// guest limit.
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
