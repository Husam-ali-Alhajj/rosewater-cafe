import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/account_deletion_service.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/settings_provider.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/form_buttons.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/setting_toggle_row.dart';
import '../auth/sign_out.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

// Sizes from the design; colours come from the theme so dark mode works (the delete red uses the
// theme's danger colour).

const _hairline = 0.515;

/// Privacy & Security: security options, password, email and privacy.
///
/// - Biometric login and Auto-Lock work. Biometric can only be turned on if the device supports it.
/// Two-factor authentication is a disabled placeholder.
/// - Change Password and Change Email ask for the current password first, so an unlocked phone
/// can't be used to change them. A new email only takes effect after the user clicks the
/// confirmation link sent to it.
/// - Delete Account asks for the password, deletes the user's stored files, then deletes the
/// account and all its data. There is no undo.
/// - Privacy Policy and Terms of Service open draft placeholder text.
class PrivacySecurityScreen extends StatefulWidget {
  final AuthService authService;
  final AccountDeletionService accountDeletionService;

  /// A parameter so tests can pass a fake.
  final BiometricService biometricService;

  /// Runs after the account is deleted (signs out by default). A parameter so tests can check it
  /// without Supabase.
  final Future<void> Function(BuildContext context)? onAccountDeleted;

  const PrivacySecurityScreen({
    super.key,
    this.authService = const AuthService(),
    this.accountDeletionService = const AccountDeletionService(),
    this.biometricService = const BiometricService(),
    this.onAccountDeleted,
  });

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _changingPassword = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _saving = false;
  String? _serverCurrentError;
  String? _serverNewError;
  String? _formError;

  final _deleteFormKey = GlobalKey<FormState>();
  final _deletePasswordController = TextEditingController();
  bool _deletingAccountForm = false;
  bool _showDeletePassword = false;
  bool _deletingAccount = false;
  String? _deletePasswordError;
  String? _deleteFormError;

  final _emailFormKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  bool _changingEmailForm = false;
  bool _showEmailPassword = false;
  bool _changingEmail = false;
  String? _emailFieldError;
  String? _emailPasswordError;
  String? _emailFormError;
  // Set right away so the "pending change" note shows immediately.
  String? _justRequestedEmail;

  @override
  void dispose() {
    // Clear the password fields when leaving.
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _deletePasswordController.dispose();
    _newEmailController.dispose();
    _emailPasswordController.dispose();
    super.dispose();
  }

  // Change Password

  void _openPasswordForm() => setState(() => _changingPassword = true);

  void _closePasswordForm() {
    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
    setState(() {
      _changingPassword = false;
      _showCurrent = _showNew = _showConfirm = false;
      _serverCurrentError = _serverNewError = _formError = null;
    });
  }

  String? _validateCurrent(String? value) {
    if (_serverCurrentError != null) return _serverCurrentError;
    if (value == null || value.isEmpty) return AppLocalizations.of(context).enterCurrentPasswordError;
    return null;
  }

