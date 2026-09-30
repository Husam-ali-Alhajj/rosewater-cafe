import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/reservation_summary.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/gradient_button.dart';

/// Reservation Confirmed screen (Figma App-13). Takes the just-created
/// reservation's data via constructor from ReserveEventScreen's own
/// already-known state -- zero additional DB reads, same pattern as
/// PaymentSuccessScreen (docs/decisions.md).
///
/// "Back to Dashboard" calls [onBackToDashboard] -- MainShell's own
/// tab-switching callback, the same pattern QrAccessScreen and HomeScreen
/// already use to move between tabs, never a `Navigator.push`. This screen
/// is swapped in by [EventsTab] over ReserveEventScreen directly rather
/// than pushed onto the nav stack in the first place, so there's no
/// dangling entry to leave behind by construction, not just by care taken
/// on the way out.
class ReservationConfirmedScreen extends StatelessWidget {
  final ReservationSummary reservation;
  final VoidCallback onBackToDashboard;

  const ReservationConfirmedScreen({super.key, required this.reservation, required this.onBackToDashboard});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final dateText = DateFormat('M/d/yyyy').format(reservation.eventDate);
    final time = reservation.startTime;
    final timeText = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final duration = reservation.durationHours;
    final durationText = '${_trimTrailingZero(duration)} ${duration == 1 ? l10n.hourSingular : l10n.hourPlural}';
    final guestsText = '${reservation.guestCount} ${l10n.peopleLabel}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colors.textPrimary),
                  child: Icon(Icons.check, color: colors.surface, size: 14),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.eventReservationConfirmedBanner,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: colors.success.withValues(alpha: 0.15)),
                    child: Icon(Icons.check, color: colors.success, size: 44),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.reservationConfirmedHeading,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.reservationConfirmedSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: colors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      _detailRow(colors, l10n.dateColonLabel, dateText),
                      const SizedBox(height: 8),
                      _detailRow(colors, l10n.timeColonLabel, timeText),
                      const SizedBox(height: 8),
                      _detailRow(colors, l10n.durationColonLabel, durationText),
                      const SizedBox(height: 8),
                      _detailRow(colors, l10n.guestsColonLabel, guestsText),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GradientButton(label: l10n.backToDashboard, onPressed: onBackToDashboard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(AppSemanticColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textMuted)),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
        ),
      ],
    );
  }

  String _trimTrailingZero(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toString();
  }
}
