import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/membership_plan.dart';
import '../../models/profile.dart';
import '../../services/id_document_service.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
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
          _loadError = 'Could not load your details. Check your connection and try again.';
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
        _loadError = 'Could not load your details. Check your connection and try again.';
      });
    }
  }

  Future<void> _showPickerOptions() async {
    final source = await showModalBottomSheet<_PickSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(ctx).pop(_PickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop(_PickSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('Choose File (PNG, JPG, PDF)'),
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
      setState(() => _pickError = 'Could not access the camera/gallery. Check app permissions and try again.');
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
      setState(() => _pickError = 'Could not open the file picker. Try again.');
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
        _pickError = 'Please choose a PNG, JPG, or PDF file.';
      });
      return;
    } on IdDocumentTooLarge catch (e) {
      setState(() {
        _pickedFile = null;
        _pickError = 'That file is too large — max ${e.maxBytes ~/ (1024 * 1024)}MB.';
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
        MaterialPageRoute(
          builder: (_) => PaymentScreen(subscriptionId: widget.subscriptionId, plan: _plan!),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadError = 'Upload failed. Check your connection and try again.';
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
        const SnackBar(content: Text('Could not go back to plans. Check your connection and try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _loadError!,
                      style: TextStyle(color: AppColors.danger),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final profile = _profile!;
    final plan = _plan!;
    return Column(
      children: [
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _cancelling ? null : _backToPlans,
            icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0A0A0A)),
            label: Text(
              _cancelling ? 'Cancelling…' : 'Back to Plans',
              style: const TextStyle(color: Color(0xFF0A0A0A), fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
                  const Text(
                    'Verify Your Membership',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: 0.4, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 48),
                  _ReadOnlyField(label: 'Full Name', value: profile.fullName),
                  const SizedBox(height: 24),
                  _ReadOnlyField(label: 'Email Address', value: profile.email),
                  const SizedBox(height: 24),
                  _ReadOnlyField(label: 'Phone Number', value: profile.phone ?? '—'),
                  const SizedBox(height: 24),
                  _ReadOnlyField(
                    label: 'Subscription Plan',
                    value: '${plan.name} — \$${plan.priceDollars}/month',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Upload ID Document',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15, color: Color(0xFF0A0A0A)),
                  ),
                  const SizedBox(height: 4),
                  _UploadBox(pickedFileName: _pickedFile?.name, onTap: _showPickerOptions),
                  if (_pickError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_pickError!, style: TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                  if (_uploadError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_uploadError!, style: TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Required for membership verification and security',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.membershipPriceSuffix),
                  ),
                  const SizedBox(height: 48),
                  GradientButton(
                    label: _uploading ? 'Uploading…' : 'Continue to Payment',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15, color: Color(0xFF0A0A0A)),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          enabled: false,
          style: const TextStyle(fontSize: 16, color: Color(0xFF717182), letterSpacing: -0.31),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F3F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
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
    final hasFile = pickedFileName != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFile ? AppColors.success : const Color(0xFFD1D5DC),
            width: hasFile ? 1.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_outlined,
              color: hasFile ? AppColors.success : const Color(0xFF99A1AF),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              hasFile ? pickedFileName! : 'Click to upload ID',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15, color: AppColors.textMuted),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            if (!hasFile) ...[
              const SizedBox(height: 4),
              const Text(
                'PNG, JPG, PDF (max 10MB)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF99A1AF)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
