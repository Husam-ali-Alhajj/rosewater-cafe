import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../models/membership_plan.dart';
import '../../models/profile.dart';
import '../../models/usage_allowance.dart';
import '../../services/notification_arrival_feedback.dart';
import '../../services/notification_service.dart';
import '../../services/subscription_service.dart';
import '../../services/supabase_client.dart';
import '../../services/usage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/app_feedback.dart';
import '../../utils/membership_localization.dart';
import '../../utils/service_hours.dart';
import '../../widgets/app_page_route.dart';
import '../auth/sign_out.dart';
import '../notifications/notifications_screen.dart';

// Sprint 8 Task 2 (real dark mode): every one of these Figma-exact light
// literals now has a hand-picked dark counterpart below, kept at the same
// hue -- warm neutral greys and a green status chip -- so this card and its
// status banner still look like this design's, just at dark-mode luminance,
// rather than falling back to the generic AppSemanticColors tokens (whose
// [AppSemanticColors.textMuted]/`.surface` etc. are close but weren't tuned
// against these specific fills). See `_homeColors` below for which one a
// given build picks.
const _iconGrey = Color(0xFF4A5565);
const _mutedText = Color(0xFF6A7282);
const _rowFill = Color(0xFFF9FAFB);
const _rowLabel = Color(0xFF364153);
const _rowValue = Color(0xFF101828);
const _statusFill = Color(0xFFF0FDF4);
const _statusBorder = Color(0xFFB9F8CF);
const _statusInk = Color(0xFF016630);

const _iconGreyDark = Color(0xFFC3B2C1);
const _mutedTextDark = Color(0xFFC3B2C1);
const _rowFillDark = Color(0xFF2B1D2C);
const _rowLabelDark = Color(0xFFE7DCE6);
const _rowValueDark = Color(0xFFF5EDF3);
const _statusFillDark = Color(0xFF122A1C);
const _statusBorderDark = Color(0xFF1F5C34);
const _statusInkDark = Color(0xFF6FDD86);

/// This screen's own Figma-literal tokens (see the doc comment above),
/// picked by brightness -- a small brightness-keyed record, not the shared
/// [AppSemanticColors] extension, because these are specific to this
/// dashboard's exact fills rather than generic surface/text roles.
class _HomeColors {
  final Color iconGrey;
  final Color mutedText;
  final Color rowFill;
  final Color rowLabel;
  final Color rowValue;
  final Color statusFill;
  final Color statusBorder;
  final Color statusInk;

  const _HomeColors({
    required this.iconGrey,
    required this.mutedText,
    required this.rowFill,
    required this.rowLabel,
    required this.rowValue,
    required this.statusFill,
    required this.statusBorder,
    required this.statusInk,
  });
}

const _lightHomeColors = _HomeColors(
  iconGrey: _iconGrey,
  mutedText: _mutedText,
  rowFill: _rowFill,
  rowLabel: _rowLabel,
  rowValue: _rowValue,
  statusFill: _statusFill,
  statusBorder: _statusBorder,
  statusInk: _statusInk,
);

const _darkHomeColors = _HomeColors(
  iconGrey: _iconGreyDark,
  mutedText: _mutedTextDark,
  rowFill: _rowFillDark,
  rowLabel: _rowLabelDark,
  rowValue: _rowValueDark,
  statusFill: _statusFillDark,
  statusBorder: _statusBorderDark,
  statusInk: _statusInkDark,
);

