import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/outlined_secondary_button.dart';
import 'create_account_screen.dart';
import 'sign_in_screen.dart';

/// The "Sign In / Create Account" screen shown after onboarding.
class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  void _goToSignIn(BuildContext context) {
    Navigator.of(context).push(appRoute(context, (_) => const SignInScreen()));
  }

  void _goToCreateAccount(BuildContext context) {
    Navigator.of(context).push(appRoute(context, (_) => const CreateAccountScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  // Hairline border in the accent colour (pink in light mode, blue in dark).
                  border: Border.all(color: colors.accent.withValues(alpha: 0.4), width: 0.515),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 50,
                      offset: const Offset(0, 25),
                      spreadRadius: -12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(height: 96),
                    const SizedBox(height: 8),
                    Text(
                      l10n.authLandingTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.31,
                        height: 24 / 16,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(height: 56),
                    Column(
                      children: [
                        _FeatureRow(icon: Icons.wifi, label: l10n.featurePremiumLounge),
                        const SizedBox(height: 16),
                        _FeatureRow(icon: Icons.music_note, label: l10n.featureExclusiveServices),
                        const SizedBox(height: 16),
                        _FeatureRow(icon: Icons.people, label: l10n.featureBringGuests),
                      ],
                    ),
                    const SizedBox(height: 56),
                    GradientButton(label: l10n.signInButton, onPressed: () => _goToSignIn(context)),
                    const SizedBox(height: 12),
                    OutlinedSecondaryButton(
                      label: l10n.createAccount,
                      onPressed: () => _goToCreateAccount(context),
                      borderColor: colors.accent.withValues(alpha: 0.4),
                      textColor: colors.accent,
                      fontSize: 18,
                      height: 28 / 18,
                      letterSpacing: -0.44,
                    ),
                    const SizedBox(height: 56),
                    Text(
                      l10n.authLandingFooter,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: context.colors.accent),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.15,
            height: 20 / 14,
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}
