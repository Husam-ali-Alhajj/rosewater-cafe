import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/reservation_details.dart';
import '../../services/event_reservation_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/event_type_localization.dart';
import '../../widgets/screen_header.dart';

/// Read-only details of one reservation, opened from an event notification. Loaded fresh, so it
/// shows the current status (for example, cancelled).
class ReservationDetailsScreen extends StatefulWidget {
  final String reservationId;
  final EventReservationService service;

  const ReservationDetailsScreen({
    super.key,
    required this.reservationId,
    this.service = const EventReservationService(),
  });

  @override
  State<ReservationDetailsScreen> createState() => _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  ReservationDetails? _reservation;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final reservation = await widget.service.fetchReservation(widget.reservationId);
      if (!mounted) return;
      setState(() {
        _reservation = reservation;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final reservation = _reservation;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            children: [
              ScreenHeader(title: l10n.reservationDetailsTitle, onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_failed)
                _Message(
                  text: l10n.couldntLoadReservationError,
                  action: TextButton(onPressed: _load, child: Text(l10n.tryAgainButton)),
                )
              else if (reservation == null)
                _Message(text: l10n.reservationNotFound)
              else
                _DetailsCard(reservation: reservation),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Message({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 48, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.4, color: colors.textMuted),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final ReservationDetails reservation;

  const _DetailsCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final locale = l10n.localeName;
    final r = reservation;
    final start = DateTime(2000, 1, 1, r.startTime.hour, r.startTime.minute);
    final hours = r.durationHours;
    final hoursText = hours == hours.roundToDouble() ? hours.toInt().toString() : hours.toString();
    final durationText = '$hoursText ${hours == 1 ? l10n.hourSingular : l10n.hourPlural}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9810FA).withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.calendar_today_outlined, size: 24, color: Color(0xFF9810FA)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  localizedEventType(l10n, r.eventType),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
              ),
              _StatusChip(status: r.status),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _row(colors, l10n.dateColonLabel, DateFormat.yMMMEd(locale).format(r.eventDate)),
                const SizedBox(height: 12),
                _row(colors, l10n.timeColonLabel, DateFormat.jm(locale).format(start)),
                const SizedBox(height: 12),
                _row(colors, l10n.durationColonLabel, durationText),
                const SizedBox(height: 12),
                _row(colors, l10n.guestsColonLabel, '${r.guestCount} ${l10n.peopleLabel}'),
                const SizedBox(height: 12),
                _row(colors, l10n.totalColonLabel, NumberFormat.simpleCurrency(name: 'USD').format(r.totalPrice)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Same row style as the booking confirmation screen.
  Widget _row(AppSemanticColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: colors.textMuted)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final (label, color) = switch (status) {
      'confirmed' => (l10n.reservationStatusConfirmed, colors.success),
      'cancelled' => (l10n.reservationStatusCancelled, colors.textMuted),
      _ => (l10n.reservationStatusPending, colors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
