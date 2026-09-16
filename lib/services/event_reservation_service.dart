import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Which of create_event_reservation's checked failure cases this is --
/// lets the UI react differently without string-matching `message` outside
/// this service. Client-side validation on Reserve an Event already blocks
/// the guest-count and event-date cases before a request is ever sent --
/// these only fire in practice from a race the form can't catch client-side
/// (e.g. midnight ticking over between opening the date picker and tapping
/// Confirm), not as the real enforcement, which stays server-side.
enum CreateEventReservationErrorCode {
  notAuthenticated,
  guestCountOutOfRange,
  eventDateInPast,
  unknown,
}

/// Thrown by [EventReservationService.createEventReservation] with a
/// message that's already safe to show the user directly -- never the raw
/// Postgres exception.
class CreateEventReservationFailure implements Exception {
  final CreateEventReservationErrorCode code;
  final String message;
  const CreateEventReservationFailure(this.code, this.message);
}

class EventReservationService {
  const EventReservationService();

  /// The flat hourly rate shown as the live "Estimated Total" on Reserve an
  /// Event -- the exact same value the server multiplies by
  /// `duration_hours` in create_event_reservation (see supabase/migrations/
  /// 20260916110000_create_event_reservation.sql's `c_price_per_hour`).
  /// One constant used on both sides is what actually guarantees the
  /// client's displayed estimate and the server-computed `total_price`
  /// can't drift apart -- not just a hope that two independently-typed
  /// `150`s stay in sync. Same placeholder-pricing caveat as the server
  /// constant: pending real numbers from the company (docs/decisions.md
  /// #33/#36).
  static const double pricePerHour = 150.0;

  static double estimatedTotal(double durationHours) => durationHours * pricePerHour;

  /// Calls the create_event_reservation RPC and returns the new
  /// event_reservations row's id. Guest count (5-100) and event date (not
  /// in the past) are validated again here server-side regardless of what
  /// the form already checked -- this call never treats client-side
  /// validation as the actual guarantee.
  Future<String> createEventReservation({
    required String eventType,
    required DateTime eventDate,
    required String startTime, // 'HH:mm:ss'
    required double durationHours,
    required int guestCount,
  }) async {
    try {
      final result = await supabase.rpc('create_event_reservation', params: {
        'p_event_type': eventType,
        'p_event_date': DateFormat('yyyy-MM-dd').format(eventDate),
        'p_start_time': startTime,
        'p_duration_hours': durationHours,
        'p_guest_count': guestCount,
      });
      return result as String;
    } on PostgrestException catch (e) {
      throw _failureFor(e);
    }
  }

  CreateEventReservationFailure _failureFor(PostgrestException e) {
    switch (e.message) {
      case 'not_authenticated':
        return const CreateEventReservationFailure(
          CreateEventReservationErrorCode.notAuthenticated,
          'Your session expired. Please sign in again.',
        );
      case 'guest_count_out_of_range':
        return const CreateEventReservationFailure(
          CreateEventReservationErrorCode.guestCountOutOfRange,
          'Number of guests must be between 5 and 100.',
        );
      case 'event_date_in_past':
        return const CreateEventReservationFailure(
          CreateEventReservationErrorCode.eventDateInPast,
          "That date has already passed -- please choose another.",
        );
    }
    return CreateEventReservationFailure(CreateEventReservationErrorCode.unknown, 'Something went wrong. Please try again.');
  }
}
