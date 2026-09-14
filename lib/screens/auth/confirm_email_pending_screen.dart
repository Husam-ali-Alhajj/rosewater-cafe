import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/gradient_button.dart';
import 'sign_in_screen.dart';

/// Shown after a successful signUp() that returned no session — meaning
/// the project requires email confirmation and the account isn't usable
/// yet. There's no Figma design for this state (the export assumed
/// confirmation was off), so this reuses the same card layout as the other
/// auth screens for visual consistency.
class ConfirmEmailPendingScreen extends StatelessWidget {
  final String email;

  const ConfirmEmailPendingScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
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
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withValues(alpha: 0.12),
                        ),
                        child: Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 44),
                      ),
                      const SizedBox(height: 24),
                      Text('Confirm Your Email', style: AppTextStyles.heading1, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        'Your account is almost ready. We\'ve sent a confirmation '
                        'link to $email — click it to activate your account, '
                        'then sign in.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMuted,
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        label: 'Back to Sign In',
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                        ),
                      ),
                    ],
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
