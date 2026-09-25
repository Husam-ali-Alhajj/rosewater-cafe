import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/remember_me_prefs.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/app_feedback.dart';
import '../../utils/validators.dart';
import '../../widgets/app_page_route.dart';
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
  // "Remember me" is real (decision #56): checked (the default -- see
  // RememberMePrefs) behaves exactly as decision #15 always did, a
  // signed-in mobile app stays signed in. Unchecked forces a sign-out on
  // the NEXT cold app start, checked by AppEntryPoint -- not here, and not
  // "on close", since a mobile OS can kill a process with no callback to
  // act on. Loaded from the last-stored value in initState so the checkbox
  // itself remembers what was last chosen, same as the behavior it drives.
  bool _rememberMe = true;
  bool _isSubmitting = false;
  String? _credentialsError;

  @override
  void initState() {
    super.initState();
    const RememberMePrefs().isRemembered().then((remembered) {
      if (mounted) setState(() => _rememberMe = remembered);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) => Validators.email(value);

  // A local validator (not shared `Validators`, which has no BuildContext
  // access) -- localizable right here via `this.context`, a State's own
  // instance member, without changing that shared utility's signature.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context).passwordRequired;
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
      // Only stored once a session actually exists -- there's nothing to
      // remember (or not) about a sign-in attempt that failed.
      await const RememberMePrefs().setRemembered(_rememberMe);
      final hasActive = await _subscriptionService.hasActiveSubscription();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        appRoute(
          context,
          (_) => hasActive ? const MainShell() : const ChooseMembershipScreen(),
        ),
      );
    } on SignInFailure catch (e) {
      if (!mounted) return;
      context.triggerError(); // Sprint 8 Task 4: failed sign-in
      setState(() {
        _isSubmitting = false;
        _credentialsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      context.triggerError();
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signInGenericError)),
      );
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
                  // Sprint 8 Task 6 (decision #63): a "back" arrow is
                  // directional -- it needs to point toward where "back"
                  // actually leads, which is the opposite screen edge in
                  // RTL. Icons.arrow_back doesn't auto-mirror (it's not one
                  // of the codepoints Flutter's own bidi icon-mirroring
                  // covers), so this checks Directionality explicitly.
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const OnboardingIconBadge(icon: Icons.lock),
                        const SizedBox(height: 24),
                        Text(l10n.welcomeBack, style: AppTextStyles.heading1(context)),
                        const SizedBox(height: 8),
                        Text(l10n.signInSubtitle, style: AppTextStyles.bodyMuted(context)),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.emailAddressLabel,
                            hintText: l10n.emailAddressHint,
                            prefixIcon: const Icon(Icons.mail_outline),
                          ),
                          validator: _validateEmail,
                          onChanged: (_) => _clearCredentialsError(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                            hintText: l10n.passwordHint,
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
                            Text(l10n.rememberMe, style: AppTextStyles.bodyMuted(context)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                appRoute(
                                  context,
                                  (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              child: Text(
                                l10n.forgotPassword,
                                style: TextStyle(color: colors.accent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        if (_credentialsError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Align(
                              // Sprint 8 Task 6: `AlignmentDirectional.centerStart`,
                              // not the physical `Alignment.centerLeft` --
                              // this error text needs to hug the START edge
                              // (right, in RTL), not always the left.
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                _credentialsError!,
                                style: TextStyle(color: colors.danger, fontSize: 12),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        GradientButton(
                          label: _isSubmitting ? l10n.signingIn : l10n.signInButton,
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l10n.noAccountPrompt, style: AppTextStyles.bodyMuted(context)),
                            // A SizedBox gap, not a trailing space baked
                            // into `noAccountPrompt` -- a translated string
                            // shouldn't have to carry layout spacing inside
                            // it (Sprint 8 Task 6).
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pushReplacement(
                                appRoute(context, (_) => const CreateAccountScreen()),
                              ),
                              child: Text(
                                l10n.createAccount,
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
