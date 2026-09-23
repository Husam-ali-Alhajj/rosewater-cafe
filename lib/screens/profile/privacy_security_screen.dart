import 'package:flutter/material.dart';

import '../../services/account_deletion_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
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
const _rowInk = Color(0xFF364153);
const _bodyInk = Color(0xFF4A5565);
const _labelInk = Color(0xFF0A0A0A);
const _hintInk = Color(0xFF717182);
const _inputFill = Color(0xFFF3F3F5);
const _eyeInk = Color(0xFF99A1AF);
const _dividerInk = Color(0xFFF3F4F6);
const _deleteInk = Color(0xFFE7000B);

const _hairline = 0.515; // Figma's fractional hairline stroke width

/// Privacy & Security (Figma frames 1217:2644 / 1217:2946): Security Options,
/// Password, and Privacy.
///
/// **Security Options are disabled placeholders** (decision #45, confirmed
/// with the project owner): Biometric Authentication, Two-Factor
/// Authentication and Auto-Lock are drawn as in the design but switched off,
/// dimmed, inert, and marked "(Coming Soon)" -- the way the design already
/// labels Dark Mode. Nothing is stored and nothing is enforced. They are shown
/// off (the design draws Auto-Lock on) so nothing looks like it is protecting
/// the account when it isn't. "Lock after inactivity" and "require biometric to
/// unlock" are two different features that share the Auto-Lock toggle; neither
/// is built.
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
/// tradeoff and explicitly chose self-service instead). Confirming calls the
/// `delete_own_account` RPC, which deletes exactly the caller's own
/// `auth.users` row -- cascading through every table of their data -- then
/// this screen ends the local session and returns to Auth Landing. There is
/// no undo, and the confirmation dialog says so before anything happens.
///
/// "View Privacy Policy" and "Terms of Service" open a "coming soon" page:
/// no policy or terms text exists yet to show.
class PrivacySecurityScreen extends StatefulWidget {
  final AuthService authService;
  final AccountDeletionService accountDeletionService;

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

  bool _deletingAccount = false;

  @override
  void dispose() {
    // Password fields never leave this screen.
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
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
    if (value == null || value.isEmpty) return 'Enter your current password';
    return null;
  }

  String? _validateNew(String? value) {
    if (_serverNewError != null) return _serverNewError;
    final rule = Validators.password(value); // decision #10, same as signup
    if (rule != null) return rule;
    if (value == _currentController.text) return 'Choose a password different from your current one.';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _newController.text) return 'Passwords do not match';
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
      _closePasswordForm();
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
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
        _formError = "Couldn't update your password. Check your connection and try again.";
      });
    }
  }

  // ---- Delete Account (real, immediate, self-service) ----

  Future<void> _confirmDeleteAccount() async {
    if (_deletingAccount) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This immediately and permanently deletes your account and everything in it -- '
          'your profile, membership, payment methods, and reservation history. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently', style: TextStyle(color: _deleteInk)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await widget.accountDeletionService.deleteAccount();
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
      setState(() => _deletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't delete your account. Please try again.")),
      );
    }
  }

  void _openComingSoon(String label) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComingSoonScreen(label: label)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            // Figma's frame padding: 16 sides, 32 top; 32 below the last card.
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: 'Privacy & Security', onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                const _SecurityOptionsCard(),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Password',
                  child: _changingPassword ? _buildPasswordForm() : _buildPasswordPrompt(),
                ),
                const SizedBox(height: 24),
                _SectionCard(title: 'Privacy', child: _buildPrivacyRows()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordPrompt() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Keep your account secure by using a strong password',
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: _bodyInk),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
            ),
            child: InkWell(
              onTap: _openPasswordForm,
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: const SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: _labelInk),
                    SizedBox(width: 17),
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: _labelInk,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PasswordField(
              label: 'Current Password',
              hint: 'Enter current password',
              controller: _currentController,
              visible: _showCurrent,
              onToggleVisible: () => setState(() => _showCurrent = !_showCurrent),
              validator: _validateCurrent,
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            _PasswordField(
              label: 'New Password',
              hint: 'Enter new password',
              controller: _newController,
              visible: _showNew,
              onToggleVisible: () => setState(() => _showNew = !_showNew),
              validator: _validateNew,
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            _PasswordField(
              label: 'Confirm New Password',
              hint: 'Confirm new password',
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
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: CancelButton(onTap: _saving ? null : _closePasswordForm)),
                const SizedBox(width: 16),
                Expanded(
                  child: SaveButton(
                    label: 'Update Password',
                    savingLabel: 'Updating…',
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

  Widget _buildPrivacyRows() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrivacyRow(label: 'View Privacy Policy', onTap: () => _openComingSoon('Privacy Policy')),
          const SizedBox(height: 12),
          _PrivacyRow(label: 'Terms of Service', onTap: () => _openComingSoon('Terms of Service')),
          const SizedBox(height: 12),
          _PrivacyRow(
            label: 'Delete Account',
            danger: true,
            onTap: _deletingAccount ? null : _confirmDeleteAccount,
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _dividerInk, width: _hairline)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 28 / 18,
                letterSpacing: -0.44,
                color: AppColors.textDark,
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
class _SecurityOptionsCard extends StatelessWidget {
  const _SecurityOptionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 20, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Security Options',
                  style: TextStyle(
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
          const SettingToggleRow(
            icon: Icons.fingerprint,
            iconSize: 20,
            label: 'Biometric Authentication',
            description: 'Use fingerprint or face ID to sign in',
            value: false,
            onToggle: null, // placeholder: disabled
            showDivider: true,
            note: '(Coming Soon)',
            switchKey: ValueKey('placeholder-biometric'),
          ),
          const SizedBox(height: 24),
          const SettingToggleRow(
            icon: Icons.smartphone_outlined,
            iconSize: 20,
            label: 'Two-Factor Authentication',
            description: 'Add an extra layer of security',
            value: false,
            onToggle: null,
            showDivider: true,
            note: '(Coming Soon)',
            switchKey: ValueKey('placeholder-two-factor'),
          ),
          const SizedBox(height: 24),
          const SettingToggleRow(
            icon: Icons.lock_outline,
            iconSize: 20,
            label: 'Auto-Lock',
            description: 'Automatically lock app when inactive',
            value: false,
            onToggle: null,
            showDivider: false,
            note: '(Coming Soon)',
            switchKey: ValueKey('placeholder-auto-lock'),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1,
            letterSpacing: -0.15,
            color: _labelInk,
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
              style: textStyle.copyWith(color: AppColors.textDark),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: _inputFill,
                hintText: hint,
                hintStyle: textStyle.copyWith(color: _hintInk),
                contentPadding: const EdgeInsets.fromLTRB(12, 8.5, 44, 8.5),
                border: border(),
                enabledBorder: border(),
                disabledBorder: border(),
                focusedBorder: border(),
                errorBorder: border(AppColors.danger),
                focusedErrorBorder: border(AppColors.danger),
                errorStyle: const TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
            Positioned(
              right: 12,
              top: 10,
              child: Tooltip(
                message: visible ? 'Hide password' : 'Show password',
                child: InkWell(
                  onTap: enabled ? onToggleVisible : null,
                  customBorder: const CircleBorder(),
                  child: Icon(
                    visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                    color: _eyeInk,
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

/// A tappable text row: 36 tall, radius 8, 16px left padding, Inter Medium 14
/// (Figma nodes 1217:2719-2720). "Delete Account" is drawn in red.
class _PrivacyRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  const _PrivacyRow({required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                letterSpacing: -0.15,
                color: danger ? _deleteInk : _rowInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

