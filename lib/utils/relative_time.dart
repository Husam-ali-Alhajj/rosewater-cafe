import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// "Just now", "5m ago", "2h ago", "1d ago", then a date after a week. Translated, with the right
/// plural forms in Arabic.
///
/// [now] is a parameter so tests can control it.
String relativeTime(DateTime time, DateTime now, AppLocalizations l10n) {
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return l10n.timeJustNow; // also handles a server clock that's slightly ahead
  if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
  return DateFormat.yMd(l10n.localeName).format(time.toLocal());
}