_HomeColors _homeColors(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? _darkHomeColors : _lightHomeColors;

// Figma's hairline stroke width on cards / badges (a fractional value from
// the design export, kept exactly).
const _hairline = 0.515;

/// Home tab (Figma frame "MemberDashboard", node 1217:3554).
///
/// `membership` and `profile` come from [MainShell]'s single shared fetch
/// (the same objects the QR Code and Profile tabs get), so nothing they
/// already have is re-queried here; the only thing this screen loads itself
/// is the current period's usage, via [UsageService.fetchCurrentUsage].
/// Real data only -- never hardcoded.
///
/// The two quick-action buttons don't navigate via `Navigator` -- "Access
/// Café" and "Reserve Event" are tabs of the same [MainShell] Home lives
/// in, so `MainShell` passes down the same tab-switch callback its bottom
/// nav uses ([onGoToQrCode]/[onGoToEvents]).
///
/// The notification bell opens the real Notifications feed (notifications
/// roadmap step 2) and shows the design's red unread-count badge, read from
/// `public.notifications` -- refreshed when the feed is closed, since that's
/// where things get marked read or deleted, and live (Supabase Realtime)
/// whenever a new notification is created for this user, which also plays
/// the arrival chime/vibration if the user's switches allow it (roadmap
/// step 4). Home stays alive in MainShell's IndexedStack for the whole
/// signed-in session, so this listens on every tab, not just Home.
class HomeScreen extends StatefulWidget {
  final ActiveMembership membership;

  /// Null if the profile couldn't be loaded; the header then falls back to
  /// a plain "Welcome!" and omits the Member ID line.
  final Profile? profile;
  final VoidCallback onGoToQrCode;
  final VoidCallback onGoToEvents;

  /// For a membership notification's "View Details" (Profile shows the
  /// membership's plan and valid-until date).
  final VoidCallback onGoToProfile;

  const HomeScreen({
    super.key,
    required this.membership,
    required this.profile,
    required this.onGoToQrCode,
    required this.onGoToEvents,
    required this.onGoToProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _usageService = const UsageService();
  final _notificationService = const NotificationService();

  bool _loading = true;
  UsageAllowance _usage = const UsageAllowance(hookahUsed: 0, drinksUsed: 0);
  bool _isSigningOut = false;
  int _unreadCount = 0;
  RealtimeChannel? _notificationsChannel;
  final _arrivalFeedback = NotificationArrivalFeedback.live();

  @override
  void initState() {
    super.initState();
    _load();
    _loadUnreadCount();
    _listenForNewNotifications();
  }

  @override
  void dispose() {
    final channel = _notificationsChannel;
    if (channel != null) supabase.removeChannel(channel);
    super.dispose();
  }

  /// Supabase Realtime: told the moment a notification row is INSERTed for
  /// this user (payment, reservation, reminder, allowance alert). Realtime
  /// applies the table's RLS, so a client only ever hears about its own
  /// rows; the filter just avoids asking for anyone else's.
  void _listenForNewNotifications() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    _notificationsChannel = supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (_) => _onNotificationArrived(),
        )
        .subscribe();
  }

  void _onNotificationArrived() {
    if (!mounted) return;
    _loadUnreadCount();
    context.triggerNotificationArrived(_arrivalFeedback);
  }

  /// The bell badge. A failure just means no badge -- never an error on
  /// the dashboard over a secondary number.
  Future<void> _loadUnreadCount() async {
    int count;
    try {
      count = await _notificationService.unreadCount();
    } catch (_) {
      count = 0;
    }
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      appRoute(
        context,
        (_) => NotificationsScreen(onViewMembership: widget.onGoToProfile),
      ),
    );
    _loadUnreadCount();
  }

  Future<void> _load() async {
    // A missing usage row (shouldn't happen for a genuinely active
    // subscription -- confirm_subscription_payment always creates one --
    // but this isn't the access-gating check MainShell's fetch already
    // did, so it degrades to "0 used" instead of bouncing anywhere.
    final usage = await _usageService.fetchCurrentUsage();
    if (!mounted) return;
    setState(() {
      _usage = usage ?? const UsageAllowance(hookahUsed: 0, drinksUsed: 0);
      _loading = false;
    });
  }

  Future<void> _logout() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    final ok = await signOutAndShowLanding(context);
    if (!ok && mounted) setState(() => _isSigningOut = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // The Figma frame's own fill: the same soft 3-stop page wash used on
      // every other screen.
      decoration: BoxDecoration(gradient: context.colors.pageBackgroundGradient),
      child: SafeArea(
        bottom: false, // the bottom nav in MainShell handles its own inset
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : HomeContent(
                profile: widget.profile,
                membership: widget.membership,
                usage: _usage,
                onGoToQrCode: widget.onGoToQrCode,
                onGoToEvents: widget.onGoToEvents,
                unreadNotifications: _unreadCount,
                onNotifications: _openNotifications,
                onLogout: _isSigningOut ? null : _logout,
              ),
      ),
    );
  }
}

