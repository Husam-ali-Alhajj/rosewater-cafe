import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../l10n/app_localizations.dart';
import '../../models/reservation_summary.dart';
import '../../services/event_reservation_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/app_feedback.dart';
import '../../widgets/arabic_trial_font.dart';
import '../../widgets/gradient_button.dart';

/// Reserve an Event screen (Figma node App-12). `eventType`'s four options
/// are a placeholder, same open-question bucket as the Help & Support FAQ
/// gap (docs/decisions.md) -- the design never confirmed a real list, and
/// no backing table exists for event types to be looked up from.
///
/// The "Estimated Total" shown here is purely a client-side display,
/// computed with the exact same [EventReservationService.pricePerHour]
/// constant the server uses in `create_event_reservation` -- never sent to
/// the server itself. The real `total_price` is always computed by the RPC
/// server-side; a mismatch between this display and that value would be a
/// cosmetic bug at worst, never a security issue, since there's no
/// parameter here for a client-computed price to reach the database
/// through (see docs/decisions.md #36).
class ReserveEventScreen extends StatefulWidget {
  final VoidCallback onBackToDashboard;
  final ValueChanged<ReservationSummary> onConfirmed;

  const ReserveEventScreen({super.key, required this.onBackToDashboard, required this.onConfirmed});

  @override
  State<ReserveEventScreen> createState() => _ReserveEventScreenState();
}

// Canonical values sent to the server (p_event_type) -- these stay in
// English regardless of the active locale, since there's no backing table
// for event types to be looked up from; only the on-screen label localizes.
const _eventTypes = ['Birthday', 'Corporate', 'Private Party', 'Other'];

String _eventTypeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'Birthday':
      return l10n.eventTypeBirthday;
    case 'Corporate':
      return l10n.eventTypeCorporate;
    case 'Private Party':
      return l10n.eventTypePrivateParty;
    default:
      return l10n.eventTypeOther;
  }
}

