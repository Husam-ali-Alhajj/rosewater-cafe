import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/app_notification.dart';
import 'event_type_localization.dart';

/// A notification's title and text in the user's language, built from its type and data. Falls back
/// to the stored English text for unknown types or missing data.
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
      case 'subscription_upgraded':
        final validUntil = DateTime.parse(data['valid_until'] as String).toLocal();
        return (
          title: l10n.notifSubscriptionUpgradedTitle,
          body: l10n.notifSubscriptionUpgradedBody(
            data['previous_plan_name'] as String,
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
            ? (title: l10n.notifEventReminderTitle, body: l10n.notifEventReminderBody(eventType, date, time, guests))
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
    // Missing or invalid data: show the stored English text instead.
    return fallback;
  }
}