  String? _validateNew(String? value) {
    if (_serverNewError != null) return _serverNewError;
    final rule = Validators.password(value);
    if (rule != null) return rule;
    if (value == _currentController.text) return AppLocalizations.of(context).passwordMustDifferError;
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _newController.text) return AppLocalizations.of(context).passwordsDoNotMatch;
    return null;
  }

  Future<void> _submitPassword() async {
    if (_saving) return;
    // Clear the last attempt's errors.
    _serverCurrentError = null;
    _serverNewError = null;
    setState(() => _formError = null);
    // Check the form first so invalid input never reaches the server.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await widget.authService.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _closePasswordForm();
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordUpdatedMessage)));
    } on ChangePasswordFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.field == 'current') {
          _serverCurrentError = e.message;
        } else if (e.field == 'new') {
          _serverNewError = e.message;
        } else {
          _formError = e.message;
        }
      });
      if (e.field != null) _formKey.currentState!.validate();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = AppLocalizations.of(context).couldntUpdatePasswordError;
      });
    }
  }

  // Delete Account

  void _openDeleteForm() => setState(() => _deletingAccountForm = true);

  void _closeDeleteForm() {
    _deletePasswordController.clear();
    setState(() {
      _deletingAccountForm = false;
      _showDeletePassword = false;
      _deletePasswordError = null;
      _deleteFormError = null;
    });
  }

  String? _validateDeletePassword(String? value) {
    if (_deletePasswordError != null) return _deletePasswordError;
    if (value == null || value.isEmpty) return AppLocalizations.of(context).enterCurrentPasswordError;
    return null;
  }

  Future<void> _submitDeleteAccount() async {
    if (_deletingAccount) return;
    // Clear the last attempt's error.
    _deletePasswordError = null;
    setState(() => _deleteFormError = null);
    // Don't send an empty password.
    if (!_deleteFormKey.currentState!.validate()) return;

    setState(() => _deletingAccount = true);
    try {
      await widget.accountDeletionService.deleteAccount(currentPassword: _deletePasswordController.text);
      if (!mounted) return;
      // The account is gone, so sign out locally too.
      if (widget.onAccountDeleted != null) {
        await widget.onAccountDeleted!(context);
      } else {
        await signOutAndShowLanding(context);
      }
    } on DeleteAccountFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _deletingAccount = false;
        if (e.field == 'password') {
          _deletePasswordError = e.message;
        } else {
          _deleteFormError = e.message;
        }
      });
      if (e.field == 'password') _deleteFormKey.currentState!.validate();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deletingAccount = false;
        _deleteFormError = AppLocalizations.of(context).couldntDeleteAccountError;
      });
    }
  }

  // Change Email

  void _openEmailForm() => setState(() => _changingEmailForm = true);

  void _closeEmailForm() {
    _newEmailController.clear();
    _emailPasswordController.clear();
    setState(() {
      _changingEmailForm = false;
      _showEmailPassword = false;
      _emailFieldError = null;
      _emailPasswordError = null;
      _emailFormError = null;
    });
  }

  String? _validateNewEmail(String? value) {
    if (_emailFieldError != null) return _emailFieldError;
    return Validators.email(value);
  }

  String? _validateEmailPassword(String? value) {
    if (_emailPasswordError != null) return _emailPasswordError;
    if (value == null || value.isEmpty) return AppLocalizations.of(context).enterCurrentPasswordError;
    return null;
  }

  Future<void> _submitChangeEmail() async {
    if (_changingEmail) return;
    // Clear the last attempt's errors.
    _emailFieldError = null;
    _emailPasswordError = null;
    setState(() => _emailFormError = null);
    // Check the form first so invalid input never reaches the server.
    if (!_emailFormKey.currentState!.validate()) return;

    final newEmail = _newEmailController.text.trim();
    setState(() => _changingEmail = true);
    try {
      await widget.authService.changeEmail(currentPassword: _emailPasswordController.text, newEmail: newEmail);
      if (!mounted) return;
      _newEmailController.clear();
      _emailPasswordController.clear();
      setState(() {
        _changingEmail = false;
        _changingEmailForm = false;
        _showEmailPassword = false;
        _justRequestedEmail = newEmail;
      });
    } on ChangeEmailFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _changingEmail = false;
        if (e.field == 'password') {
          _emailPasswordError = e.message;
        } else if (e.field == 'email') {
          _emailFieldError = e.message;
        } else {
          _emailFormError = e.message;
        }
      });
      if (e.field != null) _emailFormKey.currentState!.validate();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _changingEmail = false;
        _emailFormError = AppLocalizations.of(context).couldntUpdateEmailError;
      });
    }
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(appRoute(context, (_) => const PrivacyPolicyScreen()));
  }

  void _openTermsOfService() {
    Navigator.of(context).push(appRoute(context, (_) => const TermsOfServiceScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.colors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: l10n.privacySecurityLabel, onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                _SecurityOptionsCard(biometricService: widget.biometricService),
                const SizedBox(height: 24),
                _SectionCard(
                  title: l10n.passwordSectionTitle,
                  child: _changingPassword ? _buildPasswordForm() : _buildPasswordPrompt(),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: l10n.emailSectionTitle,
                  child: _changingEmailForm ? _buildEmailForm() : _buildEmailPrompt(),
                ),
                const SizedBox(height: 24),
                _SectionCard(title: l10n.privacySectionTitle, child: _buildPrivacyRows()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordPrompt() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.strongPasswordPrompt,
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
          ),
          const SizedBox(height: 16),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colors.border, width: _hairline),
            ),
            child: InkWell(
              onTap: _openPasswordForm,
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: colors.textPrimary),
                    const SizedBox(width: 17),
                    Text(
                      l10n.changePasswordButton,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PasswordField(
              label: l10n.currentPasswordLabel,
              hint: l10n.enterCurrentPasswordHint,
              controller: _currentController,
              visible: _showCurrent,
              onToggleVisible: () => setState(() => _showCurrent = !_showCurrent),
              validator: _validateCurrent,
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            _PasswordField(
              label: l10n.newPasswordLabel,
              hint: l10n.enterNewPasswordHint,
              controller: _newController,
              visible: _showNew,
              onToggleVisible: () => setState(() => _showNew = !_showNew),
              validator: _validateNew,
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            _PasswordField(
              label: l10n.confirmNewPasswordLabel,
              hint: l10n.confirmNewPasswordHint,
              controller: _confirmController,
              visible: _showConfirm,
              onToggleVisible: () => setState(() => _showConfirm = !_showConfirm),
              validator: _validateConfirm,
              enabled: !_saving,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CancelButton(label: l10n.cancelButton, onTap: _saving ? null : _closePasswordForm),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SaveButton(
                    label: l10n.updatePasswordButton,
                    savingLabel: l10n.updatingEllipsis,
                    saving: _saving,
                    onTap: _saving ? null : _submitPassword,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailPrompt() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final currentEmail = widget.authService.currentUserEmail ?? '';
    final pendingEmail = _justRequestedEmail ?? widget.authService.pendingEmailChange;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            currentEmail,
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textPrimary),
          ),
          if (pendingEmail != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.confirmationSentToEmail(pendingEmail),
              style: TextStyle(fontSize: 12, height: 16 / 12, color: colors.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colors.border, width: _hairline),
            ),
            child: InkWell(
              onTap: _openEmailForm,
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline, size: 16, color: colors.textPrimary),
                    const SizedBox(width: 17),
                    Text(
                      l10n.changeEmailButton,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.newEmailFormInstructions,
              style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.newEmailAddressLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.15,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              validator: _validateNewEmail,
              enabled: !_changingEmail,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(hintText: 'your.new.email@example.com'),
              onChanged: (_) {
                if (_emailFieldError != null) setState(() => _emailFieldError = null);
              },
            ),
            const SizedBox(height: 24),
            _PasswordField(
              label: l10n.currentPasswordLabel,
              hint: l10n.enterCurrentPasswordHint,
              controller: _emailPasswordController,
              visible: _showEmailPassword,
              onToggleVisible: () => setState(() => _showEmailPassword = !_showEmailPassword),
              validator: _validateEmailPassword,
              enabled: !_changingEmail,
            ),
            if (_emailFormError != null) ...[
              const SizedBox(height: 16),
              Text(
                _emailFormError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CancelButton(label: l10n.cancelButton, onTap: _changingEmail ? null : _closeEmailForm),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SaveButton(
                    label: l10n.sendConfirmationButton,
                    savingLabel: l10n.sendingEllipsis,
                    saving: _changingEmail,
                    onTap: _changingEmail ? null : _submitChangeEmail,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyRows() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrivacyRow(label: l10n.viewPrivacyPolicyLabel, onTap: _openPrivacyPolicy),
          const SizedBox(height: 12),
          _PrivacyRow(label: l10n.termsOfService, onTap: _openTermsOfService),
          const SizedBox(height: 12),
          if (_deletingAccountForm)
            _buildDeleteAccountForm()
          else
            _PrivacyRow(label: l10n.deleteAccountLabel, danger: true, onTap: _openDeleteForm),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountForm() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _deleteFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deleteAccountWarning,
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
          ),
          const SizedBox(height: 16),
          _PasswordField(
            label: l10n.currentPasswordLabel,
            hint: l10n.enterCurrentPasswordHint,
            controller: _deletePasswordController,
            visible: _showDeletePassword,
            onToggleVisible: () => setState(() => _showDeletePassword = !_showDeletePassword),
            validator: _validateDeletePassword,
            enabled: !_deletingAccount,
          ),
          if (_deleteFormError != null) ...[
            const SizedBox(height: 16),
            Text(
              _deleteFormError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CancelButton(label: l10n.cancelButton, onTap: _deletingAccount ? null : _closeDeleteForm),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DangerButton(
                  label: l10n.deletePermanentlyButton,
                  savingLabel: l10n.deletingEllipsis,
                  saving: _deletingAccount,
                  onTap: _deletingAccount ? null : _submitDeleteAccount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A card with a title and a thin divider, used for the Password and Privacy sections.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border, width: _hairline),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 28 / 18,
                letterSpacing: -0.44,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

/// The "Security Options" card: gradient header, then the three switches.
class _SecurityOptionsCard extends StatefulWidget {
  final BiometricService biometricService;

  const _SecurityOptionsCard({this.biometricService = const BiometricService()});

  @override
  State<_SecurityOptionsCard> createState() => _SecurityOptionsCardState();
}

class _SecurityOptionsCardState extends State<_SecurityOptionsCard> {
  bool _checkingBiometric = false;

  Future<void> _toggleBiometric(SettingsProvider settings) async {
    if (_checkingBiometric) return;
    if (settings.biometricEnabled) {
      // Turning it off never needs a device check.
      await settings.setBiometricEnabled(false);
      return;
    }
    setState(() => _checkingBiometric = true);
    final available = await widget.biometricService.isAvailable();
    if (!mounted) return;
    setState(() => _checkingBiometric = false);
    if (!available) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).noBiometricsAvailableError)));
      return;
    }
    await settings.setBiometricEnabled(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    // Watches the settings so the switches update right away.
    final settings = context.watch<SettingsProvider>();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: colors.accentGradient),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  l10n.securityOptionsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
                    letterSpacing: -0.44,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SettingToggleRow(
            icon: Icons.fingerprint,
            iconSize: 20,
            label: l10n.biometricAuthLabel,
            description: l10n.biometricAuthDescription,
            value: settings.biometricEnabled,
            onToggle: _checkingBiometric ? null : () => _toggleBiometric(settings),
            showDivider: true,
            switchKey: const ValueKey('biometric-authentication'),
          ),
          const SizedBox(height: 24),
          SettingToggleRow(
            icon: Icons.smartphone_outlined,
            iconSize: 20,
            label: l10n.twoFactorAuthLabel,
            description: l10n.twoFactorAuthDescription,
            value: false,
            onToggle: null,
            showDivider: true,
            note: l10n.comingSoonNote,
            switchKey: const ValueKey('placeholder-two-factor'),
          ),
          const SizedBox(height: 24),
          SettingToggleRow(
            icon: Icons.lock_outline,
            iconSize: 20,
            label: l10n.autoLockLabel,
            description: l10n.autoLockDescription,
            value: settings.autoLockEnabled,
            onToggle: () => settings.setAutoLockEnabled(!settings.autoLockEnabled),
            showDivider: false,
            switchKey: const ValueKey('auto-lock'),
          ),
        ],
      ),
    );
  }
}