/// The dashboard's content, separated from data loading so the data mapping
/// (greeting, member ID, usage, unlimited plans, service-hours status) can
/// be widget-tested without a Supabase connection.
class HomeContent extends StatelessWidget {
  final Profile? profile;
  final ActiveMembership membership;
  final UsageAllowance usage;
  final VoidCallback onGoToQrCode;
  final VoidCallback onGoToEvents;
  final VoidCallback onNotifications;
  final VoidCallback? onLogout;

  /// Unread notifications, for the bell's badge (none shown at 0).
  final int unreadNotifications;

  /// "Now" for the service-hours status banner; defaults to the real clock.
  /// A parameter only so both banner states are testable.
  final DateTime? now;

  const HomeContent({
    super.key,
    required this.profile,
    required this.membership,
    required this.usage,
    required this.onGoToQrCode,
    required this.onGoToEvents,
    required this.onNotifications,
    required this.onLogout,
    this.unreadNotifications = 0,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      // Figma's frame padding: 16 sides, 32 top. Bottom 16 is the gap the
      // design leaves above the bottom nav (which sits outside this scroll
      // view in MainShell).
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HomeHeader(
            profile: profile,
            unreadNotifications: unreadNotifications,
            onNotifications: onNotifications,
            onLogout: onLogout,
          ),
          const SizedBox(height: 32),
          _MembershipStatusCard(membership: membership),
          const SizedBox(height: 24),
          _QuickActionButton(
            icon: Icons.qr_code_outlined,
            label: l10n.accessCafe,
            gradient: context.colors.accentGradient,
            iconColor: Colors.white,
            textColor: Colors.white,
            onTap: onGoToQrCode,
          ),
          const SizedBox(height: 16),
          _QuickActionButton(
            icon: Icons.calendar_today_outlined,
            label: l10n.reserveEvent,
            backgroundColor: context.colors.surface,
            border: Border.all(color: context.colors.border, width: 1.545),
            iconColor: context.colors.accent,
            textColor: context.colors.textPrimary,
            onTap: onGoToEvents,
          ),
          const SizedBox(height: 24),
          _UsageCard(
            icon: Icons.local_fire_department,
            iconBackground: const Color(0xFFFFEDD4),
            iconColor: const Color(0xFFF54900),
            label: l10n.hookahSessions,
            used: usage.hookahUsed,
            limit: membership.hookahLimit,
          ),
          const SizedBox(height: 24),
          _UsageCard(
            icon: Icons.local_bar,
            iconBackground: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF155DFC),
            label: l10n.drinks,
            used: usage.drinksUsed,
            limit: membership.drinksLimit,
          ),
          const SizedBox(height: 24),
          _ServiceHoursCard(now: now ?? DateTime.now()),
          const SizedBox(height: 24),
          _BenefitsCard(plan: membership.plan),
        ],
      ),
    );
  }
}

/// White-at-90% (this theme's `surface` token in dark mode) card with the
/// design's hairline border and 14px radius, shared by the usage,
/// service-hours and benefits cards.
BoxDecoration _whiteCardDecoration(BuildContext context) {
  final colors = context.colors;
  return BoxDecoration(
    color: colors.surface.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: colors.border, width: _hairline),
  );
}

/// "Welcome, {first name}!" + "Member ID: …" on the left, the notification
/// bell and Logout on the right (Figma nodes 1217:3557-3575).
///
/// Everything is real data: the first name comes from the profile's full
/// name, the member ID from `profiles.member_id`. If the profile couldn't be
/// loaded (or has no name) the greeting is a plain "Welcome!" and a missing
/// member ID hides its line -- never a placeholder name or number.
///
/// The bell is the design's 40x36 button, with the red unread-count badge
/// whenever something is unread (see the class doc on [HomeScreen]).
class _HomeHeader extends StatelessWidget {
  final Profile? profile;
  final int unreadNotifications;
  final VoidCallback onNotifications;
  final VoidCallback? onLogout;

  const _HomeHeader({
    required this.profile,
    required this.unreadNotifications,
    required this.onNotifications,
    required this.onLogout,
  });

