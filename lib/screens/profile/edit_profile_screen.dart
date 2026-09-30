import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../models/profile.dart';
import '../../services/avatar_service.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/form_buttons.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/screen_header.dart';

// Sizes from the design; colours come from the theme so dark mode works.

const _hairline = 0.515;

/// Edit Profile. Name, phone and photo can be changed; email, member ID and plan are read-only
/// (email is changed from Privacy & Security).
///
/// The form is checked before anything is sent. A new photo is uploaded only when Save is pressed,
/// then the old one is deleted. Returns the saved profile, or null if cancelled or unchanged.
class EditProfileScreen extends StatefulWidget {
  final Profile profile;
  final ActiveMembership membership;
  final ProfileService profileService;
  final AvatarService avatarService;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.membership,
    this.profileService = const ProfileService(),
    this.avatarService = const AvatarService(),
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

enum _PhotoSource { camera, gallery }

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.profile.fullName);
  late final _phoneController = TextEditingController(text: widget.profile.phone ?? '');

  Uint8List? _pickedBytes;
  String? _pickedName;
  String? _photoError;

  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.takePhotoOption),
              onTap: () => Navigator.of(ctx).pop(_PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGalleryOption),
              onTap: () => Navigator.of(ctx).pop(_PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _photoError = null);
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source == _PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1024, // big enough for an avatar, keeps uploads small
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _photoError = l10n.cameraGalleryAccessError);
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    try {
      widget.avatarService.validate(fileName: file.name, sizeBytes: bytes.length);
    } on AvatarInvalidType {
      setState(() => _photoError = l10n.photoTypeError);
      return;
    } on AvatarTooLarge catch (e) {
      setState(() => _photoError = l10n.photoTooLargeError(e.maxBytes ~/ (1024 * 1024)));
      return;
    }
    setState(() {
      _pickedBytes = bytes;
      _pickedName = file!.name;
    });
  }

  bool get _hasChanges =>
      _pickedBytes != null ||
      _nameController.text.trim() != widget.profile.fullName ||
      _phoneController.text.trim() != (widget.profile.phone ?? '');

  Future<void> _save() async {
    if (_saving) return;
    // Check the form first so invalid input never reaches the server.
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    String? newAvatarPath;
    try {
      final picked = _pickedBytes;
      if (picked != null) {
        try {
          newAvatarPath = await widget.avatarService.upload(bytes: picked, fileName: _pickedName!);
        } catch (_) {
          throw const ProfileUpdateFailure("Couldn't upload your photo. Please try again.");
        }
      }
      final updated = await widget.profileService.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarPath: newAvatarPath,
      );
      final oldPath = widget.profile.avatarUrl;
      if (newAvatarPath != null && oldPath != null && oldPath != newAvatarPath) {
        await widget.avatarService.deleteQuietly(oldPath);
      }
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ProfileUpdateFailure catch (e) {
      // The photo may have uploaded before the save failed; delete it so it isn't left behind.
      if (newAvatarPath != null) await widget.avatarService.deleteQuietly(newAvatarPath);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (newAvatarPath != null) await widget.avatarService.deleteQuietly(newAvatarPath);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = AppLocalizations.of(context).couldntSaveChangesError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberId = widget.profile.memberId;
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: l10n.editProfileButton, onBack: _saving ? null : () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                _PhotoCard(
                  avatarPath: widget.profile.avatarUrl,
                  previewBytes: _pickedBytes,
                  avatarService: widget.avatarService,
                  errorText: _photoError,
                  onChoosePhoto: _choosePhoto,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _cardDecoration(colors),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CardTitle(l10n.personalInformationTitle),
                        const SizedBox(height: 40),
                        _EditField(
                          label: l10n.fullNameLabel,
                          icon: Icons.person_outline,
                          controller: _nameController,
                          validator: Validators.fullName,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          enabled: !_saving,
                        ),
                        const SizedBox(height: 16),
                        _ReadOnlyEmailField(email: widget.profile.email),
                        const SizedBox(height: 16),
                        _EditField(
                          label: l10n.phoneNumberLabel,
                          icon: Icons.phone_outlined,
                          controller: _phoneController,
                          validator: Validators.phone,
                          keyboardType: TextInputType.phone,
                          enabled: !_saving,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _cardDecoration(colors),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CardTitle(l10n.membershipInformationTitle),
                      const SizedBox(height: 40),
                      if (memberId != null && memberId.isNotEmpty) ...[
                        _InfoRow(label: l10n.memberIdFieldLabel, value: memberId),
                        const SizedBox(height: 12),
                      ],
                      _InfoRow(label: l10n.subscriptionTypeLabel, value: widget.membership.planName),
                      const SizedBox(height: 12),
                      Text(
                        l10n.contactSupportNote,
                        style: TextStyle(fontSize: 12, height: 16 / 12, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.danger, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CancelButton(
                        label: l10n.cancelButton,
                        onTap: _saving ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SaveButton(
                        label: l10n.saveChangesButton,
                        savingLabel: l10n.savingEllipsis,
                        saving: _saving,
                        onTap: _saving ? null : _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(AppSemanticColors colors) {
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: colors.border, width: _hairline),
  );
}

/// The avatar with its camera button and the hint below it.
class _PhotoCard extends StatelessWidget {
  final String? avatarPath;
  final Uint8List? previewBytes;
  final AvatarService avatarService;
  final String? errorText;
  final VoidCallback onChoosePhoto;

  const _PhotoCard({
    required this.avatarPath,
    required this.previewBytes,
    required this.avatarService,
    required this.errorText,
    required this.onChoosePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(colors),
      child: Column(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              children: [
                ProfileAvatar(
                  size: 128,
                  avatarPath: avatarPath,
                  previewBytes: previewBytes,
                  avatarService: avatarService,
                ),
                PositionedDirectional(
                  end: 0,
                  bottom: 0,
                  child: Tooltip(
                    message: l10n.changePhotoTooltip,
                    child: Material(
                      color: colors.surface,
                      shape: CircleBorder(side: BorderSide(color: colors.border, width: 1.545)),
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      elevation: 4,
                      child: InkWell(
                        onTap: onChoosePhoto,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(child: Icon(Icons.camera_alt_outlined, size: 20, color: colors.textMuted)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tapCameraIconHint,
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.danger, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;

  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 28 / 18,
        letterSpacing: -0.44,
        color: context.colors.textPrimary,
      ),
    );
  }
}

TextStyle _labelStyle(AppSemanticColors colors) =>
    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1, letterSpacing: -0.15, color: colors.textMuted);

// Editable text is slightly muted, unlike the read-only values below.
TextStyle _valueStyle(AppSemanticColors colors) =>
    TextStyle(fontSize: 16, height: 19 / 16, letterSpacing: -0.31, color: colors.textMuted);

/// One editable field: label, then an input with an icon.
class _EditField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool enabled;

  const _EditField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.validator,
    required this.keyboardType,
    required this.enabled,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    OutlineInputBorder border([Color? color]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: color == null ? BorderSide.none : BorderSide(color: color),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle(colors)),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextFormField(
              controller: controller,
              validator: validator,
              enabled: enabled,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: _valueStyle(colors),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colors.inputFill,
                // The icon is drawn by hand, so its position has to flip for right-to-left.
                contentPadding: const EdgeInsetsDirectional.fromSTEB(44, 8.5, 12, 8.5),
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
              start: 12,
              top: 8,
              child: IgnorePointer(child: Icon(icon, size: 20, color: colors.textMuted)),
            ),
          ],
        ),
      ],
    );
  }
}

/// The email, styled like an input but read-only text so it can't be edited.
class _ReadOnlyEmailField extends StatelessWidget {
  final String email;

  const _ReadOnlyEmailField({required this.email});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.emailAddressLabel, style: _labelStyle(colors)),
        const SizedBox(height: 8),
        Semantics(
          readOnly: true,
          label: l10n.emailAddressLabel,
          value: email,
          child: ExcludeSemantics(
            child: Container(
              height: 36,
              decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(8)),
              child: Stack(
                children: [
                  PositionedDirectional(
                    start: 12,
                    top: 8,
                    child: Icon(Icons.mail_outline, size: 20, color: colors.textMuted),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 44, end: 12),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: _valueStyle(colors)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.emailCantBeChangedNote,
          style: TextStyle(fontSize: 12, height: 16 / 12, color: colors.textMuted),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textMuted),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, height: 24 / 16, letterSpacing: -0.31, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
