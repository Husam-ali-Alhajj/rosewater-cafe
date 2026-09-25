import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../services/notification_prefs.dart';
import '../../services/subscription_service.dart';
import '../../services/supabase_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/coming_soon_screen.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/sign_out.dart';
import 'edit_profile_screen.dart';
import 'app_settings_screen.dart';
import 'help_support_screen.dart';
import 'notification_settings_screen.dart';
import 'payment_methods_screen.dart';
import 'privacy_security_screen.dart';

// Exact values read from the Figma `ProfileScreen` frame (node 1216:2169) via
// the REST API -- see docs/decisions.md. Kept private to this file rather
// than added to AppColors, the same way the other exact-Figma screens keep
// their one-off literals local (decision #20).
//
// Sprint 8 Task 2 (dark mode rebuild): the neutral greys/blacks this frame
// exported (icon/label/value/border/fill) are now sourced from
// `context.colors` instead, so they invert correctly. The v3 accent rebuild
// went further and tokenized "Upgrade Membership"'s pink border/text too
// (`colors.accent`), so it goes blue in dark mode with every other accent
// use, instead of staying the design's fixed pink literal.

// Figma's own hairline stroke width on the cards / Upgrade button (a
// fractional value from the design export, kept exactly).
const _hairline = 0.515;

// Matches `version` in pubspec.yaml (1.0.0+1) -- the design's footer line.
const _appVersion = '1.0.0';

/// Profile tab (Figma frame "ProfileScreen", node 1216:2169).
///
/// `membership` comes from [MainShell]'s single shared fetch (same object
/// Home and QR Code get -- decisions #27/#31/#35), so the plan, valid-until
/// and max-guests shown here are never re-queried. The user's own profile
/// (name / email / phone / member ID) is also fetched once by `MainShell`
/// (via [ProfileService.fetchCurrentProfile], decision #18) and passed in as
/// [profile]; this screen only calls the service itself to retry after a
/// failed load.
///
/// Everything shown is real data. A field with no value (a profile with no
/// phone number, say) hides its row instead of showing a placeholder.
///
/// Edit Profile opens the real [EditProfileScreen]; when it saves, the updated
/// profile goes up through [onProfileChanged] to `MainShell`, which owns the
/// profile, so the change shows here, on Home and on the QR tab at once.
/// Payment Methods opens the real [PaymentMethodsScreen] (Sprint 5 Task 3) and
/// Notifications the real, local-only [NotificationSettingsScreen] (Task 4),
/// Privacy & Security the real [PrivacySecurityScreen] (Task 5), and Help &
/// Support the real [HelpSupportScreen] (Task 6), and App Settings the
/// real [AppSettingsScreen] (Task 7).
/// Every other row/button except Sign Out opens a [ComingSoonScreen] for now
/// -- their real screens are later Sprint 5 tasks. Sign Out is the real,
/// permanent one (decisions #21/#26): it ends the session and clears the
/// whole navigation stack so Back can't return to an authenticated screen.
class ProfileScreen extends StatefulWidget {
  final ActiveMembership membership;

  /// Null if `MainShell`'s profile fetch failed -- the header card then
  /// shows a retry prompt (see [ProfileContent]).
  final Profile? profile;

  /// Called with a newly loaded (retry) or newly saved (Edit Profile)
  /// profile, so `MainShell` can update every tab that shows it.
  final ValueChanged<Profile> onProfileChanged;

