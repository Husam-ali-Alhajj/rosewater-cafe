import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/app_notification.dart';
import 'event_type_localization.dart';

/// [notification]'s title and body in [l10n]'s language, built from its
/// `type` + `data` (the facts the server recorded) rather than the
/// English `title`/`body` columns -- so Arabic users read Arabic, and an
/// existing notification re-translates when the language changes.
///
/// Falls back to the stored English `title`/`body` for a type this app
/// version doesn't know yet, or a row whose `data` is missing/malformed
/// (e.g. written before migration 20260929100000 added it) -- never a
/// blank notification or a crash.
({String title, String body}) localizeNotification(AppNotification notification, AppLocalizations l10n) {
  final fallback = (title: notification.title, body: notification.body ?? '');
  final data = notification.data;
  try {
    switch (notification.type) {
      case 'subscription_activated':
        final validUntil = DateTime.parse(data['valid_until'] as String).toLocal();
        return (
          title: l10n.notifSubscriptionActivatedTitle,
          body: l10n.notifSubscriptionActivatedBody(
            data['plan_name'] as String,
            DateFormat.yMMMd(l10n.localeName).format(validUntil),
          ),
        );
      case 'event_reservation_confirmed':
      case 'event_reminder':
        final eventDate = DateTime.parse(data['event_date'] as String);
        final timeParts = (data['start_time'] as String).split(':');
        final startTime = DateTime(2000, 1, 1, int.parse(timeParts[0]), int.parse(timeParts[1]));
        final eventType = localizedEventType(l10n, data['event_type'] as String);
        final date = DateFormat.yMMMd(l10n.localeName).format(eventDate);
        final time = DateFormat.jm(l10n.localeName).format(startTime);
        final guests = data['guest_count'] as int;
        return notification.type == 'event_reminder'
            ? (
                title: l10n.notifEventReminderTitle,
                body: l10n.notifEventReminderBody(eventType, date, time, guests),
              )
            : (
                title: l10n.notifEventReservationConfirmedTitle,
                body: l10n.notifEventReservationConfirmedBody(eventType, date, time, guests),
              );
      case 'allowance_low':
        final remaining = data['remaining'] as int;
        final body = switch (data['kind']) {
          'hookah' => l10n.notifLowHookahBody(remaining),
          'drinks' => l10n.notifLowDrinksBody(remaining),
          _ => null,
        };
        return body == null ? fallback : (title: l10n.notifLowAllowanceTitle, body: body);
      default:
        return fallback;
    }
  } catch (_) {
    // Missing key, wrong type, unparseable date -- show the English text
    // the server stored rather than nothing.
    return fallback;
  }
}
