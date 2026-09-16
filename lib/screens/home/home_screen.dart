import 'package:flutter/material.dart';

import '../../models/membership_plan.dart';
import '../../models/usage_allowance.dart';
import '../../services/subscription_service.dart';
import '../../services/usage_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/service_hours.dart';
import '../../widgets/coming_soon_screen.dart';

/// Home's membership status card (Figma node 1217:3576), usage progress
/// cards (1217:3615/3633), and quick-action buttons (1217:3587) -- the
/// dashboard content this and the two preceding tasks build. Real data
/// only: plan name/valid-until/limits from [membership] (fetched once by
/// [MainShell] and shared with the QR Code tab too -- see its own doc
/// comment for why), usage from [UsageService.fetchCurrentUsage], never
/// hardcoded.
///
/// This screen no longer fetches or gates on [ActiveMembership] itself
/// (that moved to `MainShell` in Sprint 4 Task 2, so QR Code could reuse
/// the same fetch instead of querying it a second time) -- `MainShell`
/// never builds this widget at all until it has a non-null membership, so
/// there's nothing to bounce from here anymore.
///
/// The two quick-action buttons don't navigate via `Navigator` -- "Access
/// Café" and "Reserve Event" are tabs of the same [MainShell] Home lives
/// in, not separate pushed screens, so `MainShell` passes down the same
/// tab-switch callback its bottom nav uses ([onGoToQrCode]/[onGoToEvents])
/// rather than this screen reaching for a Navigator that doesn't lead
/// there.
///
/// The notification bell (Figma node 1217:3570) is a stub only, on
/// purpose: icon + navigation to a `ComingSoonScreen`, no unread-count
/// logic and no badge, even though the Figma mock shows one with a "2" on
/// it. Building that would mean inventing a notifications table/schema
/// that hasn't been decided on -- logged as an open question in
/// docs/decisions.md rather than guessed at here. This screen also
/// doesn't build the rest of the Figma header around the bell (a
/// "Welcome, {name}!" greeting and member ID) -- out of this task's
/// scope, not overlooked.
class HomeScreen extends StatefulWidget {
  final ActiveMembership membership;
  final VoidCallback onGoToQrCode;
  final VoidCallback onGoToEvents;

  const HomeScreen({
    super.key,
    required this.membership,
    required this.onGoToQrCode,
    required this.onGoToEvents,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _usageService = const UsageService();

  bool _loading = true;
  UsageAllowance _usage = const UsageAllowance(hookahUsed: 0, drinksUsed: 0);

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final membership = widget.membership;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textMuted),
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ComingSoonScreen(label: 'Notifications')),
              ),
            ),
          ),
          _MembershipStatusCard(membership: membership),
          const SizedBox(height: 24),
          _QuickActionButton(
            icon: Icons.qr_code_outlined,
            label: 'Access Café',
            gradient: AppColors.primaryGradient,
            iconColor: Colors.white,
            textColor: Colors.white,
            onTap: widget.onGoToQrCode,
          ),
          const SizedBox(height: 16),
          _QuickActionButton(
            icon: Icons.calendar_today_outlined,
            label: 'Reserve Event',
            backgroundColor: AppColors.cardWhite,
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            iconColor: AppColors.bottomNavActive,
            textColor: AppColors.textDark,
            onTap: widget.onGoToEvents,
          ),
          const SizedBox(height: 24),
          _UsageCard(
            icon: Icons.local_fire_department,
            iconBackground: const Color(0xFFFFEDD4),
            iconColor: const Color(0xFFF54900),
            label: 'Hookah Sessions',
            used: _usage.hookahUsed,
            limit: membership.hookahLimit,
          ),
          const SizedBox(height: 24),
          _UsageCard(
            icon: Icons.local_bar,
            iconBackground: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF155DFC),
            label: 'Drinks',
            used: _usage.drinksUsed,
            limit: membership.drinksLimit,
          ),
          const SizedBox(height: 24),
          const _ServiceHoursCard(),
          const SizedBox(height: 24),
          _BenefitsCard(plan: membership.plan),
        ],
      ),
    );
  }
}

class _MembershipStatusCard extends StatelessWidget {
  final ActiveMembership membership;

  const _MembershipStatusCard({required this.membership});

