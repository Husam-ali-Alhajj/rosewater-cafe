import 'package:flutter/material.dart';

import '../../models/reservation_summary.dart';
import 'reservation_confirmed_screen.dart';
import 'reserve_event_screen.dart';

/// The Events tab's actual content inside MainShell's IndexedStack. Holds
/// which of the tab's two states is showing -- the reservation form, or
/// the confirmation screen for whatever was just submitted -- as plain
/// local state, swapped with a simple conditional rather than a nested
/// Navigator. That's what makes "returning to Home doesn't leave a
/// dangling nav stack entry" true by construction: this transition was
/// never a `Navigator.push` to begin with (see docs/decisions.md #38).
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
    // Cleared here, not only on next entry -- so the next time the user
    // opens the Events tab at all (not just the next time this screen
    // happens to rebuild), they see a fresh, blank ReserveEventScreen
    // rather than the reservation they already confirmed.
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