  static String? _firstName(String? fullName) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final firstName = _firstName(profile?.fullName);
    final memberId = profile?.memberId;
    final home = _homeColors(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName == null ? l10n.welcomeGeneric : l10n.welcomeNamed(firstName),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 40 / 36,
                  letterSpacing: 0.369,
                  color: context.colors.textPrimary,
                ),
              ),
              if (memberId != null && memberId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.memberIdLabel(memberId),
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    letterSpacing: -0.3125,
                    color: home.iconGrey,
                  ),
                ),
              ],
            ],
          ),
        ),
        Tooltip(
          message: l10n.notifications,
          child: InkWell(
            onTap: onNotifications,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 36,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 16, color: home.iconGrey),
                  if (unreadNotifications > 0)
                    // The design's red count bubble on the bell's top corner
                    // (Figma App-22). Directional, so it sits on the
                    // trailing corner in RTL too. Capped at "9+" so a big
                    // count can't outgrow the bubble.
                    PositionedDirectional(
                      top: 0,
                      end: 4,
                      child: Semantics(
                        label: l10n.unreadBadgeSemantics(unreadNotifications),
                        child: Container(
                          key: const ValueKey('unread-badge'),
                          constraints: const BoxConstraints(minWidth: 16),
                          height: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.colors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ExcludeSemantics(
                            child: Text(
                              unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onLogout,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, size: 16, color: home.iconGrey),
                  const SizedBox(width: 16),
                  Text(
                    l10n.logout,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      letterSpacing: -0.15,
                      color: home.iconGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MembershipStatusCard extends StatelessWidget {
  final ActiveMembership membership;

  const _MembershipStatusCard({required this.membership});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = membership.validUntil;
    // Kept as the app's existing M/D/YYYY, not re-formatted per locale --
    // this task translates text, not date conventions, which weren't asked
    // for. Only the surrounding "Valid until:" wording is localized.
    final validUntilText = '${d.month}/${d.day}/${d.year}';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Same purple gradient as every instance of this card in the
        // Figma file (node 1217:3576) -- one fixed accent for the Home
        // status card regardless of which plan the member is actually on,
        // not per-tier like the Choose Membership cards. Coincidentally
        // the same hex pair already named `membershipPremiumGradient`,
        // reused here rather than duplicated -- see docs/decisions.md #27.
        gradient: AppColors.membershipPremiumGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 8), spreadRadius: -6),
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 25, offset: const Offset(0, 20), spreadRadius: -5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.membershipStatus,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // The design's title box is one line (36) tall inside a
                    // fixed-height card; at 375 wide "Premium Member" wraps
                    // and its second line spills into the 40px gap above
                    // "Valid until" (Figma exports the text as 72 tall in
                    // a 36 tall frame). Reproduced here -- the box keeps
                    // its one-line height and the wrapped line overflows
                    // visibly -- so the card stays 169.03 tall, as designed.
                    SizedBox(
                      height: 36,
                      child: OverflowBox(
                        // `AlignmentDirectional.topStart`, not physical
                        // `Alignment.topLeft` (Sprint 8 Task 6) -- the
                        // overflowing second line needs to spill toward
                        // the same edge the text itself starts from.
                        alignment: AlignmentDirectional.topStart,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: Text(
                          l10n.memberSuffix(membership.planName),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 36 / 30,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6.1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: _hairline),
                ),
                child: Text(
                  l10n.activeStatus,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            l10n.validUntil(validUntilText),
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// One usage stat card (Figma nodes 1217:3615/3633) -- real `used` from
/// [UsageService.fetchCurrentUsage], real `limit` from the active plan.
///
/// Layout, top to bottom, exactly as exported: the icon + label/value row,
/// the progress bar (40 below), then the "used this month" caption (32
/// below the bar).
///
/// `limit == null` is this app's established "unlimited" sentinel (see
/// [MembershipPlan.hookahLimit]/`drinksLimit`, which VIP's seed row sets to
/// SQL `NULL`, not a magic number like -1 or 0) -- so there is no limit to
/// divide by and no fraction to show. Rendered as "Unlimited" with no
/// progress bar at all, rather than computing `used / null` or inventing a
/// fake full bar that would suggest a cap exists. The design has no
/// unlimited variant, so the caption simply follows the header row at 16.
class _UsageCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final int used;
  final int? limit;

  const _UsageCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.used,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final planLimit = limit;
    final colors = context.colors;
    final home = _homeColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The design's progress bar is near-black (#030213) on a white card --
    // on a dark card that fill and its 20%-alpha track both collapse into
    // the background, so dark mode swaps to a near-white fill instead
    // (same idea, inverted for the surface it sits on).
    final progressColor = isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF030213);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _whiteCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: -0.15,
                      color: colors.textMuted,
                    ),
                  ),
                  Text(
                    planLimit == null ? l10n.unlimited : '$used / $planLimit',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 32 / 24,
                      letterSpacing: 0.07,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (planLimit != null) ...[
            const SizedBox(height: 40),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: planLimit <= 0 ? 0 : (used / planLimit).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: progressColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            const SizedBox(height: 32),
          ] else
            const SizedBox(height: 16),
          Text(
            l10n.usedThisMonth(used),
            style: TextStyle(fontSize: 12, height: 16 / 12, color: home.mutedText),
          ),
        ],
      ),
    );
  }
}

