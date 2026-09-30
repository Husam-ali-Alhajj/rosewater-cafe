import 'package:flutter/material.dart';

/// The reservation just made, passed from the booking form to the confirmation screen.
class ReservationSummary {
  final DateTime eventDate;
  final TimeOfDay startTime;
  final double durationHours;
  final int guestCount;

  const ReservationSummary({
    required this.eventDate,
    required this.startTime,
    required this.durationHours,
    required this.guestCount,
  });
}
