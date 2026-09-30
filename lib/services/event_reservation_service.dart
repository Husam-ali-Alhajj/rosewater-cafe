import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reservation_details.dart';
import 'supabase_client.dart';

/// Which reservation error this is. The form already checks these; they only happen in edge cases
/// like midnight passing while booking.
enum CreateEventReservationErrorCode { notAuthenticated, guestCountOutOfRange, eventDateInPast, unknown }

/// A reservation error with a message safe to show.
class CreateEventReservationFailure implements Exception {
  final CreateEventReservationErrorCode code;
  final String message;
  const CreateEventReservationFailure(this.code, this.message);
}

class EventReservationService {
  const EventReservationService();

  /// Hourly price used for the estimate on the booking screen. Must match `c_price_per_hour` in
  /// create_event_reservation. Placeholder until the company gives real prices.
  static const double pricePerHour = 150.0;

  static double estimatedTotal(double durationHours) => durationHours * pricePerHour;

  /// Calls create_event_reservation and returns the new reservation id. The server checks the guest
  /// count (5-100) and the date again.
  Future<String> createEventReservation({
    required String eventType,
    required DateTime eventDate,
    required String startTime,
    required double durationHours,
    required int guestCount,
  }) async {
    try {
      final result = await supabase.rpc(
        'create_event_reservation',
        params: {
          'p_event_type': eventType,
          'p_event_date': DateFormat('yyyy-MM-dd').format(eventDate),
          'p_start_time': startTime,
          'p_duration_hours': durationHours,
          'p_guest_count': guestCount,
        },
      );
      return result as String;
    } on PostgrestException catch (e) {
      throw _failureFor(e);
    }
  }

  /// One of the user's own reservations, or null if not found (another user's id also reads as not
  /// found).
  Future<ReservationDetails?> fetchReservation(String id) async {
    final row = await supabase
        .from('event_reservations')
        .select('id, event_type, event_date, start_time, duration_hours, guest_count, status, total_price')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : ReservationDetails.fromMap(row);
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
    return CreateEventReservationFailure(
      CreateEventReservationErrorCode.unknown,
      'Something went wrong. Please try again.',
    );
  }
}