/// One quick-action button (Figma node 1217:3587's two `Button`s) --
/// "Access Café" (filled, the app's real primary gradient -- same
/// `primaryGradient` the Sign In button already uses) and "Reserve Event"
/// (white/outlined). They switch [MainShell] to the QR Code / Events tab.
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final BoxBorder? border;
  final Color iconColor;
  final Color textColor;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconColor,
    required this.textColor,
    this.gradient,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            gradient: gradient,
            color: backgroundColor,
            border: border,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 28 / 18,
                    letterSpacing: -0.44,
                    color: textColor,
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

/// Service Hours card (Figma node 1217:3650) -- static hours from the
/// design, no database involved. The one real piece of logic is "Current
/// Status," computed from [ServiceHours.isFullServiceAt] against [now] --
/// not hardcoded, and not a stored value that could drift from the clock.
///
/// **Single-Figma-instance judgment call**: the design only shows the
/// status banner in its full-service state (green). Both states reuse the
/// same green treatment and differ only in text; the self-service copy
/// ("Self-service hours") isn't literal design copy (decision #30).
class _ServiceHoursCard extends StatelessWidget {
  final DateTime now;

  const _ServiceHoursCard({required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFullService = ServiceHours.isFullServiceAt(now);
    final statusColors = _homeColors(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _whiteCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 24, color: statusColors.iconGrey),
              const SizedBox(width: 12),
              Text(
                l10n.serviceHours,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 28 / 20,
                  letterSpacing: -0.45,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // The flex weights are the label/value box widths Figma lays out
          // (128.83:141.13 and 131.48:138.48), so on a 375-wide screen the
          // text wraps exactly where the design does instead of
          // overflowing; on wider screens the rows stay on one line with
          // the value pushed to the right.
          _ServiceHoursRow(
            label: l10n.fullServiceHours,
            value: l10n.fullServiceHoursValue,
            labelFlex: 12883,
            valueFlex: 14113,
          ),
          const SizedBox(height: 12),
          _ServiceHoursRow(
            label: l10n.selfServiceHours,
            value: l10n.selfServiceHoursValue,
            labelFlex: 13148,
            valueFlex: 13848,
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColors.statusFill,
              border: Border.all(color: statusColors.statusBorder, width: _hairline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: statusColors.statusInk,
                ),
                children: [
                  TextSpan(text: l10n.currentStatusLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                    text: isFullService ? l10n.fullServiceAvailable : l10n.selfServiceHoursStatus,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceHoursRow extends StatelessWidget {
  final String label;
  final String value;
  final int labelFlex;
  final int valueFlex;

  const _ServiceHoursRow({
    required this.label,
    required this.value,
    required this.labelFlex,
    required this.valueFlex,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 16, height: 24 / 16, letterSpacing: -0.3125);
    final home = _homeColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: home.rowFill, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(flex: labelFlex, child: Text(label, style: style.copyWith(color: home.rowLabel))),
          Flexible(flex: valueFlex, child: Text(value, style: style.copyWith(color: home.rowValue))),
        ],
      ),
    );
  }
}

/// Membership Benefits card (Figma node 1217:3673). Deliberately renders
/// [localizedFeatureBullets] -- the exact same helper Choose Membership's
/// own cards already call, not a hand-copied list -- so this card and
/// Choose Membership can't drift out of sync for the same plan (#31).
class _BenefitsCard extends StatelessWidget {
  final MembershipPlan plan;

  const _BenefitsCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final bullets = localizedFeatureBullets(plan, AppLocalizations.of(context));
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _whiteCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).membershipBenefits,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 28 / 20,
              letterSpacing: -0.45,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 40),
          for (var i = 0; i < bullets.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Text(
              '• ${bullets[i]}',
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: -0.15,
                color: colors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
