import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/gradient_button.dart';
import '../home/main_shell.dart';
import '../membership/choose_membership_screen.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import '../../widgets/onboarding_icon_badge.dart';

/// Real sign-in: supabase.auth.signInWithPassword, then routes based on
/// subscription state — Home if the user has an active subscription,
/// Choose Membership if they signed up but never completed payment.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = const AuthService();
  final _subscriptionService = const SubscriptionService();

  bool _obscurePassword = true;
  // "Remember me" is decorative for now — Supabase's session persists
  // on-device (via our SecureLocalStorage) regardless of this checkbox,
  // which matches normal mobile-app expectations (unlike a browser, a
  // signed-in mobile app staying signed in is the default users expect).
  // Logged as a deliberate decision in docs/decisions.md rather than left
  // unexplained — if a real distinction is ever wanted (e.g. force
  // sign-out on app restart when unchecked), that needs its own design,
  // since mobile OSes can kill an app without any "on close" callback
  // firing to act on.
  bool _rememberMe = true;
  bool _isSubmitting = false;
  String? _credentialsError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) => Validators.email(value);

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  void _clearCredentialsError() {
    if (_credentialsError != null) setState(() => _credentialsError = null);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // same re-entry guard as Create Account
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _credentialsError = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final hasActive = await _subscriptionService.hasActiveSubscription();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => hasActive ? const MainShell() : const ChooseMembershipScreen(),
        ),
      );
    } on SignInFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _credentialsError = e.message;
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const OnboardingIconBadge(
                          icon: Icons.lock,
                          gradient: AppColors.primaryGradient,
                        ),
                        const SizedBox(height: 24),
                        Text('Welcome Back', style: AppTextStyles.heading1),
                        const SizedBox(height: 8),
                        Text('Sign in to your account', style: AppTextStyles.bodyMuted),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'your@email.com',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: _validateEmail,
                          onChanged: (_) => _clearCredentialsError(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: _validatePassword,
                          onChanged: (_) => _clearCredentialsError(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) => setState(() => _rememberMe = value ?? true),
                            ),
                            Text('Remember me', style: AppTextStyles.bodyMuted),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        if (_credentialsError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _credentialsError!,
                                style: TextStyle(color: AppColors.danger, fontSize: 12),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        GradientButton(
                          label: _isSubmitting ? 'Signing in…' : 'Sign In',
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: AppTextStyles.bodyMuted),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
                              ),
                              child: Text(
                                'Create Account',
                                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
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
