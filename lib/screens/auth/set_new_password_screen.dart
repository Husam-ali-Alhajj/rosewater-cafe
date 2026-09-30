import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_client.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/onboarding_icon_badge.dart';
import 'sign_in_screen.dart';

/// Opened only by a password-reset email link (see auth_deep_link_listener.dart). There's no
/// current-password field: the link already proved it's the user.
///
/// On success we sign out, and the user signs in again with the new password.
class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = const AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  bool _succeeded = false;
  String? _serverPasswordError;
  String? _formError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (_serverPasswordError != null) return _serverPasswordError;
    return Validators.password(value);
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return AppLocalizations.of(context).passwordsDoNotMatch;
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    _serverPasswordError = null;
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.completePasswordRecovery(_passwordController.text);
      // End the recovery session so nothing stays signed in.
      try {
        await supabase.auth.signOut();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _succeeded = true;
      });
    } on SetNewPasswordFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        if (e.field == 'password') {
          _serverPasswordError = e.message;
        } else {
          _formError = e.message;
        }
      });
      if (e.field == 'password') _formKey.currentState!.validate();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _formError = AppLocalizations.of(context).couldNotUpdatePasswordError;
      });
    }
  }

  void _continueToSignIn() {
    Navigator.of(context).pushAndRemoveUntil(appRoute(context, (_) => const SignInScreen()), (route) => false);
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
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
              child: _succeeded ? _SuccessContent(onContinue: _continueToSignIn) : _buildForm(context),
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
          const OnboardingIconBadge(icon: Icons.lock_reset_outlined),
          const SizedBox(height: 24),
          Text(l10n.setNewPasswordHeading, style: AppTextStyles.heading1(context)),
          const SizedBox(height: 8),
          Text(l10n.chooseNewPasswordSubtitle, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted(context)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.newPasswordLabel,
              hintText: l10n.passwordHint,
              helperText: l10n.passwordHelperText,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: _validatePassword,
            enabled: !_isSubmitting,
            onChanged: (_) {
              if (_serverPasswordError != null) setState(() => _serverPasswordError = null);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: l10n.confirmNewPasswordLabel,
              hintText: l10n.passwordHint,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: _validateConfirm,
            enabled: !_isSubmitting,
          ),
          if (_formError != null) ...[
            const SizedBox(height: 16),
            Text(
              _formError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: _isSubmitting ? l10n.updatingEllipsis : l10n.updatePassword,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  final VoidCallback onContinue;

  const _SuccessContent({required this.onContinue});

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
          decoration: BoxDecoration(shape: BoxShape.circle, color: colors.success.withValues(alpha: 0.12)),
          child: Icon(Icons.check_circle_outline, color: colors.success, size: 44),
        ),
        const SizedBox(height: 24),
        Text(l10n.passwordUpdatedHeading, style: AppTextStyles.heading1(context), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(l10n.passwordUpdatedBody, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted(context)),
        const SizedBox(height: 24),
        GradientButton(label: l10n.continueToSignIn, onPressed: onContinue),
      ],
    );
  }
}
