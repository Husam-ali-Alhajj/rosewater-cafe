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
import '../../widgets/coming_soon_screen.dart';
import '../../widgets/form_buttons.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/setting_toggle_row.dart';
import '../auth/sign_out.dart';

// Values read from the Figma `PrivacySecurityScreen` frames (nodes 1217:2644
// default, 1217:2946 with the password form open) in the Figma app's Design
// panel -- the REST API was rate-limited when this was built, so a few spacing
// values not read directly are derived from the shared card/row pattern and
// the frames' measured heights (see docs/decisions.md #45).
//
// Sprint 8 Task 2 (dark mode rebuild): all of these were fixed light-mode
// neutrals; they now come from `context.colors` instead (`_deleteInk` maps
// onto `colors.danger`, the semantic token already re-picked per brightness
// to clear AA contrast -- not a generic color, the correct one for "this is
// destructive" in either theme).

const _hairline = 0.515; // Figma's fractional hairline stroke width

/// Privacy & Security (Figma frames 1217:2644 / 1217:2946): Security Options,
/// Password, and Privacy.
///
/// **Biometric Authentication and Auto-Lock are real** (Sprint 8 Task 5,
/// decision #62). Auto-Lock reads/writes `SettingsProvider.autoLockEnabled`;
/// [AppLockGate] (mounted once, above `MaterialApp` in `main.dart`) is what
/// actually tracks elapsed background time and shows the lock screen on
/// resume -- this row is just the switch. Biometric Authentication checks
/// [BiometricService.isAvailable] before it's allowed to turn on at all
/// ("fail gracefully... rather than a toggle that silently does nothing");
/// turning it off never needs that check. **Two-Factor Authentication stays
/// a disabled placeholder** (decision #45) -- a separate later task, not
/// this one.
///
/// **Change Password is real.** It asks for the CURRENT password first and
/// re-authenticates with it before anything is changed (see
/// [AuthService.changePassword]) -- Supabase's API doesn't require that, but a
/// phone left unlocked shouldn't let anyone silently change the password. The
/// new password must pass decision #10's rules, [Validators.password], the
/// same as signup.
///
/// **Delete Account is real, immediate, self-service deletion** (decision #52,
/// replacing the request-queue of decision #45 after the user was shown that
/// tradeoff and explicitly chose self-service instead; hardened afterwards to
/// require the current password and clean up storage first). Tapping the row
/// opens an inline form -- the same expand-in-place pattern Change Password
/// already uses on this screen -- asking for the CURRENT password before
/// anything happens. Confirming calls [AccountDeletionService.deleteAccount],
/// which re-verifies that password, removes every file the user ever stored
/// (avatars + ID documents), and only then deletes the account itself via the
/// `delete_own_account` RPC -- cascading through every table of their data.
/// This screen then ends the local session and returns to Auth Landing. There
/// is no undo, and the form says so before anything happens.
///
/// **Change Email is real** (decision #57). Same expand-in-place pattern and
/// password re-check as Change Password. Requesting a change only ever
/// starts it: Supabase emails a confirmation link to the NEW address, and
/// the current email keeps signing in the whole time -- there's nothing
/// else for this screen to do once the request succeeds, since the actual
/// `auth.users.email` change (and `profiles.email` following it, via the
/// new sync trigger) happens server-side when that link is clicked, whether
/// or not this screen -- or even this device -- is still open. Reads the
/// current/pending email via [AuthService.currentUserEmail] /
/// [AuthService.pendingEmailChange] (the real auth state) rather than the
/// `profiles` row, which only ever reflects a confirmed value.
///
/// "View Privacy Policy" and "Terms of Service" open a "coming soon" page:
/// no policy or terms text exists yet to show.
class PrivacySecurityScreen extends StatefulWidget {
  final AuthService authService;
  final AccountDeletionService accountDeletionService;

  /// Passed straight through to `_SecurityOptionsCard` -- private to this
  /// file, so a test can't construct it directly and inject a fake here
  /// instead, the same shape as [authService]/[accountDeletionService].
  final BiometricService biometricService;

  /// What runs right after the account is deleted server-side. Defaults to
  /// [signOutAndShowLanding] -- the real thing, which needs a live Supabase
  /// client. Overridable so this can be proven without one (widget tests
  /// can't initialise Supabase): a test passes a spy here to confirm this
  /// step would run, the same pattern AppSettingsScreen's onDataCleared
  /// uses for "Clear All App Data".
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
  // Set right after a successful request so the pending notice shows
  // immediately, without waiting on a fresh `currentUser` read -- Supabase
  // updates `currentUser.newEmail` from the same response, but re-reading
  // it here keeps this screen's own state the obvious source during this
  // build, matching every other field on this screen.
  String? _justRequestedEmail;

  @override
  void dispose() {
    // Password fields never leave this screen.
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _deletePasswordController.dispose();
    _newEmailController.dispose();
    _emailPasswordController.dispose();
    super.dispose();
  }

