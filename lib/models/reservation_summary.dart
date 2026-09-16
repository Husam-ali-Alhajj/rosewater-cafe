import 'package:flutter/material.dart';

/// The just-created reservation's data, carried from [ReserveEventScreen]
/// to [ReservationConfirmedScreen] via constructor -- no re-fetch, since
/// the screen that just submitted the reservation already has every field
/// this needs. Same pattern as PaymentSuccessScreen taking its
/// MembershipPlan directly rather than looking it up again.
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
