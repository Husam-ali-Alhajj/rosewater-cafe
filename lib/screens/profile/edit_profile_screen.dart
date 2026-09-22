import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/profile.dart';
import '../../services/avatar_service.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/form_buttons.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/screen_header.dart';

// Exact values read from the Figma `EditProfileScreen` frame (node 1217:2403)
// via the REST API -- same method as decisions #20/#40/#41. Kept private to
// this file.
const _labelInk = Color(0xFF364153);
const _iconGrey = Color(0xFF99A1AF);
const _inputFill = Color(0xFFF3F3F5);
// The design shows field values in this grey (Figma's muted-foreground).
const _inputInk = Color(0xFF717182);
const _rowFill = Color(0xFFF9FAFB);
const _rowValue = Color(0xFF101828);
const _mutedText = Color(0xFF6A7282);
const _cameraButtonBorder = Color(0xFFF3F4F6);

const _hairline = 0.515; // Figma's fractional hairline stroke width

/// Edit Profile (Figma frame "EditProfileScreen", node 1217:2403).
///
/// **Editable:** full name, phone number, profile photo. **Not editable:**
/// email -- changing a Supabase Auth email needs its own re-verification flow
/// (a confirmation link to the new address), out of scope this sprint. It is
/// shown as plain read-only text (not a text field at all, so it can't be
/// focused or edited) with a short note, rather than an input that looks
/// editable but wouldn't take effect. Member ID and plan are read-only too, as
/// in the design.
///
/// **Validation:** name required; phone uses [Validators.phone], decision
/// #10's exact rule (leading `+`, E.164 digit range), shared with Create
/// Account. Both run before any network call -- an invalid form never
/// reaches the server.
///
/// **Photo:** picked with `image_picker` (camera/gallery), validated by
/// [AvatarService] (type + size), shown as a local preview, and uploaded only
/// on Save into the private `avatars` bucket under the user's own folder.
/// Cancel discards it, so nothing is uploaded for a photo that's never saved.
///
/// **Save:** upload the photo (if any) -> a plain `profiles` UPDATE scoped by
/// the existing `auth.uid() = id` policy (no RPC; decision #3 always allowed
/// self-owned writes like this) -> delete the replaced photo. Pops with the
/// saved [Profile] so the caller shows it immediately; pops with null when
/// cancelled or nothing changed.
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
    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(ctx).pop(_PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
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
        maxWidth: 1024, // an avatar never needs more; keeps uploads small
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _photoError = 'Could not access the camera/gallery. Check app permissions and try again.');
      return;
    }
    if (file == null) return; // user cancelled
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    try {
      widget.avatarService.validate(fileName: file.name, sizeBytes: bytes.length);
    } on AvatarInvalidType {
      setState(() => _photoError = 'Please choose a PNG, JPG or WebP image.');
      return;
    } on AvatarTooLarge catch (e) {
      setState(() => _photoError = 'That photo is too large (max ${e.maxBytes ~/ (1024 * 1024)}MB).');
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
    // Client-side validation first -- an invalid form never reaches the
    // network (the server-side rules are the real enforcement, this saves
    // the round trip and gives inline errors).
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
      // The photo may have uploaded before the save failed -- don't leave it orphaned.
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
        _errorMessage = "Couldn't save your changes. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberId = widget.profile.memberId;
    return Scaffold(
      body: Container(
        // The Figma frame's own fill: the same soft 3-stop page wash.
        decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            // Figma's frame padding: 16 sides, 32 top, and 32 below the
            // buttons where the design's frame ends.
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: 'Edit Profile', onBack: _saving ? null : () => Navigator.of(context).pop()),
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
                  decoration: _cardDecoration(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _CardTitle('Personal Information'),
                        const SizedBox(height: 40),
                        _EditField(
                          label: 'Full Name',
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
                          label: 'Phone Number',
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
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _CardTitle('Membership Information'),
                      const SizedBox(height: 40),
                      if (memberId != null && memberId.isNotEmpty) ...[
                        _InfoRow(label: 'Member ID', value: memberId),
                        const SizedBox(height: 12),
                      ],
                      _InfoRow(label: 'Subscription Type', value: widget.membership.planName),
                      const SizedBox(height: 12),
                      const Text(
                        'Contact support to change membership type',
                        style: TextStyle(fontSize: 12, height: 16 / 12, color: _mutedText),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CancelButton(onTap: _saving ? null : () => Navigator.of(context).pop()),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SaveButton(label: 'Save Changes', saving: _saving, onTap: _saving ? null : _save),
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

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
  );
}

/// The avatar with its camera button, and the hint under it (Figma nodes
/// 1217:2413-2424): a 128px avatar with a 40px white camera button in its
/// bottom-right corner, 16px above the caption.
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
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
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Tooltip(
                    message: 'Change photo',
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(side: BorderSide(color: _cameraButtonBorder, width: 1.545)),
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      elevation: 4,
                      child: InkWell(
                        onTap: onChoosePhoto,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(child: Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.textMuted)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap camera icon to change photo',
            style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: AppColors.textMuted),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
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
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 28 / 18,
        letterSpacing: -0.44,
        color: AppColors.textDark,
      ),
    );
  }
}

const _labelStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  height: 1, // the design's 14px line height
  letterSpacing: -0.15,
  color: _labelInk,
);

const _valueStyle = TextStyle(
  fontSize: 16,
  height: 19 / 16, // the design's text box is 19 tall, at y=8.5 in a 36 input
  letterSpacing: -0.31,
  color: _inputInk,
);

/// One editable field: a 14px label, 8px gap, then a 36px input with a 20px
/// icon at x=12 and text starting at x=44 (Figma "Primitive.label" +
/// "Input", e.g. nodes 1217:2429-2437).
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
    OutlineInputBorder border([Color? color]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: color == null ? BorderSide.none : BorderSide(color: color),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
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
              style: _valueStyle,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: _inputFill,
                contentPadding: const EdgeInsets.fromLTRB(44, 8.5, 12, 8.5),
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
              left: 12,
              top: 8,
              child: IgnorePointer(child: Icon(icon, size: 20, color: _iconGrey)),
            ),
          ],
        ),
      ],
    );
  }
}

/// The email, shown exactly like an input (same fill/icon/text) but as plain
/// text -- deliberately not a `TextField`, so it cannot be focused or edited
/// -- with a short note saying why.
class _ReadOnlyEmailField extends StatelessWidget {
  final String email;

  const _ReadOnlyEmailField({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Email Address', style: _labelStyle),
        const SizedBox(height: 8),
        Semantics(
          readOnly: true,
          label: 'Email Address',
          value: email,
          child: ExcludeSemantics(
            child: Container(
              height: 36,
              decoration: BoxDecoration(color: _inputFill, borderRadius: BorderRadius.circular(8)),
              child: Stack(
                children: [
                  const Positioned(
                    left: 12,
                    top: 8,
                    child: Icon(Icons.mail_outline, size: 20, color: _iconGrey),
                  ),
                  Padding(
                    // Text starts at x=44, same as the editable inputs.
                    padding: const EdgeInsets.only(left: 44, right: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: _valueStyle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Your email can't be changed in the app.",
          style: TextStyle(fontSize: 12, height: 16 / 12, color: _mutedText),
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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _rowFill, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: _labelInk),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, height: 24 / 16, letterSpacing: -0.31, color: _rowValue),
          ),
        ],
      ),
    );
  }
}
