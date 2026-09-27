import 'package:flutter/material.dart';

/// One `event_reservations` row, as the read-only Reservation Details
/// screen shows it (opened from an event notification's "View Details").
/// Unlike [ReservationSummary] -- handed from the booking form straight to
/// its confirmation screen -- this is fetched fresh, so it reflects the
/// reservation as it is now (e.g. a later cancellation).
class ReservationDetails {
  final String id;

  /// The canonical English value sent at booking (see
  /// `utils/event_type_localization.dart`), localized for display.
  final String eventType;
  final DateTime eventDate;
  final TimeOfDay startTime;
  final double durationHours;
  final int guestCount;

  /// 'pending' / 'confirmed' / 'cancelled' (`reservation_status`).
  final String status;
  final double totalPrice;

  const ReservationDetails({
    required this.id,
    required this.eventType,
    required this.eventDate,
    required this.startTime,
    required this.durationHours,
    required this.guestCount,
    required this.status,
    required this.totalPrice,
  });

  factory ReservationDetails.fromMap(Map<String, dynamic> map) {
    final time = (map['start_time'] as String).split(':'); // 'HH:MM:SS'
    return ReservationDetails(
      id: map['id'] as String,
      eventType: map['event_type'] as String,
      eventDate: DateTime.parse(map['event_date'] as String),
      startTime: TimeOfDay(hour: int.parse(time[0]), minute: int.parse(time[1])),
      durationHours: (map['duration_hours'] as num).toDouble(),
      guestCount: map['guest_count'] as int,
      status: map['status'] as String,
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }
}