  const ProfileScreen({
    super.key,
    required this.membership,
    required this.profile,
    required this.onProfileChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = const ProfileService();

  bool _loading = false;
  bool _isSigningOut = false;

  /// Retry after `MainShell`'s profile fetch failed.
  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    Profile? profile;
    try {
      profile = await _profileService.fetchCurrentProfile();
    } catch (_) {
      profile = null; // stays a retryable error below, not a crash
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (profile != null) widget.onProfileChanged(profile);
  }

  void _openAppSettings() {
    Navigator.of(context).push(appRoute(context, (_) => const AppSettingsScreen()));
  }

  void _openHelpSupport() {
    Navigator.of(context).push(appRoute(context, (_) => const HelpSupportScreen()));
  }

  void _openNotificationSettings() {
    // The user id only namespaces the saved choices on this device (so two
    // people sharing a phone don't share settings); reading it from the
    // session is local, not a network call.
    final prefs = NotificationPrefs(userId: supabase.auth.currentUser?.id);
    Navigator.of(context).push(
      appRoute(context, (_) => NotificationSettingsScreen(prefs: prefs)),
    );
  }

  void _openPrivacySecurity() {
    Navigator.of(context).push(appRoute(context, (_) => const PrivacySecurityScreen()));
  }

  void _openPaymentMethods() {
    Navigator.of(context).push(appRoute(context, (_) => const PaymentMethodsScreen()));
  }

  Future<void> _editProfile() async {
    final profile = widget.profile;
    if (profile == null) {
      // Nothing to edit until the profile loads -- retry that instead.
      await _loadProfile();
      return;
    }
    final updated = await Navigator.of(context).push<Profile>(
      appRoute(
        context,
        (_) => EditProfileScreen(profile: profile, membership: widget.membership),
      ),
    );
    if (updated != null && mounted) widget.onProfileChanged(updated);
  }

  void _openComingSoon(String label) {
    Navigator.of(context).push(
      appRoute(context, (_) => ComingSoonScreen(label: label)),
    );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    final ok = await signOutAndShowLanding(context);
    if (!ok && mounted) setState(() => _isSigningOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      // The Figma frame's own fill: the same soft 3-stop page wash used on
      // every other screen.
      decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
      child: SafeArea(
        bottom: false, // the bottom nav in MainShell handles its own inset
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ProfileContent(
                profile: widget.profile,
                membership: widget.membership,
                onRetry: _loadProfile,
                onEditProfile: _editProfile,
                onUpgradeMembership: () => _openComingSoon('Upgrade Membership'),
                onPaymentMethods: _openPaymentMethods,
                onNotifications: _openNotificationSettings,
                onPrivacySecurity: _openPrivacySecurity,
                onHelpSupport: _openHelpSupport,
                onAppSettings: _openAppSettings,
                onSignOut: _isSigningOut ? null : _signOut,
              ),
      ),
    );
  }
}

/// The screen's content, separated from data loading so the data mapping
/// (badge text, hidden rows, date format) can be widget-tested without a
/// Supabase connection.
class ProfileContent extends StatelessWidget {
  /// Null when the profile couldn't be loaded -- the header card then shows
  /// a retry prompt, while the sections that don't depend on it (membership
  /// details, settings, Sign Out) still work.
  final Profile? profile;
  final ActiveMembership membership;
  final VoidCallback onRetry;
  final VoidCallback onEditProfile;
  final VoidCallback onUpgradeMembership;
  final VoidCallback onPaymentMethods;
  final VoidCallback onNotifications;
  final VoidCallback onPrivacySecurity;
  final VoidCallback onHelpSupport;
  final VoidCallback onAppSettings;
  final VoidCallback? onSignOut;

  const ProfileContent({
    super.key,
    required this.profile,
    required this.membership,
    required this.onRetry,
    required this.onEditProfile,
    required this.onUpgradeMembership,
    required this.onPaymentMethods,
    required this.onNotifications,
    required this.onPrivacySecurity,
    required this.onHelpSupport,
    required this.onAppSettings,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    final colors = context.colors;
    return SingleChildScrollView(
      // Figma's frame padding: 16 sides, 32 top. Bottom 16 is the gap the
      // design leaves above the bottom nav (which sits outside this
      // scroll view in MainShell).
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w500,
              height: 40 / 36,
              letterSpacing: 0.369,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          if (profile != null)
            _ProfileCard(profile: profile, planName: membership.planName)
          else
            _ProfileLoadError(onRetry: onRetry),
          const SizedBox(height: 24),
          _OutlinedActionButton(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            ink: colors.textPrimary,
            borderColor: colors.border,
            borderWidth: 1.545,
            iconGap: 17,
            onTap: onEditProfile,
          ),
          const SizedBox(height: 24),
          _MembershipDetailsCard(membership: membership, onUpgrade: onUpgradeMembership),
          const SizedBox(height: 24),
          _SettingsCard(
            onPaymentMethods: onPaymentMethods,
            onNotifications: onNotifications,
            onPrivacySecurity: onPrivacySecurity,
            onHelpSupport: onHelpSupport,
            onAppSettings: onAppSettings,
          ),
          const SizedBox(height: 24),
          _OutlinedActionButton(
            icon: Icons.logout,
            label: 'Sign Out',
            ink: colors.danger,
            borderColor: colors.danger.withValues(alpha: 0.4),
            borderWidth: 1.545,
            iconGap: 16,
            onTap: onSignOut,
          ),
          const SizedBox(height: 24),
          Text(
            'Version $_appVersion • Rosewater Café',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 16 / 12, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Themed card surface with the design's hairline border and 14px radius,
/// shared by all three cards on this screen.
BoxDecoration _cardDecoration(AppSemanticColors colors, {List<BoxShadow>? shadows}) {
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: colors.border, width: _hairline),
    boxShadow: shadows,
  );
}

class _ProfileCard extends StatelessWidget {
  final Profile profile;
  final String planName;

  const _ProfileCard({required this.profile, required this.planName});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final phone = profile.phone;
    final memberId = profile.memberId;
    final rows = <Widget>[
      _InfoRow(icon: Icons.mail_outline, text: profile.email),
      if (phone != null && phone.isNotEmpty) _InfoRow(icon: Icons.phone_outlined, text: phone),
      if (memberId != null && memberId.isNotEmpty)
        _InfoRow(icon: Icons.credit_card_outlined, text: 'Member ID: $memberId'),
    ];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(
        colors,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 8),
            blurRadius: 10,
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 20),
            blurRadius: 25,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(size: 80, avatarPath: profile.avatarUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        height: 32 / 24,
                        letterSpacing: 0.07,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7.15),
                    _PlanBadge(planName: planName),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 64),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// "PREMIUM Member"-style badge. The label is built from the member's real
/// plan name, not hardcoded -- so Basic shows "BASIC Member", VIP shows
/// "VIP Member".
class _PlanBadge extends StatelessWidget {
  final String planName;

  const _PlanBadge({required this.planName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.membershipPremiumGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${planName.toUpperCase()} Member',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: colors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Stand-in for the header card when the profile fetch failed -- not part
/// of the Figma design (which only shows the loaded state), kept minimal
/// and in the same card style so the rest of the screen, including Sign
/// Out, stays usable.
class _ProfileLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(colors),
      child: Column(
        children: [
          Text(
            "Couldn't load your profile.",
            style: TextStyle(fontSize: 14, height: 20 / 14, color: colors.textMuted),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// The two full-width outlined buttons (Edit Profile, Sign Out) -- same
/// shape, differing only in icon/ink/border colour and the icon-to-label
/// gap (Figma centres a 16px icon + label; the gap is 17 on one, 16 on
/// the other, as exported).
class _OutlinedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color ink;
  final Color borderColor;
  final double borderWidth;
  final double iconGap;
  final VoidCallback? onTap;

  const _OutlinedActionButton({
    required this.icon,
    required this.label,
    required this.ink,
    required this.borderColor,
    required this.borderWidth,
    required this.iconGap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          height: 51.09,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: ink),
              SizedBox(width: iconGap),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipDetailsCard extends StatelessWidget {
  final ActiveMembership membership;
  final VoidCallback onUpgrade;

  const _MembershipDetailsCard({required this.membership, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle('Membership Details'),
          const SizedBox(height: 40),
          _DetailRow(label: 'Plan', value: membership.planName),
          const SizedBox(height: 12),
          // Same M/D/YYYY (no leading zeros) Home's status card uses, from
          // the same DateTime, so the two screens always agree.
          _DetailRow(label: 'Valid Until', value: DateFormat('M/d/yyyy').format(membership.validUntil)),
          const SizedBox(height: 12),
          _DetailRow(label: 'Max Guests', value: '${membership.plan.maxGuests}'),
          const SizedBox(height: 40),
          SizedBox(
            height: 36,
            child: Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.accent.withValues(alpha: 0.4), width: _hairline),
              ),
              child: InkWell(
                onTap: onUpgrade,
                customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(
                    'Upgrade Membership',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      letterSpacing: -0.15,
                      color: colors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;

  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 28 / 18,
        letterSpacing: -0.44,
        color: context.colors.textPrimary,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, height: 24 / 16, letterSpacing: -0.31, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final VoidCallback onPaymentMethods;
  final VoidCallback onNotifications;
  final VoidCallback onPrivacySecurity;
  final VoidCallback onHelpSupport;
  final VoidCallback onAppSettings;

  const _SettingsCard({
    required this.onPaymentMethods,
    required this.onNotifications,
    required this.onPrivacySecurity,
    required this.onHelpSupport,
    required this.onAppSettings,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      _SettingsRow(icon: Icons.credit_card_outlined, label: 'Payment Methods', onTap: onPaymentMethods),
      _SettingsRow(icon: Icons.notifications_none, label: 'Notifications', onTap: onNotifications),
      _SettingsRow(icon: Icons.shield_outlined, label: 'Privacy & Security', onTap: onPrivacySecurity),
      _SettingsRow(icon: Icons.help_outline, label: 'Help & Support', onTap: onHelpSupport),
      _SettingsRow(icon: Icons.settings_outlined, label: 'App Settings', onTap: onAppSettings),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context.colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle('Settings'),
          const SizedBox(height: 36),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                    letterSpacing: -0.31,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
