import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/onboarding_icon_badge.dart';

/// Real password-reset request: supabase.auth.resetPasswordForEmail(...).
/// Shows the exact same success screen whether or not the email is
/// registered — this is the one screen in the app where hiding account
/// existence is the explicit goal, not an incidental side effect.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = const AuthService();

  bool _isSubmitting = false;
  bool _submitted = false;
  String? _requestError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // same re-entry guard as the other auth forms
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _requestError = null;
    });

    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      // Always the success state on a non-throwing call — resetPassword()
      // only ever throws for a genuine technical problem, never because
      // the email isn't registered, so reaching here means "show success"
      // unconditionally, by design.
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    } on ResetPasswordFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _requestError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Check your connection and try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                    // Figma's fractional hairline stroke (same value as App
                    // Settings' _hairline), confirmed in Sprint 6 Task 3 --
                    // was missing entirely before this fidelity pass.
                    border: Border.all(color: colors.border, width: 0.515),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 50,
                        offset: const Offset(0, 25),
                        spreadRadius: -12,
                      ),
                    ],
                  ),
                  child: _submitted ? _SuccessContent(email: _emailController.text.trim()) : _buildForm(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const OnboardingIconBadge(
            icon: Icons.lock_outline,
            gradient: AppColors.primaryGradient,
          ),
          const SizedBox(height: 24),
          Text('Forgot Password?', style: AppTextStyles.heading1(context)),
          const SizedBox(height: 8),
          Text(
            "No worries! Enter your email address and we'll send you a link to reset your password.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted(context),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'your.email@example.com',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: Validators.email,
          ),
          if (_requestError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _requestError!,
                  style: TextStyle(color: context.colors.danger, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 24),
          GradientButton(
            label: _isSubmitting ? 'Sending…' : 'Send Reset Link',
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  final String email;

  const _SuccessContent({required this.email});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.success.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.mark_email_read_outlined, color: colors.success, size: 44),
        ),
        const SizedBox(height: 24),
        Text('Check Your Email', style: AppTextStyles.heading1(context), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          // Deliberately worded to be true and identical whether or not
          // "$email" actually has an account — never "we sent a link to
          // your account", which would confirm the account exists.
          'If an account exists for $email, we\'ve sent a link to reset '
          'your password. Check your inbox (and spam folder).',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted(context),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Back to Sign In',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
