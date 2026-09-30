import 'package:flutter/material.dart';

import '../../models/reservation_summary.dart';
import 'reservation_confirmed_screen.dart';
import 'reserve_event_screen.dart';

/// The Events tab: shows the booking form, or the confirmation after a booking. Swapped with a
/// simple condition instead of navigation, so going back to Home leaves nothing behind.
class EventsTab extends StatefulWidget {
  final VoidCallback onGoToHome;

  const EventsTab({super.key, required this.onGoToHome});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  ReservationSummary? _confirmedReservation;

  void _onReservationConfirmed(ReservationSummary reservation) {
    setState(() => _confirmedReservation = reservation);
  }

  void _backToDashboard() {
    // Clear it so the next visit shows an empty form.
    setState(() => _confirmedReservation = null);
    widget.onGoToHome();
  }

  @override
  Widget build(BuildContext context) {
    final reservation = _confirmedReservation;
    if (reservation != null) {
      return ReservationConfirmedScreen(reservation: reservation, onBackToDashboard: _backToDashboard);
    }
    return ReserveEventScreen(onBackToDashboard: widget.onGoToHome, onConfirmed: _onReservationConfirmed);
  }
}
