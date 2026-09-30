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

// Colours taken from the design for this screen, each with a matching dark-mode version.
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

/// Picks the light or dark set of the colours above.
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

// Hairline border width from the design.
const _hairline = 0.515;

/// The Home tab. Membership and profile come from MainShell; this screen only loads the current
/// usage.
///
/// "Access Cafe" and "Reserve Event" switch tabs instead of navigating.
///
/// The bell shows the unread count. It refreshes when the notifications screen closes, and live
/// (Supabase Realtime) when a new notification arrives, which also plays the arrival sound. Home
/// stays alive in the background, so this works on every tab.
class HomeScreen extends StatefulWidget {
  final ActiveMembership membership;

  /// Null if the profile couldn't be loaded; the header then just says "Welcome!".
  final Profile? profile;
  final VoidCallback onGoToQrCode;
  final VoidCallback onGoToEvents;

  /// Used by a membership notification's "View Details" (Profile shows the plan details).
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

  /// Listens for new notifications for this user. Realtime respects the same security rules, so
  /// users only hear about their own.
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

  /// If this fails we just show no badge.
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
    await Navigator.of(
      context,
    ).push(appRoute(context, (_) => NotificationsScreen(onViewMembership: widget.onGoToProfile)));
    _loadUnreadCount();
  }

  Future<void> _load() async {
    // No usage row found: show "0 used" instead of an error.
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
      decoration: BoxDecoration(gradient: context.colors.pageBackgroundGradient),
      child: SafeArea(
        bottom: false,
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

/// The dashboard content, kept separate from data loading so it can be tested without Supabase.
class HomeContent extends StatelessWidget {
  final Profile? profile;
  final ActiveMembership membership;
  final UsageAllowance usage;
  final VoidCallback onGoToQrCode;
  final VoidCallback onGoToEvents;
  final VoidCallback onNotifications;
  final VoidCallback? onLogout;

  /// Unread notifications for the bell badge (hidden at 0).
  final int unreadNotifications;

  /// "Now" for the service-hours status; a parameter so tests can control it.
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

/// Card style shared by the usage, service-hours and benefits cards.
BoxDecoration _whiteCardDecoration(BuildContext context) {
  final colors = context.colors;
  return BoxDecoration(
    color: colors.surface.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: colors.border, width: _hairline),
  );
}

/// Greeting and member ID on the left, the notification bell and Logout on the right. Falls back to
/// "Welcome!" if there's no name.
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
                  style: TextStyle(fontSize: 16, height: 24 / 16, letterSpacing: -0.3125, color: home.iconGrey),
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
                    // Red unread-count bubble on the bell. Capped at "9+" so it always fits.
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
    final validUntilText = '${d.month}/${d.day}/${d.year}';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // The design uses the same purple gradient for every plan on this card.
        gradient: AppColors.membershipPremiumGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 20),
            spreadRadius: -5,
          ),
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
                    // Matches the design: the title box is one line tall, so a wrapped title
                    // overflows instead of growing the card.
                    SizedBox(
                      height: 36,
                      child: OverflowBox(
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: Colors.white,
                  ),
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

/// One usage card (hookah or drinks). A null limit means unlimited: we show "Unlimited" and no
/// progress bar.
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
    // The dark progress bar would disappear on a dark card, so dark mode uses a light one.
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
                    style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
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

/// One of the two quick-action buttons ("Access Cafe" / "Reserve Event").
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

/// Service hours from the design. The status line is worked out from the current time.
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
          // Flex values from the design so the text wraps in the same place on small screens.
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
                style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: statusColors.statusInk),
                children: [
                  TextSpan(
                    text: l10n.currentStatusLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
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

  const _ServiceHoursRow({required this.label, required this.value, required this.labelFlex, required this.valueFlex});

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
          Flexible(
            flex: labelFlex,
            child: Text(label, style: style.copyWith(color: home.rowLabel)),
          ),
          Flexible(
            flex: valueFlex,
            child: Text(value, style: style.copyWith(color: home.rowValue)),
          ),
        ],
      ),
    );
  }
}

/// Uses the same bullet list as Choose Membership so the two never disagree.
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
              style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
