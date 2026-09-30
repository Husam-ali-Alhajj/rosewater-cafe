import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_semantic_colors.dart';

/// Sprint 8 Task 5's lock screen -- shown by [AppLockGate] over whatever
/// screen the app was on, blocking it until the user actually unlocks.
///
/// If Biometric Authentication is on and the device supports it, a
/// biometric prompt fires automatically the moment this screen appears
/// (and again on "Try Again"). "Use Password Instead" is always visible
/// too, never hidden behind a failed biometric attempt first -- the
/// acceptance criterion is that a device/user without working biometrics
/// has a real path forward, not a dead end.
class AppLockScreen extends StatefulWidget {
  final bool biometricEnabled;
  final BiometricService biometricService;
  final AuthService authService;
  final VoidCallback onUnlocked;

  const AppLockScreen({
    super.key,
    required this.biometricEnabled,
    required this.onUnlocked,
    this.biometricService = const BiometricService(),
    this.authService = const AuthService(),
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _passwordController = TextEditingController();
  bool _showPasswordField = false;
  bool _showPassword = false;
  bool _biometricInFlight = false;
  bool _verifyingPassword = false;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    if (widget.biometricEnabled) {
      // Fire once the first frame is up, not from initState directly --
      // showing a native biometric prompt before this screen has actually
      // painted anything looks broken on some devices.
      WidgetsBinding.instance.addPostFrameCallback((_) => _attemptBiometric());
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _attemptBiometric() async {
    if (_biometricInFlight || !mounted) return;
    setState(() => _biometricInFlight = true);
    final ok = await widget.biometricService.authenticate(
      reason: AppLocalizations.of(context).unlockReasonPrompt,
    );
    if (!mounted) return;
    setState(() => _biometricInFlight = false);
    if (ok) widget.onUnlocked();
    // A failed/cancelled attempt just leaves the lock screen up -- "Try
    // Again" and "Use Password Instead" are both always visible, not
    // revealed only after a failure.
  }

  Future<void> _submitPassword() async {
    if (_verifyingPassword) return;
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = AppLocalizations.of(context).enterYourPasswordError);
      return;
    }
    setState(() {
      _verifyingPassword = true;
      _passwordError = null;
    });
    try {
      await widget.authService.verifyCurrentPassword(password);
      if (!mounted) return;
      _passwordController.clear();
      widget.onUnlocked();
    } on ReauthenticationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _verifyingPassword = false;
        _passwordError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifyingPassword = false;
        _passwordError = AppLocalizations.of(context).couldntVerifyPasswordError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Material(
      // A screen unto itself, not a dialog -- fully opaque, no way to see
      // or interact with whatever's underneath until unlocked.
      color: colors.surface,
      child: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(gradient: colors.accentGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.lock_outline, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appLockedTitle,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.biometricEnabled ? l10n.unlockWithBiometricPrompt : l10n.unlockWithPasswordPrompt,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  if (widget.biometricEnabled && !_showPasswordField) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _biometricInFlight ? null : _attemptBiometric,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(_biometricInFlight ? l10n.checkingEllipsis : l10n.tryAgainBiometricButton),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _showPasswordField = true),
                      child: Text(l10n.usePasswordInsteadButton),
                    ),
                  ] else ...[
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      autofocus: !widget.biometricEnabled,
                      enabled: !_verifyingPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      onSubmitted: (_) => _submitPassword(),
                      decoration: InputDecoration(
                        labelText: l10n.passwordFieldLabel,
                        errorText: _passwordError,
                        filled: true,
                        fillColor: colors.inputFill,
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _verifyingPassword ? null : _submitPassword,
                        child: Text(_verifyingPassword ? l10n.verifyingEllipsis : l10n.unlockButton),
                      ),
                    ),
                    if (widget.biometricEnabled) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _verifyingPassword
                            ? null
                            : () => setState(() {
                                  _showPasswordField = false;
                                  _passwordError = null;
                                  _passwordController.clear();
                                }),
                        child: Text(l10n.useBiometricInsteadButton),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
