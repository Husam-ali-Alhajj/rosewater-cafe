import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
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
        SnackBar(content: Text(AppLocalizations.of(context).genericConnectionError)),
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
                  // Sprint 8 Task 6: see sign_in_screen.dart for why this
                  // needs an explicit RTL check.
                  icon: Icon(
                    Directionality.of(context) == TextDirection.rtl ? Icons.arrow_forward : Icons.arrow_back,
                    color: colors.textPrimary,
                  ),
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
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const OnboardingIconBadge(icon: Icons.lock_outline),
          const SizedBox(height: 24),
          Text(l10n.forgotPassword, style: AppTextStyles.heading1(context)),
          const SizedBox(height: 8),
          Text(
            l10n.forgotPasswordSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted(context),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.emailAddressLabel,
              hintText: l10n.emailAddressHint,
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            validator: Validators.email,
          ),
          if (_requestError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                // AlignmentDirectional.centerStart, not physical
                // Alignment.centerLeft (Sprint 8 Task 6).
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _requestError!,
                  style: TextStyle(color: context.colors.danger, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 24),
          GradientButton(
            label: _isSubmitting ? l10n.sendingEllipsis : l10n.sendResetLink,
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
    final l10n = AppLocalizations.of(context);
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
        Text(l10n.checkYourEmail, style: AppTextStyles.heading1(context), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          // Deliberately worded to be true and identical whether or not
          // "$email" actually has an account — never "we sent a link to
          // your account", which would confirm the account exists.
          l10n.resetLinkSentBody(email),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted(context),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: l10n.backToSignIn,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
