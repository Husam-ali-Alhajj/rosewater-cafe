import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/notification_localization.dart';
import '../../utils/relative_time.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/screen_header.dart';
import '../events/reservation_details_screen.dart';

const _hairline = 0.515; // Figma's fractional hairline stroke width

/// "View Details" purple from the design (App-23), and a lighter shade of
/// the same hue that stays readable on the dark theme's navy surface.
const _detailsPurple = Color(0xFF9810FA);
const _detailsPurpleDark = Color(0xFFC27AFF);

/// How each notification type looks: the tinted icon circle on the left of
/// its card. Colors follow the design's cards -- green check for a payment
/// ("Payment Successful"), purple calendar for an event ("Event Reminder"),
/// orange alert for low allowance ("Low Allowance Alert"), and blue info
/// for anything this app version doesn't know yet.
({IconData icon, Color color}) _typeVisual(String type) {
  switch (type) {
    case 'subscription_activated':
      return (icon: Icons.check, color: const Color(0xFF00A63E));
    case 'subscription_upgraded':
      return (icon: Icons.workspace_premium_outlined, color: const Color(0xFF9810FA));
    case 'event_reservation_confirmed':
    case 'event_reminder':
      return (icon: Icons.calendar_today_outlined, color: const Color(0xFF9810FA));
    case 'allowance_low':
      // The design's "Low Allowance Alert": an orange "!" in a warm circle.
      return (icon: Icons.error_outline, color: const Color(0xFFE17100));
    default:
      return (icon: Icons.info_outline, color: const Color(0xFF155DFC));
  }
}

/// Notifications feed (Figma frame App-23), opened from the Home bell
/// (notifications roadmap step 2). Real rows from `public.notifications`,
/// newest first, each rendered in the active language from its `type` +
/// `data` (decision #66).
///
/// Per card, as in the design: unread ones get an accent border, a strip
/// on their leading edge, a dot and a "Mark as Read" action; every card has
/// a delete button (own rows only -- migration 20260930110000). "View
/// Details" on an event notification (confirmation or reminder) opens that
/// reservation's read-only details page on top of this list (decision
/// #73); on a membership payment it goes to the Profile tab, which shows
/// the plan and valid-until date. Opening details also marks the
/// notification read.
///
/// Mark-as-read and delete update the list immediately, then save; if the
/// save fails the card goes back to how it was and a snackbar says so.
class NotificationsScreen extends StatefulWidget {
  final NotificationService service;
  final VoidCallback onViewMembership;

  /// "Now" for the relative timestamps; defaults to the real clock.
  final DateTime? now;

