import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../models/membership_plan.dart';
import '../../models/profile.dart';
import '../../services/id_document_service.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/gradient_button.dart';
import 'payment_screen.dart';

class _PickedFile {
  final String name;
  final Uint8List bytes;
  const _PickedFile({required this.name, required this.bytes});
}

enum _PickSource { camera, gallery, file }

/// Real "Create Your Account" screen from the design (Figma page 9) —
/// renamed here to "Verify Your Membership" since, per decision #1, account
/// creation already happened in Sprint 1. Name/email/phone and the selected
/// plan are shown read-only (pulled from `profiles` and the subscription's
/// plan) rather than re-asked, per docs/decisions.md #18 — only the ID
/// upload control is interactive.
class IdUploadScreen extends StatefulWidget {
  final String subscriptionId;

  const IdUploadScreen({super.key, required this.subscriptionId});

  @override
  State<IdUploadScreen> createState() => _IdUploadScreenState();
}

class _IdUploadScreenState extends State<IdUploadScreen> {
  final _profileService = const ProfileService();
  final _subscriptionService = const SubscriptionService();
  final _idDocumentService = const IdDocumentService();

  bool _loading = true;
  Profile? _profile;
  MembershipPlan? _plan;
  String? _loadError;

  _PickedFile? _pickedFile;
  String? _pickError;
  bool _uploading = false;
  String? _uploadError;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Fetched by subscriptionId alone (not passed-through profile/plan
  /// objects) so this screen behaves identically whether it was reached by
  /// a fresh plan selection or by Choose Membership resuming a pending
  /// subscription on a cold start.
  Future<void> _init() async {
    try {
      final results = await Future.wait([
        _profileService.fetchCurrentProfile(),
        _subscriptionService.fetchPlanForSubscription(widget.subscriptionId),
      ]);
      final profile = results[0] as Profile?;
      final plan = results[1] as MembershipPlan?;
      if (!mounted) return;
      if (profile == null || plan == null) {
        setState(() {
          _loading = false;
          _loadError = AppLocalizations.of(context).couldNotLoadDetailsError;
        });
        return;
      }
      setState(() {
        _profile = profile;
        _plan = plan;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = AppLocalizations.of(context).couldNotLoadDetailsError;
      });
    }
  }

  Future<void> _showPickerOptions() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<_PickSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.of(ctx).pop(_PickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.of(ctx).pop(_PickSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(l10n.chooseFileHint),
              onTap: () => Navigator.of(ctx).pop(_PickSource.file),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    switch (source) {
      case _PickSource.camera:
        await _pickImage(ImageSource.camera);
      case _PickSource.gallery:
        await _pickImage(ImageSource.gallery);
      case _PickSource.file:
        await _pickFile();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _pickError = null;
      _uploadError = null;
    });
    XFile? file;
    try {
      file = await ImagePicker().pickImage(source: source, imageQuality: 90);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pickError = AppLocalizations.of(context).cameraGalleryAccessError);
      return;
    }
    if (file == null) return; // user cancelled
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    _validateAndStore(name: file.name, bytes: bytes);
  }

