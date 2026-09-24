import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/profile.dart';
import '../../services/door_access_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/gradient_button.dart';

/// Door Access / QR Code screen (Figma node 1215:1616). `membership` comes
/// from [MainShell]'s single shared fetch (see its own doc comment) --
/// this screen's guest-count cap reuses the exact same `max_guests` Home
/// already has, rather than re-querying `SubscriptionService` a second
/// time for the same subscription.
///
/// **Training-project simplification, deliberately not fixed here:** the
/// QR code's payload is just the member's plain `member_id` string. A
/// real production version of this screen should use a short-lived,
/// signed/rotating token instead -- a static QR code can be photographed
/// once (by the member, or by anyone standing near them) and reused
/// indefinitely to claim a door-access log against that member's account
/// forever, with no way to revoke or expire it. Not building that now
/// (it needs a token-issuing endpoint and a scanner-side verification
/// step that don't exist yet); this comment exists so it isn't silently
/// forgotten either.
class QrAccessScreen extends StatefulWidget {
  final ActiveMembership membership;

  /// The member's profile, fetched once by [MainShell] and shared with the
  /// other tabs (its `memberId` is the QR payload). Null if that fetch
  /// failed, in which case the QR area shows "Unable to load your member
  /// ID" instead of a code.
  final Profile? profile;
  final VoidCallback onBackToDashboard;

  const QrAccessScreen({
    super.key,
    required this.membership,
    required this.profile,
    required this.onBackToDashboard,
  });

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
      setState(() {
        _isOpening = false;
        _guestCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Door unlocked! Enjoy your visit.'),
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
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onBackToDashboard,
              icon: Icon(Icons.arrow_back, size: 16, color: colors.textPrimary),
              label: Text(
                'Back to Dashboard',
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
                  'Door Access',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: colors.textPrimary),
                ),
                const SizedBox(height: 48),
                _buildQrSection(colors),
                const SizedBox(height: 56),
                _buildGuestCounter(colors),
                const SizedBox(height: 48),
                _buildNote(context),
                const SizedBox(height: 48),
                GradientButton(
                  label: _isOpening ? 'Opening…' : 'Open Door',
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

  Widget _buildQrSection(AppSemanticColors colors) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Deliberately ALWAYS white, in both themes -- not colors.surface.
            // A QR scanner needs real black-on-white contrast; a dark-mode
            // card fill behind it would risk it not scanning at all, so this
            // one element intentionally opts out of the theme.
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: (widget.profile?.memberId == null)
              ? const SizedBox(
                  width: 199,
                  height: 199,
                  child: Center(
                    child: Text(
                      'Unable to load your member ID',
                      textAlign: TextAlign.center,
                      // Fixed dark-on-white text to match the QR card's
                      // always-white fill above, not colors.textMuted.
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                )
              : QrImageView(
                  // See this file's class-level doc comment: a plain
                  // member_id is a training-project simplification,
                  // not something to reuse in production as-is.
                  data: widget.profile!.memberId!,
                  version: QrVersions.auto,
                  size: 199,
                  backgroundColor: Colors.white,
                ),
        ),
        const SizedBox(height: 24),
        Text(
          'Scan this QR code at the entrance to unlock the door',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textMuted),
        ),
      ],
    );
  }

  Widget _buildGuestCounter(AppSemanticColors colors) {
    final plan = widget.membership.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How many people are with you?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: colors.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          'You can bring up to $_maxGuests guest${_maxGuests == 1 ? '' : 's'} with your ${plan.name} membership',
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
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400, color: colors.textPrimary),
                    ),
                  ],
                ),
                Text(
                  'Guests',
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

  // A warning-accented INFO box, not a neutral surface -- same reasoning as
  // ReserveEventScreen's purple package card: keeps its own brightness-picked
  // amber tint (the design's exact light-mode colors; a dark amber-tinted
  // surface with light amber text in dark mode) rather than becoming an
  // undifferentiated `colors.surface` card.
  Widget _buildNote(BuildContext context) {
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
          children: const [
            TextSpan(text: 'Note: ', style: TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(
              text: 'Your monthly allowance covers your orders only. Guest orders will receive '
                  'member discounts but are paid separately.',
            ),
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