class _ReserveEventScreenState extends State<ReserveEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reservationService = const EventReservationService();

  final _durationController = TextEditingController();
  final _guestCountController = TextEditingController();

  String? _eventType;
  DateTime? _eventDate;
  TimeOfDay? _startTime;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _durationController.addListener(_onDurationChanged);
  }

  @override
  void dispose() {
    _durationController.removeListener(_onDurationChanged);
    _durationController.dispose();
    _guestCountController.dispose();
    super.dispose();
  }

  void _onDurationChanged() => setState(() {});

  double get _durationHours => double.tryParse(_durationController.text.trim()) ?? 0;

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 2),
      // Dialogs open above the Events tab, outside its ArabicTrialFont.
      builder: (context, child) => ArabicTrialFont(child: child!),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) => ArabicTrialFont(child: child!),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  // At most 2 integer digits and 2 decimal digits, matching the
  // event_reservations.duration_hours column's own numeric(4,2) precision
  // -- rejecting anything finer client-side means the value this screen
  // multiplies by $150 for display is exactly the value that ends up
  // stored, with nothing for Postgres to silently round on insert.
  static final _durationPattern = RegExp(r'^\d{1,2}(\.\d{1,2})?$');

  String? _validateDuration(String? value) {
    final l10n = AppLocalizations.of(context);
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.durationRequired;
    if (!_durationPattern.hasMatch(trimmed)) return l10n.enterValidNumberDecimal;
    final parsed = double.parse(trimmed);
    if (parsed <= 0) return l10n.durationMustBeGreaterThanZero;
    return null;
  }

  String? _validateGuestCount(String? value) {
    final l10n = AppLocalizations.of(context);
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.guestCountRequired;
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return l10n.enterValidNumber;
    if (parsed < 5 || parsed > 100) return l10n.guestCountRange;
    return null;
  }

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    final formValid = _formKey.currentState!.validate();
    final dateValid = _eventDate != null && !_eventDate!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    final timeValid = _startTime != null;
    setState(() => _formSubmitted = true); // surfaces the date/time error text below, if any
    if (!formValid || !dateValid || !timeValid) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final startTime = _startTime!;
    final guestCount = int.parse(_guestCountController.text.trim());
    final durationHours = _durationHours;
    final startTimeText = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
    try {
      await _reservationService.createEventReservation(
        eventType: _eventType!,
        eventDate: _eventDate!,
        startTime: startTimeText,
        durationHours: durationHours,
        guestCount: guestCount,
      );
      if (!mounted) return;
      context.triggerSuccess(); // Sprint 8 Task 4: reservation confirmed
      // Handing off to onConfirmed swaps this whole screen out for
      // ReservationConfirmedScreen (see EventsTab) -- this State gets
      // discarded, not reused, so there's nothing to reset here. The next
      // time a fresh ReserveEventScreen is built, its fields start blank
      // by construction, not because anything here cleared them.
      widget.onConfirmed(ReservationSummary(
        eventDate: _eventDate!,
        startTime: startTime,
        durationHours: durationHours,
        guestCount: guestCount,
      ));
    } on CreateEventReservationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
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
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reserveAnEvent,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: ArabicTrialFont.boldInArabic(context, FontWeight.w500),
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.reserveEventSubtitle,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  _FieldLabel(l10n.eventTypeLabel),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _eventType,
                    items: _eventTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(_eventTypeLabel(l10n, type))))
                        .toList(),
                    onChanged: (value) => setState(() => _eventType = value),
                    validator: (value) => value == null ? l10n.pleaseSelectEventType : null,
                    decoration: _fieldDecoration(colors, hint: l10n.selectEventTypeHint),
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel(l10n.eventDateLabel, icon: Icons.calendar_today_outlined, required: true),
                  const SizedBox(height: 4),
                  _PickerField(
                    text: _eventDate == null ? null : DateFormat.yMMMd().format(_eventDate!),
                    hint: l10n.selectDateHint,
                    onTap: _pickDate,
                  ),
                  if (_dateError != null) _ErrorText(_dateError!),
                  const SizedBox(height: 20),
                  _FieldLabel(l10n.startTimeLabel, icon: Icons.access_time, required: true),
                  const SizedBox(height: 4),
                  _PickerField(
                    text: _startTime?.format(context),
                    hint: l10n.selectTimeHint,
                    onTap: _pickStartTime,
                  ),
                  if (_timeError != null) _ErrorText(_timeError!),
                  const SizedBox(height: 20),
                  _FieldLabel(l10n.durationHoursLabel),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _durationController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: _validateDuration,
                    decoration: _fieldDecoration(colors, hint: l10n.durationExampleHint),
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel(l10n.numberOfGuestsLabel, icon: Icons.people_outline, required: true),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _guestCountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateGuestCount,
                    decoration: _fieldDecoration(colors, hint: '10'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.guestCountRange,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  _buildPackageCard(context, l10n),
                  const SizedBox(height: 24),
                  _buildPriceCard(colors, l10n),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorText(_errorMessage!),
                  ],
                  const SizedBox(height: 32),
                  GradientButton(
                    label: _isSubmitting ? l10n.confirmingEllipsis : l10n.confirmReservation,
                    onPressed: _isSubmitting ? null : _confirm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _formSubmitted = false;

  String? get _dateError {
    if (!_formSubmitted) return null;
    final l10n = AppLocalizations.of(context);
    if (_eventDate == null) return l10n.eventDateRequired;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (_eventDate!.isBefore(todayOnly)) return l10n.datePassedError;
    return null;
  }

  String? get _timeError {
    if (!_formSubmitted) return null;
    if (_startTime == null) return AppLocalizations.of(context).startTimeRequired;
    return null;
  }

  InputDecoration _fieldDecoration(AppSemanticColors colors, {required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.border),
      ),
      errorStyle: TextStyle(color: colors.danger, fontSize: 11),
    );
  }

  // A purple-accented INFO box, not a neutral surface -- keeps its own
  // brightness-picked tint (light lavender-on-white in light mode; a dark
  // purple-tinted surface with light lavender text in dark mode) rather than
  // becoming an undifferentiated `colors.surface` card, so it still reads as
  // "the package included with every event" highlight in both modes.
  Widget _buildPackageCard(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bullets = [
      l10n.packageBulletCafe,
      l10n.packageBulletHookah,
      l10n.packageBulletMenu,
      l10n.packageBulletStaff,
      l10n.packageBulletSound,
    ];
    final bg = isDark ? const Color(0xFF2A2038) : const Color(0xFFFAF5FF);
    final ink = isDark ? const Color(0xFFDCC2FF) : AppColors.purple;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.membershipPremiumBorder.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.eventPackageIncludes,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
          ),
          const SizedBox(height: 8),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $bullet', style: TextStyle(fontSize: 14, color: ink)),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(AppSemanticColors colors, AppLocalizations l10n) {
    final total = EventReservationService.estimatedTotal(_durationHours);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          _priceRow(colors, l10n.baseRatePerHour, '\$${EventReservationService.pricePerHour.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _priceRow(
            colors,
            l10n.durationRowLabel,
            l10n.durationHoursValue(_durationController.text.trim().isEmpty ? '0' : _durationController.text.trim()),
          ),
          const SizedBox(height: 8),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 8),
          _priceRow(colors, l10n.estimatedTotal, '\$${total.toStringAsFixed(2)}', emphasize: true),
        ],
      ),
    );
  }

  Widget _priceRow(AppSemanticColors colors, String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 16 : 14,
            fontWeight: emphasize ? ArabicTrialFont.boldInArabic(context, FontWeight.w400) : FontWeight.w400,
            color: emphasize ? colors.textPrimary : colors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 24 : 14,
            fontWeight: emphasize ? ArabicTrialFont.boldInArabic(context, FontWeight.w400) : FontWeight.w400,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool required;

  const _FieldLabel(this.label, {this.icon, this.required = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: colors.textMuted),
          const SizedBox(width: 6),
        ],
        Text(
          required ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: ArabicTrialFont.boldInArabic(context, FontWeight.w500),
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  final String? text;
  final String hint;
  final VoidCallback onTap;

  const _PickerField({required this.text, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          text ?? hint,
          style: TextStyle(fontSize: 14, color: text == null ? colors.textMuted : colors.textPrimary),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(message, style: TextStyle(color: context.colors.danger, fontSize: 12)),
    );
  }
}