/// A password field with a show/hide button.
class _PasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggleVisible;
  final String? Function(String?) validator;
  final bool enabled;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.visible,
    required this.onToggleVisible,
    required this.validator,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const textStyle = TextStyle(fontSize: 16, height: 19 / 16, letterSpacing: -0.31);
    OutlineInputBorder border([Color? color]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: color == null ? BorderSide.none : BorderSide(color: color),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1,
            letterSpacing: -0.15,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextFormField(
              controller: controller,
              validator: validator,
              enabled: enabled,
              obscureText: !visible,
              // No suggestions or autocorrect for passwords.
              enableSuggestions: false,
              autocorrect: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: textStyle.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colors.inputFill,
                hintText: hint,
                hintStyle: textStyle.copyWith(color: colors.textMuted),
                // The eye icon is drawn by hand, so its padding has to flip for right-to-left.
                contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 8.5, 44, 8.5),
                border: border(),
                enabledBorder: border(),
                disabledBorder: border(),
                focusedBorder: border(),
                errorBorder: border(colors.danger),
                focusedErrorBorder: border(colors.danger),
                errorStyle: TextStyle(fontSize: 12, color: colors.danger),
              ),
            ),
            PositionedDirectional(
              end: 12,
              top: 10,
              child: Tooltip(
                message: visible
                    ? AppLocalizations.of(context).hidePasswordTooltip
                    : AppLocalizations.of(context).showPasswordTooltip,
                child: InkWell(
                  onTap: enabled ? onToggleVisible : null,
                  customBorder: const CircleBorder(),
                  child: Icon(
                    visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Solid red button for the irreversible delete, so it doesn't look like a normal save.
class _DangerButton extends StatelessWidget {
  final String label;
  final String savingLabel;
  final bool saving;
  final VoidCallback? onTap;

  const _DangerButton({required this.label, required this.saving, required this.onTap, this.savingLabel = 'Saving…'});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: context.colors.danger, borderRadius: BorderRadius.circular(8)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                saving ? savingLabel : label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable text row. "Delete Account" is shown in red.
class _PrivacyRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  const _PrivacyRow({required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                letterSpacing: -0.15,
                color: danger ? colors.danger : colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