  @override
  Widget build(BuildContext context) {
    final d = membership.validUntil;
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
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
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
                    const Text(
                      'Membership Status',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.15, color: Colors.white),
                    ),
                    Text(
                      '${membership.planName} Member',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500, letterSpacing: 0.4, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'Valid until: ${d.month}/${d.day}/${d.year}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.15, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// One usage stat card (Figma nodes 1217:3615/3633, the two usage
/// `Card`s inside `MemberDashboard`) -- real `used` from
/// [UsageService.fetchCurrentUsage], real `limit` from the active plan.
///
/// `limit == null` is this app's established "unlimited" sentinel (see
/// [MembershipPlan.hookahLimit]/`drinksLimit`, which VIP's seed row sets to
/// SQL `NULL`, not a magic number like -1 or 0) -- so there is no limit to
/// divide by and no fraction to show. Rendered as "Unlimited" with no
/// progress bar at all, rather than computing `used / null` (a compile
/// error in Dart, but the equivalent bug in a looser language is exactly
/// the "15/null" this task called out to guard against) or inventing a
/// fake 100%-full bar that would misleadingly suggest a cap exists.
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
    final planLimit = limit;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMuted),
                  ),
                  Text(
                    planLimit == null ? 'Unlimited' : '$used / $planLimit',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: AppColors.textDark),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$used used this month',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.membershipPriceSuffix),
          ),
          if (planLimit != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: planLimit <= 0 ? 0 : (used / planLimit).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFF030213).withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF030213)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One quick-action button (Figma node 1217:3587's two `Button`s) --
/// "Access Café" (filled, the app's real primary gradient -- same
/// `primaryGradient` the Sign In button already uses, not a separate
/// per-screen color) and "Reserve Event" (white/outlined). Both are stubs
/// this task: they switch [MainShell] to the QR Code / Events tab, which
/// are themselves still `ComingSoonScreen`s until Sprint 4/their own task
/// builds them for real -- this task's job is only that tapping actually
/// gets you there.
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
                Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Service Hours card (Figma node 1217:3650) -- static hours from the
/// design, no database involved (these never vary per user or change at
/// runtime, unlike everything else on this dashboard). The one real piece
/// of logic here is "Current Status," computed live from
/// [ServiceHours.isFullServiceAt] against `DateTime.now()` at build time
/// -- not hardcoded, and not a stored value that could ever drift from
/// the actual time.
///
/// **Single-Figma-instance judgment call**, same kind decisions #27/#28
/// already flagged for this dashboard: the design only shows the
/// "Current Status" banner in its full-service state (green background,
/// green border, green text) -- there's no second instance showing what
/// self-service looks like. Rather than invent an unevidenced second
/// color scheme, both states reuse the same green treatment and differ
/// only in text. The self-service copy itself ("Self-service hours") is
/// also not literally from the design -- the FAQ item that would explain
/// the distinction ("What's the difference between full service and
/// self-service hours?") has no answer text in the Figma export (the
/// same "only 1 of 4 FAQ answers exported" gap already logged in the
/// Sprint 2 checkpoint) -- so this is a reasonable editorial completion,
/// not extracted data, worth a real answer once real FAQ copy exists.
class _ServiceHoursCard extends StatelessWidget {
  const _ServiceHoursCard();

  @override
  Widget build(BuildContext context) {
    final isFullService = ServiceHours.isFullServiceAt(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time, size: 24, color: AppColors.textMuted),
              SizedBox(width: 12),
              Text(
                'Service Hours',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _ServiceHoursRow(label: 'Full Service Hours', value: '9:00 AM - 11:00 PM'),
          const SizedBox(height: 12),
          const _ServiceHoursRow(label: 'Self-Service Hours', value: '11:00 PM - 9:00 AM'),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: Border.all(color: const Color(0xFFB9F8CF)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF016630)),
                children: [
                  const TextSpan(text: 'Current Status: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                    text: isFullService ? 'Full service available' : 'Self-service hours',
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

  const _ServiceHoursRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: AppColors.membershipListText)),
          Text(value, style: const TextStyle(fontSize: 16, color: AppColors.membershipPriceText)),
        ],
      ),
    );
  }
}

/// Membership Benefits card (Figma node 1217:3673). Deliberately renders
/// [MembershipPlan.featureBullets] -- the exact getter Choose Membership's
/// own cards already call, not a re-derived or hand-copied list -- so
/// this card and Choose Membership are structurally incapable of drifting
/// out of sync for the same plan; see docs/decisions.md #31 for why that
/// meant reworking [ActiveMembership] to wrap a real [MembershipPlan]
/// instead of copying a few of its fields.
class _BenefitsCard extends StatelessWidget {
  final MembershipPlan plan;

  const _BenefitsCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Membership Benefits',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textDark),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < plan.featureBullets.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Text(
              '• ${plan.featureBullets[i]}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
