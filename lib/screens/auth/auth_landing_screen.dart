import 'package:flutter/material.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/outlined_secondary_button.dart';
import 'create_account_screen.dart';
import 'sign_in_screen.dart';

/// The root "Sign In / Create Account" choice screen shown after onboarding.
class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  void _goToSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  void _goToCreateAccount(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                  // Figma's fractional hairline stroke width (same value as
                  // App Settings' _hairline) -- re-measured in Sprint 6 Task 3
                  // via the Figma app; the original PDF estimate (1.55) was wrong.
                  // The brand-pink tint stays the same in both modes -- it's
                  // an accent detail, not a light/dark neutral.
                  border: Border.all(color: const Color(0xFFFFCCD3), width: 0.515),
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
                    Text(
                      'Rosewater Café',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.logoTitle(context),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'VIP Membership & Lounge',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.31,
                        height: 24 / 16,
                        color: Color(0xFFEC003F),
                      ),
                    ),
                    const SizedBox(height: 56),
                    Column(
                      children: [
                        _FeatureRow(icon: Icons.wifi, label: 'Premium Lounge'),
                        const SizedBox(height: 16),
                        _FeatureRow(icon: Icons.music_note, label: 'Exclusive Services'),
                        const SizedBox(height: 16),
                        _FeatureRow(icon: Icons.people, label: 'Bring Guests'),
                      ],
                    ),
                    const SizedBox(height: 56),
                    GradientButton(
                      label: 'Sign In',
                      onPressed: () => _goToSignIn(context),
                    ),
                    const SizedBox(height: 12),
                    OutlinedSecondaryButton(
                      label: 'Create Account',
                      onPressed: () => _goToCreateAccount(context),
                      borderColor: const Color(0xFFFFA1AD),
                      textColor: const Color(0xFFEC003F),
                      fontSize: 18,
                      height: 28 / 18,
                      letterSpacing: -0.44,
                    ),
                    const SizedBox(height: 56),
                    Text(
                      'Premium hookah lounge & café experience',
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
        Icon(icon, size: 20, color: const Color(0xFFFF2056)),
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
