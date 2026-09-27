import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// "Just now" / "5m ago" / "2h ago" / "1d ago", then a plain date once it's
/// a week old -- the Notifications feed's timestamps (Figma App-23 shows
/// "2h ago", "1d ago" ... and "1/7/2026" for the oldest card). In Arabic
/// these become "منذ ساعتين" etc., with the right plural form.
///
/// [now] is a parameter (not read from the clock here) so the thresholds
/// are testable.
String relativeTime(DateTime time, DateTime now, AppLocalizations l10n) {
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return l10n.timeJustNow; // also covers a slightly-ahead server clock
  if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
  return DateFormat.yMd(l10n.localeName).format(time.toLocal());
}
