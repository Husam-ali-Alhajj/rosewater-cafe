import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/onboarding_icon_badge.dart';
import '../membership/choose_membership_screen.dart';
import 'confirm_email_pending_screen.dart';
import 'sign_in_screen.dart';

/// Real signup: creates the auth.users row (and, via the handle_new_user
/// trigger, the matching profiles row) then routes to Choose Membership.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = const AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _showTermsError = false;
  bool _isSubmitting = false;
  String? _serverEmailError;
  String? _serverPasswordError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) => Validators.fullName(value);

  String? _validateEmail(String? value) {
    if (_serverEmailError != null) return _serverEmailError;
    return Validators.email(value);
  }

  // Decision #10's rule, shared with Edit Profile via Validators.phone.
  String? _validatePhone(String? value) => Validators.phone(value);

  // Decision #10's rule, shared with Change Password via Validators.password.
  String? _validatePassword(String? value) {
    if (_serverPasswordError != null) return _serverPasswordError;
    return Validators.password(value);
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    // Re-entry guard: without this, a rapid double-tap can invoke _submit()
    // twice before the button's onPressed is rebuilt to null on the next
    // frame — the closure captured at the last build is still the old
    // (enabled) one, so the second tap would fire a second, concurrent
    // signUp() call with identical data. This check is synchronous and runs
    // before any `await`, so the second call always sees the flag the first
    // call already set.
    if (_isSubmitting) return;

    final formOk = _formKey.currentState!.validate();
    final termsOk = _agreedToTerms;
    if (!termsOk) setState(() => _showTermsError = true);
    if (!formOk || !termsOk) return;

    setState(() {
      _isSubmitting = true;
      _serverEmailError = null;
      _serverPasswordError = null;
    });

    try {
      final email = _emailController.text.trim();
      final hasSession = await _authService.signUp(
        fullName: _fullNameController.text.trim(),
        email: email,
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // If the project requires email confirmation, signUp() succeeds but
      // returns no session yet — the account exists but isn't usable until
      // the confirmation link is clicked. Routing to Choose Membership here
      // would push an unauthenticated user into a screen that assumes
      // they're logged in, so show a "check your email" state instead.
      Navigator.of(context).pushReplacement(
        appRoute(
          context,
          (_) => hasSession
              ? const ChooseMembershipScreen()
              : ConfirmEmailPendingScreen(email: email),
        ),
      );
    } on SignUpFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _serverEmailError = e.field == 'email' ? e.message : null;
        _serverPasswordError = e.field == 'password' ? e.message : null;
      });
      if (e.field == 'email' || e.field == 'password') {
        _formKey.currentState!.validate();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      // Anything that isn't our own SignUpFailure — a dropped connection,
      // a timeout, DNS failure, etc. Without this, an unhandled exception
      // here just leaves the button stuck on "Creating account…" forever
      // with no feedback, which reads as a hang/crash to the user.
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Check your connection and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.pageBackgroundGradient,
        ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const OnboardingIconBadge(icon: Icons.person),
                        const SizedBox(height: 24),
                        Text('Create Account', style: AppTextStyles.heading1(context)),
                        const SizedBox(height: 8),
                        Text(
                          'Join Rosewater Café today',
                          style: AppTextStyles.bodyMuted(context),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'John Doe',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _validateFullName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'your@email.com',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: _validateEmail,
                          onChanged: (_) {
                            if (_serverEmailError != null) {
                              setState(() => _serverEmailError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '+1 (555) 000-0000',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            helperText:
                                '8+ characters, with uppercase, lowercase & a number',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                          onChanged: (_) {
                            if (_serverPasswordError != null) {
                              setState(() => _serverPasswordError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                          ),
                          validator: _validateConfirmPassword,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) => setState(() {
                                _agreedToTerms = value ?? false;
                                if (_agreedToTerms) _showTermsError = false;
                              }),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.bodyMuted(context),
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: colors.accent,
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: colors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_showTermsError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'You must agree to continue',
                                style: TextStyle(
                                  color: colors.danger,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        GradientButton(
                          label: _isSubmitting
                              ? 'Creating account…'
                              : 'Create Account',
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTextStyles.bodyMuted(context),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushReplacement(
                                    appRoute(
                                      context,
                                      (_) => const SignInScreen(),
                                    ),
                                  ),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
