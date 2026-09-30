import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_logo.dart';
import '../membership/choose_membership_screen.dart';
import 'confirm_email_pending_screen.dart';
import 'sign_in_screen.dart';

/// Creates the account (a database trigger also creates the profile row), then goes to Choose
/// Membership.
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

  // Same rule as Edit Profile.
  String? _validatePhone(String? value) => Validators.phone(value);

  // Same rule as Change Password.
  String? _validatePassword(String? value) {
    if (_serverPasswordError != null) return _serverPasswordError;
    return Validators.password(value);
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return AppLocalizations.of(context).passwordsDoNotMatch;
    return null;
  }

  Future<void> _submit() async {
    // Stops a quick double-tap from signing up twice.
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
      // Email confirmation is on: the account exists but has no session yet, so show "check your
      // email" instead.
      Navigator.of(context).pushReplacement(
        appRoute(context, (_) => hasSession ? const ChooseMembershipScreen() : ConfirmEmailPendingScreen(email: email)),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      // Network errors and the like; otherwise the button would stay on "Creating account..."
      // forever.
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).genericConnectionError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
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
                  // The back arrow has to point the other way in right-to-left.
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
                        const AppLogo(height: 72),
                        const SizedBox(height: 24),
                        Text(l10n.createAccountHeading, style: AppTextStyles.heading1(context)),
                        const SizedBox(height: 8),
                        Text(l10n.joinToday, style: AppTextStyles.bodyMuted(context)),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.fullNameLabel,
                            hintText: l10n.fullNameHint,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: _validateFullName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.emailAddressLabel,
                            hintText: l10n.emailAddressHint,
                            prefixIcon: const Icon(Icons.mail_outline),
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
                          decoration: InputDecoration(
                            labelText: l10n.phoneNumberLabel,
                            hintText: l10n.phoneNumberHint,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                            hintText: l10n.passwordHint,
                            helperText: l10n.passwordHelperText,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                            labelText: l10n.confirmPasswordLabel,
                            hintText: l10n.passwordHint,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                                      TextSpan(text: l10n.agreeToTermsPrefix),
                                      TextSpan(
                                        text: l10n.termsOfService,
                                        style: TextStyle(color: colors.accent),
                                      ),
                                      TextSpan(text: l10n.agreeToTermsAnd),
                                      TextSpan(
                                        text: l10n.privacyPolicy,
                                        style: TextStyle(color: colors.accent),
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
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                l10n.mustAgreeToContinue,
                                style: TextStyle(color: colors.danger, fontSize: 12),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        GradientButton(
                          label: _isSubmitting ? l10n.creatingAccount : l10n.createAccount,
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l10n.alreadyHaveAccount, style: AppTextStyles.bodyMuted(context)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushReplacement(appRoute(context, (_) => const SignInScreen())),
                              child: Text(
                                l10n.signInButton,
                                style: TextStyle(color: colors.accent, fontWeight: FontWeight.w600),
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
