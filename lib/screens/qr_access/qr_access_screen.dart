import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../models/profile.dart';
import '../../services/door_access_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/app_feedback.dart';
import '../../widgets/gradient_button.dart';

/// Door Access: shows the member's QR code and a guest counter limited by the plan (from
/// MainShell).
///
/// Note: the QR code is just the plain member ID. A real version should use a short-lived signed
/// token, because a photo of a static code could be reused forever.
class QrAccessScreen extends StatefulWidget {
  final ActiveMembership membership;

  /// The member's profile from MainShell; its member ID is the QR content. Null if it failed to
  /// load.
  final Profile? profile;
  final VoidCallback onBackToDashboard;

  const QrAccessScreen({super.key, required this.membership, required this.profile, required this.onBackToDashboard});

  @override
  State<QrAccessScreen> createState() => _QrAccessScreenState();
}

class _QrAccessScreenState extends State<QrAccessScreen> {
  final _doorAccessService = const DoorAccessService();

  int _guestCount = 0;
  bool _isOpening = false;
  String? _errorMessage;

  int get _maxGuests => widget.membership.plan.maxGuests;

  void _decrement() {
    if (_guestCount <= 0) return;
    setState(() => _guestCount--);
  }

  void _increment() {
    if (_guestCount >= _maxGuests) return;
    setState(() => _guestCount++);
  }

  Future<void> _openDoor() async {
    if (_isOpening) return;
    setState(() {
      _isOpening = true;
      _errorMessage = null;
    });
    try {
      await _doorAccessService.logDoorAccess(_guestCount);
      if (!mounted) return;
      context.triggerSuccess();
      setState(() {
        _isOpening = false;
        _guestCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).doorUnlockedMessage),
          backgroundColor: context.colors.success,
        ),
      );
    } on LogDoorAccessFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isOpening = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isOpening = false;
        _errorMessage = AppLocalizations.of(context).genericTryAgainError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: widget.onBackToDashboard,
              icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, size: 16, color: colors.textPrimary),
              label: Text(
                l10n.backToDashboard,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.doorAccessHeading,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
                const SizedBox(height: 48),
                _buildQrSection(colors, l10n),
                const SizedBox(height: 56),
                _buildGuestCounter(colors, l10n),
                const SizedBox(height: 48),
                _buildNote(context, l10n),
                const SizedBox(height: 48),
                GradientButton(
                  label: _isOpening ? l10n.openingEllipsis : l10n.openDoorButton,
                  onPressed: _isOpening ? null : _openDoor,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.danger, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection(AppSemanticColors colors, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Always white, even in dark mode: QR scanners need black on white.
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: (widget.profile?.memberId == null)
              ? SizedBox(
                  width: 199,
                  height: 199,
                  child: Center(
                    child: Text(
                      l10n.unableToLoadMemberId,
                      textAlign: TextAlign.center,
                      // Dark text to match the white QR card.
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                )
              : QrImageView(
                  // The plain member ID (see the note at the top of this class).
                  data: widget.profile!.memberId!,
                  version: QrVersions.auto,
                  size: 199,
                  backgroundColor: Colors.white,
                ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.scanQrInstruction,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textMuted),
        ),
      ],
    );
  }

  Widget _buildGuestCounter(AppSemanticColors colors, AppLocalizations l10n) {
    final plan = widget.membership.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.howManyPeopleQuestion,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          _maxGuests == 1
              ? l10n.guestAllowanceSingular(_maxGuests, plan.name)
              : l10n.guestAllowancePlural(_maxGuests, plan.name),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StepperButton(label: '−', onPressed: _guestCount > 0 ? _decrement : null),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 20, color: colors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      '$_guestCount',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                  ],
                ),
                Text(
                  l10n.guestsCounterLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colors.textMuted),
                ),
              ],
            ),
            _StepperButton(label: '+', onPressed: _guestCount < _maxGuests ? _increment : null),
          ],
        ),
      ],
    );
  }

  // A tinted info box, so it stands out in both light and dark mode.
  Widget _buildNote(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF3A2E12) : const Color(0xFFFFFBEB);
    final border = isDark ? const Color(0xFF6B5518) : const Color(0xFFFEE685);
    final ink = isDark ? const Color(0xFFFFD98A) : const Color(0xFF973C00);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 14, color: ink),
          children: [
            TextSpan(
              text: l10n.noteLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: l10n.guestOrdersNote),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _StepperButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.border.withValues(alpha: enabled ? 1 : 0.5)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: enabled ? colors.textPrimary : colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