  const NotificationsScreen({
    super.key,
    this.service = const NotificationService(),
    required this.onViewMembership,
    this.now,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification>? _items; // null while loading
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _loadFailed = false;
    });
    try {
      final items = await widget.service.fetchAll();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  void _showUpdateError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).couldntUpdateNotificationError)),
    );
  }

  AppNotification _withRead(AppNotification n, bool isRead) => AppNotification(
    id: n.id,
    type: n.type,
    title: n.title,
    body: n.body,
    isRead: isRead,
    relatedId: n.relatedId,
    data: n.data,
    createdAt: n.createdAt,
  );

  void _replace(String id, AppNotification Function(AppNotification) change) {
    setState(() => _items = [for (final n in _items!) n.id == id ? change(n) : n]);
  }

  Future<void> _markRead(AppNotification notification, {bool reportFailure = true}) async {
    if (notification.isRead) return;
    _replace(notification.id, (n) => _withRead(n, true));
    try {
      await widget.service.markRead(notification.id);
    } catch (_) {
      if (!mounted) return;
      _replace(notification.id, (n) => _withRead(n, false));
      if (reportFailure) _showUpdateError();
    }
  }

  Future<void> _delete(AppNotification notification) async {
    final before = _items!;
    setState(() => _items = [for (final n in before) if (n.id != notification.id) n]);
    try {
      await widget.service.delete(notification.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = before);
      _showUpdateError();
    }
  }

  /// What "View Details" does for [notification], or null to hide it.
  VoidCallback? _detailsAction(AppNotification notification) {
    switch (notification.type) {
      case 'event_reservation_confirmed':
      case 'event_reminder':
        final reservationId = notification.relatedId;
        if (reservationId == null) return null;
        return () {
          _markRead(notification);
          Navigator.of(context).push(
            appRoute(context, (_) => ReservationDetailsScreen(reservationId: reservationId)),
          );
        };
      case 'subscription_activated':
      case 'subscription_upgraded':
        return () {
          // Fire-and-forget: leaving the screen shouldn't wait on it, and a
          // failure just leaves it unread (no snackbar on a closing screen).
          _markRead(notification, reportFailure: false);
          Navigator.of(context).pop();
          widget.onViewMembership();
        };
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final items = _items;
    final unread = items?.where((n) => !n.isRead).length ?? 0;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              // Figma's frame padding: 16 sides, 32 top.
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ScreenHeader(title: l10n.notifications, onBack: () => Navigator.of(context).pop()),
                if (items != null)
                  Padding(
                    // Lines up under the title: 40 back button + 16 gap.
                    padding: const EdgeInsetsDirectional.only(start: 56),
                    child: Text(
                      l10n.unreadNotificationsCount(unread),
                      style: TextStyle(fontSize: 14, height: 20 / 14, color: colors.textMuted),
                    ),
                  ),
                const SizedBox(height: 24),
                if (_loadFailed)
                  _Message(
                    icon: Icons.cloud_off_outlined,
                    title: l10n.couldntLoadNotificationsError,
                    action: TextButton(onPressed: _load, child: Text(l10n.tryAgainButton)),
                  )
                else if (items == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty)
                  _Message(
                    icon: Icons.notifications_none,
                    title: l10n.noNotificationsTitle,
                    body: l10n.noNotificationsBody,
                  )
                else
                  for (final n in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _NotificationCard(
                        key: ValueKey('notification-${n.id}'),
                        notification: n,
                        now: widget.now ?? DateTime.now(),
                        onMarkRead: () => _markRead(n),
                        onDelete: () => _delete(n),
                        onViewDetails: _detailsAction(n),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty / error state: an icon, a line or two, and an optional action.
class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  const _Message({required this.icon, required this.title, this.body, this.action});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 48, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: colors.textMuted),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final DateTime now;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;
  final VoidCallback? onViewDetails;

  const _NotificationCard({
    super.key,
    required this.notification,
    required this.now,
    required this.onMarkRead,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = !notification.isRead;
    final text = localizeNotification(notification, l10n);
    final visual = _typeVisual(notification.type);
    final detailsColor = isDark ? _detailsPurpleDark : _detailsPurple;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: unread ? colors.accent : colors.border, width: unread ? 1 : _hairline),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The design's thick accent edge on unread cards. A Row child
            // rather than a one-sided Border (which can't be combined with
            // rounded corners) -- and a Row mirrors itself in RTL, so the
            // strip is always on the reading-start side.
            if (unread) Container(width: 4, color: colors.accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: visual.color.withValues(alpha: isDark ? 0.22 : 0.1),
                      ),
                      child: Icon(visual.icon, size: 24, color: visual.color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  text.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 28 / 18,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  relativeTime(notification.createdAt, now, l10n),
                                  style: TextStyle(fontSize: 12, height: 16 / 12, color: colors.textMuted),
                                ),
                              ),
                              if (unread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  key: const ValueKey('unread-dot'),
                                  margin: const EdgeInsets.only(top: 8),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: colors.accent),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text.body,
                            style: TextStyle(fontSize: 14, height: 20 / 14, color: colors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (unread) ...[
                                _CardAction(
                                  icon: Icons.check,
                                  label: l10n.markAsReadButton,
                                  color: colors.accent,
                                  onTap: onMarkRead,
                                ),
                                const SizedBox(width: 16),
                              ],
                              if (onViewDetails != null)
                                _CardAction(label: l10n.viewDetailsButton, color: detailsColor, onTap: onViewDetails!),
                              const Spacer(),
                              IconButton(
                                tooltip: l10n.deleteTooltip,
                                onPressed: onDelete,
                                icon: Icon(Icons.delete_outline, size: 20, color: colors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "✓ Mark as Read" / "View Details": colored text (with an optional
/// leading icon), no button chrome -- as drawn in the design.
class _CardAction extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CardAction({this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 8)],
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