  Future<void> _pickFile() async {
    setState(() {
      _pickError = null;
      _uploadError = null;
    });
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: IdDocumentService.allowedExtensions.toList(),
        withData: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _pickError = AppLocalizations.of(context).filePickerError);
      return;
    }
    if (!mounted) return;
    final files = result?.files;
    if (files == null || files.isEmpty) return; // user cancelled
    final picked = files.first;
    final bytes = picked.bytes;
    if (bytes == null) return;
    _validateAndStore(name: picked.name, bytes: bytes);
  }

  /// Checked against name/size only, before this file is ever handed to
  /// IdDocumentService.uploadAndRecord — so an oversized or wrong-type file
  /// is rejected here, before any network call, not after one fails.
  void _validateAndStore({required String name, required Uint8List bytes}) {
    try {
      _idDocumentService.validate(fileName: name, sizeBytes: bytes.length);
    } on IdDocumentInvalidType {
      setState(() {
        _pickedFile = null;
        _pickError = AppLocalizations.of(context).invalidIdFileType;
      });
      return;
    } on IdDocumentTooLarge catch (e) {
      setState(() {
        _pickedFile = null;
        _pickError = AppLocalizations.of(context).idFileTooLarge(e.maxBytes ~/ (1024 * 1024));
      });
      return;
    }
    setState(() {
      _pickedFile = _PickedFile(name: name, bytes: bytes);
      _pickError = null;
    });
  }

  Future<void> _submit() async {
    final file = _pickedFile;
    if (file == null || _uploading) return;
    setState(() {
      _uploading = true;
      _uploadError = null;
    });
    try {
      await _idDocumentService.uploadAndRecord(bytes: file.bytes, fileName: file.name);
      if (!mounted) return;
      Navigator.of(context).push(
        appRoute(
          context,
          (_) => PaymentScreen(subscriptionId: widget.subscriptionId, plan: _plan!),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadError = AppLocalizations.of(context).uploadFailedError;
      });
    }
  }

  /// Unlike the hardware/system back gesture (which Choose Membership
  /// re-intercepts to resume straight back into this same screen, keeping
  /// the anti-duplicate behavior from decision #17), this button actually
  /// cancels the pending subscription first via cancel_subscription, then
  /// pops with a `true` result so Choose Membership knows to re-resolve
  /// (and this time actually show the cards) instead of bouncing back here.
  Future<void> _backToPlans() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    try {
      await _subscriptionService.cancelSubscription(widget.subscriptionId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).couldNotGoBackToPlansError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _loadError!,
                      style: TextStyle(color: colors.danger),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildForm(colors),
        ),
      ),
    );
  }

  Widget _buildForm(AppSemanticColors colors) {
    final l10n = AppLocalizations.of(context);
    final profile = _profile!;
    final plan = _plan!;
    return Column(
      children: [
        const SizedBox(height: 16),
        Align(
          // AlignmentDirectional.centerStart, not physical
          // Alignment.centerLeft (Sprint 8 Task 6).
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _cancelling ? null : _backToPlans,
            icon: Icon(
              // Same explicit RTL check as every other back control this
              // task touched.
              Directionality.of(context) == TextDirection.rtl ? Icons.arrow_forward : Icons.arrow_back,
              size: 16,
              color: colors.textPrimary,
            ),
            label: Text(
              _cancelling ? l10n.cancellingEllipsis : l10n.backToPlans,
              style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.verifyYourMembership,
                    // TextAlign.start, not physical TextAlign.left (Sprint 8
                    // Task 6).
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 48),
                  _ReadOnlyField(label: l10n.fullNameLabel, value: profile.fullName),
                  const SizedBox(height: 24),
                  _ReadOnlyField(label: l10n.emailAddressLabel, value: profile.email),
                  const SizedBox(height: 24),
                  _ReadOnlyField(label: l10n.phoneNumberLabel, value: profile.phone ?? '—'),
                  const SizedBox(height: 24),
                  _ReadOnlyField(
                    label: l10n.subscriptionPlanLabel,
                    value: '${plan.name} — \$${plan.priceDollars}${l10n.perMonthSuffix}',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.uploadIdDocumentLabel,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  _UploadBox(pickedFileName: _pickedFile?.name, onTap: _showPickerOptions),
                  if (_pickError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_pickError!, style: TextStyle(color: colors.danger, fontSize: 12)),
                    ),
                  if (_uploadError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_uploadError!, style: TextStyle(color: colors.danger, fontSize: 12)),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.requiredForVerification,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colors.textMuted),
                  ),
                  const SizedBox(height: 48),
                  GradientButton(
                    label: _uploading ? l10n.uploadingEllipsis : l10n.continueToPayment,
                    onPressed: (_pickedFile == null || _uploading) ? null : _submit,
                    fontSize: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15, color: colors.textPrimary),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          enabled: false,
          style: TextStyle(fontSize: 16, color: colors.textMuted, letterSpacing: -0.31),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String? pickedFileName;
  final VoidCallback onTap;

  const _UploadBox({required this.pickedFileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasFile = pickedFileName != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFile ? colors.success : colors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_outlined,
              color: hasFile ? colors.success : colors.textMuted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              hasFile ? pickedFileName! : AppLocalizations.of(context).clickToUploadId,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15, color: colors.textMuted),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            if (!hasFile) ...[
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).idFileTypesHint,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
