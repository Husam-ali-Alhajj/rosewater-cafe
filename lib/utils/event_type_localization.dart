import '../l10n/app_localizations.dart';

/// Event types sent to the server. Always English; only the label on screen is translated.
const eventTypes = ['Birthday', 'Corporate', 'Private Party', 'Other'];

/// The translated label for [type]. Used by the booking form and event notifications, so both use
/// the same words.
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
