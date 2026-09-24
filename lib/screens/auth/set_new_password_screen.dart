import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/onboarding_icon_badge.dart';
import 'sign_in_screen.dart';

/// The screen Forgot Password was always missing a second half for
/// (decision #55): reached ONLY by `auth_deep_link_listener.dart`, the
/// moment Supabase fires `AuthChangeEvent.passwordRecovery` because a real
/// password-recovery email link was just opened. There's no button anywhere
/// in the app that navigates here on purpose -- landing on this screen IS
/// the proof a real recovery link worked.
///
/// Same shape as [ForgotPasswordScreen]: a card on the gradient background,
/// a form that swaps to a success view once it succeeds. Same password
/// rules as signup ([Validators.password], decision #10) -- there's no
/// "current password" field, because the whole point of this flow is the
/// user doesn't remember it; the recovery link itself already proved this
/// is really them.
///
/// On success, the recovery session is ended (`signOut`) and the success
/// view's button sends the user to [SignInScreen] to sign in fresh with the
/// new password -- chosen over silently continuing on the recovery session,
/// so "did it actually work?" gets answered by an explicit, ordinary sign-in
/// rather than assumed.
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
    return Validators.password(value); // decision #10, same as signup
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // same re-entry guard as every other auth form
    _serverPasswordError = null;
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.completePasswordRecovery(_passwordController.text);
      // The recovery session has done its one job -- end it so nothing is
      // left silently signed in if the user never taps through to Sign In.
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
        _formError = "Couldn't update your password. Check your connection and try again.";
      });
    }
  }

  void _continueToSignIn() {
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false);
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const OnboardingIconBadge(icon: Icons.lock_reset_outlined, gradient: AppColors.primaryGradient),
          const SizedBox(height: 24),
          Text('Set New Password', style: AppTextStyles.heading1(context)),
          const SizedBox(height: 8),
          Text(
            'Choose a new password for your account.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted(context),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: '••••••••',
              helperText: '8+ characters, with uppercase, lowercase & a number',
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
              labelText: 'Confirm New Password',
              hintText: '••••••••',
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
            Text(_formError!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.danger, fontSize: 12)),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: _isSubmitting ? 'Updating…' : 'Update Password',
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
        Text('Password Updated', style: AppTextStyles.heading1(context), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          "Your password has been changed. Please sign in with your new password.",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted(context),
        ),
        const SizedBox(height: 24),
        GradientButton(label: 'Continue to Sign In', onPressed: onContinue),
      ],
    );
  }
}