  // ---- Change Password ----

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
    final rule = Validators.password(value); // decision #10, same as signup
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
    // Clear last attempt's server errors so the validators start clean.
    _serverCurrentError = null;
    _serverNewError = null;
    setState(() => _formError = null);
    // Client-side checks first: an invalid form never reaches the network.
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

  // ---- Delete Account (real, immediate, self-service, password-gated) ----

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
    // Clear last attempt's server error so the validator starts clean.
    _deletePasswordError = null;
    setState(() => _deleteFormError = null);
    // Client-side check first: an empty field never reaches the network.
    if (!_deleteFormKey.currentState!.validate()) return;

    setState(() => _deletingAccount = true);
    try {
      await widget.accountDeletionService.deleteAccount(currentPassword: _deletePasswordController.text);
      if (!mounted) return;
      // The account is gone server-side; end the local session too, the
      // same way App Settings' "Clear All App Data" does -- a device with
      // no live account shouldn't still look signed in.
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

  // ---- Change Email (real, password-gated, request-only) ----

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
    // Clear last attempt's server errors so the validators start clean.
    _emailFieldError = null;
    _emailPasswordError = null;
    setState(() => _emailFormError = null);
    // Client-side checks first: an invalid form never reaches the network.
    if (!_emailFormKey.currentState!.validate()) return;

    final newEmail = _newEmailController.text.trim();
    setState(() => _changingEmail = true);
    try {
      await widget.authService.changeEmail(
        currentPassword: _emailPasswordController.text,
        newEmail: newEmail,
      );
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

  void _openComingSoon(String label) {
    Navigator.of(context).push(appRoute(context, (_) => ComingSoonScreen(label: label)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.colors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            // Figma's frame padding: 16 sides, 32 top; 32 below the last card.
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
                Expanded(child: CancelButton(label: l10n.cancelButton, onTap: _saving ? null : _closePasswordForm)),
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
                Expanded(child: CancelButton(label: l10n.cancelButton, onTap: _changingEmail ? null : _closeEmailForm)),
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
          _PrivacyRow(label: l10n.viewPrivacyPolicyLabel, onTap: () => _openComingSoon(l10n.privacyPolicy)),
          const SizedBox(height: 12),
          _PrivacyRow(label: l10n.termsOfService, onTap: () => _openComingSoon(l10n.termsOfService)),
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
              Expanded(child: CancelButton(label: l10n.cancelButton, onTap: _deletingAccount ? null : _closeDeleteForm)),
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

/// A white card with a titled header (16 padding, 18px title, hairline divider
/// below) and a body 24px under it -- the shape of the Password and Privacy
/// cards (Figma nodes 1217:2707 / 1217:2714: header 60.51, gap 24).
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
              border: Border(bottom: BorderSide(color: colors.border, width: _hairline)),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
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

/// The gradient-banded "Security Options" card (Figma node 1217:2653): a 60px
/// band with a shield icon and title, then the three toggles 24px apart. All
/// three are disabled placeholders -- see [PrivacySecurityScreen].
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
      // Turning it off never needs a capability check.
      await settings.setBiometricEnabled(false);
      return;
    }
    setState(() => _checkingBiometric = true);
    final available = await widget.biometricService.isAvailable();
    if (!mounted) return;
    setState(() => _checkingBiometric = false);
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).noBiometricsAvailableError)),
      );
      return;
    }
    await settings.setBiometricEnabled(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    // `watch`, not `read` -- this card's own switches (Biometric, Auto-Lock)
    // need to reflect SettingsProvider immediately, same reasoning as every
    // other real toggle this sprint.
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
                    fontWeight: FontWeight.w500,
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
            onToggle: null, // a separate later task, not #62 -- decision #45
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

/// A labelled password field with a show/hide eye: a 14px label, 8px gap, then
/// a 309.95x36 input (radius 8, fill `#F3F3F5`, 12px left padding, the eye 12px
/// from the right) -- Figma nodes 1217:3009 / 1217:3013.
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
              // A password field: no suggestions or autocorrect learning it.
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
                // Sprint 8 Task 6: EdgeInsetsDirectional, not EdgeInsets --
                // this custom eye-icon overlay isn't InputDecoration.suffixIcon
                // (which auto-mirrors), so the padding has to be made
                // directional by hand, same as edit_profile_screen.dart's
                // _EditField.
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

/// The same shape as [SaveButton] (48 tall, radius 8, Inter Medium 14 white
/// label), but solid `_deleteInk` red instead of the app's primary gradient
/// -- this confirms a destructive, irreversible action, not a normal save,
/// and shouldn't look like one. No Figma frame covers this (the original
/// design never had self-service deletion); the color matches the
/// already-red "Delete Account" row this button replaces once tapped.
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

/// A tappable text row: 36 tall, radius 8, 16px left padding, Inter Medium 14
/// (Figma nodes 1217:2719-2720). "Delete Account" is drawn in red.
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
          // Sprint 8 Task 6: was EdgeInsets.only(left:)/Alignment.centerLeft
          // -- physical values that wouldn't flip to the trailing edge in RTL.
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

