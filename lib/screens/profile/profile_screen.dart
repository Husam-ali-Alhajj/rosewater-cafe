import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../l10n/app_localizations.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../services/notification_prefs.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/sign_out.dart';
import '../membership/upgrade_membership_screen.dart';
import 'edit_profile_screen.dart';
import 'app_settings_screen.dart';
import 'help_support_screen.dart';
import 'notification_settings_screen.dart';
import 'payment_methods_screen.dart';
import 'privacy_security_screen.dart';

// Sizes from the design; colours come from the theme so dark mode works.

// Hairline border width from the design.
const _hairline = 0.515;

// Matches the app version in pubspec.yaml.
const _appVersion = '1.0.0';

/// The Profile tab. The membership and profile come from MainShell; this screen only reloads the
/// profile when retrying a failed load. Empty fields (like a missing phone number) are hidden.
///
/// Every button opens its real screen. An edited profile is passed back to MainShell so every tab
/// shows it. "Upgrade Membership" only appears when a more expensive plan exists (not for VIP).
/// Sign Out clears navigation so Back can't return here.
class ProfileScreen extends StatefulWidget {
  final ActiveMembership membership;

  /// Null if the profile failed to load; the header then shows a retry button.
  final Profile? profile;

  /// Sends a reloaded or edited profile back to MainShell.
  final ValueChanged<Profile> onProfileChanged;

  const ProfileScreen({super.key, required this.membership, required this.profile, required this.onProfileChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = const ProfileService();
  final _subscriptionService = const SubscriptionService();

  bool _loading = false;
  bool _isSigningOut = false;

  /// Null while checking. Treated as "no" so the button never appears and then disappears.
  bool? _hasUpgradeOption;

  @override
  void initState() {
    super.initState();
    _loadUpgradeOption();
  }

  Future<void> _loadUpgradeOption() async {
    bool has;
    try {
      has = await _subscriptionService.hasUpgradeOption(widget.membership.plan.priceCents);
    } catch (_) {
      has = false; // if the check fails, hide the button
    }
    if (!mounted) return;
    setState(() => _hasUpgradeOption = has);
  }

  /// Retry loading the profile.
  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    Profile? profile;
    try {
      profile = await _profileService.fetchCurrentProfile();
    } catch (_) {
      profile = null;
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
    Navigator.of(
      context,
    ).push(appRoute(context, (_) => const NotificationSettingsScreen(prefs: SupabaseNotificationPrefs())));
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
      // Nothing to edit until the profile loads, so retry instead.
      await _loadProfile();
      return;
    }
    final updated = await Navigator.of(
      context,
    ).push<Profile>(appRoute(context, (_) => EditProfileScreen(profile: profile, membership: widget.membership)));
    if (updated != null && mounted) widget.onProfileChanged(updated);
  }

  void _openUpgradeMembership() {
    Navigator.of(context).push(appRoute(context, (_) => UpgradeMembershipScreen(currentPlan: widget.membership.plan)));
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
      decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
      child: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ProfileContent(
                profile: widget.profile,
                membership: widget.membership,
                hasUpgradeOption: _hasUpgradeOption ?? false,
                onRetry: _loadProfile,
                onEditProfile: _editProfile,
                onUpgradeMembership: _openUpgradeMembership,
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

/// The screen content, kept separate from data loading so it can be tested without Supabase.
class ProfileContent extends StatelessWidget {
  /// Null if the profile failed to load. The header shows a retry button; the rest of the screen
  /// still works.
  final Profile? profile;
  final ActiveMembership membership;

  /// Whether a more expensive plan exists. When false (VIP), the upgrade button is hidden.
  final bool hasUpgradeOption;

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
    required this.hasUpgradeOption,
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
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileHeading,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
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
            label: l10n.editProfileButton,
            ink: colors.textPrimary,
            borderColor: colors.border,
            borderWidth: 1.545,
            iconGap: 17,
            onTap: onEditProfile,
          ),
          const SizedBox(height: 24),
          _MembershipDetailsCard(
            membership: membership,
            hasUpgradeOption: hasUpgradeOption,
            onUpgrade: onUpgradeMembership,
          ),
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
            label: l10n.signOutButton,
            ink: colors.danger,
            borderColor: colors.danger.withValues(alpha: 0.4),
            borderWidth: 1.545,
            iconGap: 16,
            onTap: onSignOut,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.versionFooter(_appVersion),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 16 / 12, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Card style shared by the three cards on this screen.
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
        _InfoRow(icon: Icons.credit_card_outlined, text: AppLocalizations.of(context).memberIdLabel(memberId)),
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
                        fontWeight: FontWeight.w700,
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
          for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: 12), rows[i]],
        ],
      ),
    );
  }
}

/// The "PREMIUM Member" badge, built from the real plan name.
class _PlanBadge extends StatelessWidget {
  final String planName;

  const _PlanBadge({required this.planName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(gradient: AppColors.membershipPremiumGradient, borderRadius: BorderRadius.circular(8)),
      child: Text(
        AppLocalizations.of(context).planBadgeSuffix(planName.toUpperCase()),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12, color: Colors.white),
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
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Shown instead of the header card when the profile failed to load. Not in the design.
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
            AppLocalizations.of(context).couldntLoadProfile,
            style: TextStyle(fontSize: 14, height: 20 / 14, color: colors.textMuted),
          ),
          TextButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).tryAgainButton)),
        ],
      ),
    );
  }
}

/// The two outlined buttons (Edit Profile and Sign Out).
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
  final bool hasUpgradeOption;
  final VoidCallback onUpgrade;

  const _MembershipDetailsCard({required this.membership, required this.hasUpgradeOption, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(l10n.membershipDetailsTitle),
          const SizedBox(height: 40),
          _DetailRow(label: l10n.planLabel, value: membership.planName),
          const SizedBox(height: 12),
          // Same date format as Home's membership card.
          _DetailRow(label: l10n.validUntilLabel, value: DateFormat('M/d/yyyy').format(membership.validUntil)),
          const SizedBox(height: 12),
          _DetailRow(label: l10n.maxGuestsLabel, value: '${membership.plan.maxGuests}'),
          // Hidden when there's no higher plan to upgrade to.
          if (hasUpgradeOption) ...[
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
                      l10n.upgradeMembershipButton,
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
        fontWeight: FontWeight.w700,
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
    final l10n = AppLocalizations.of(context);
    final rows = [
      _SettingsRow(icon: Icons.credit_card_outlined, label: l10n.paymentMethodsLabel, onTap: onPaymentMethods),
      _SettingsRow(icon: Icons.notifications_none, label: l10n.notificationsLabel, onTap: onNotifications),
      _SettingsRow(icon: Icons.shield_outlined, label: l10n.privacySecurityLabel, onTap: onPrivacySecurity),
      _SettingsRow(icon: Icons.help_outline, label: l10n.helpSupportLabel, onTap: onHelpSupport),
      _SettingsRow(icon: Icons.settings_outlined, label: l10n.appSettingsLabel, onTap: onAppSettings),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context.colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(l10n.settingsTitle),
          const SizedBox(height: 36),
          for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: 4), rows[i]],
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
    // The chevron points "forward", so it flips in right-to-left.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
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
              Icon(isRtl ? Icons.chevron_left : Icons.chevron_right, size: 20, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
