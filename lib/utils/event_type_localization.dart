import '../l10n/app_localizations.dart';

/// Canonical event-type values sent to the server (`p_event_type`) --
/// these stay in English regardless of the active locale, since there's
/// no backing table for event types to be looked up from; only the
/// on-screen label localizes, via [localizedEventType].
const eventTypes = ['Birthday', 'Corporate', 'Private Party', 'Other'];

/// [type]'s label in [l10n]'s language. Shared by the Reserve an Event
/// form and event-reservation notifications (whose `data.event_type` is
/// this same canonical value), so both always show the same wording.
String localizedEventType(AppLocalizations l10n, String type) {
  switch (type) {
    case 'Birthday':
      return l10n.eventTypeBirthday;
    case 'Corporate':
      return l10n.eventTypeCorporate;
    case 'Private Party':
      return l10n.eventTypePrivateParty;
    default:
      return l10n.eventTypeOther;
  }
}
