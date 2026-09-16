import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/reservation_summary.dart';
import '../../services/event_reservation_service.dart';
import '../../theme/app_colors.dart';
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

const _eventTypes = ['Birthday', 'Corporate', 'Private Party', 'Other'];

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
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _startTime = picked);
  }

  // At most 2 integer digits and 2 decimal digits, matching the
  // event_reservations.duration_hours column's own numeric(4,2) precision
  // -- rejecting anything finer client-side means the value this screen
  // multiplies by $150 for display is exactly the value that ends up
  // stored, with nothing for Postgres to silently round on insert.
  static final _durationPattern = RegExp(r'^\d{1,2}(\.\d{1,2})?$');

  String? _validateDuration(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Duration is required';
    if (!_durationPattern.hasMatch(trimmed)) return 'Enter a valid number (up to 2 decimal places)';
    final parsed = double.parse(trimmed);
    if (parsed <= 0) return 'Duration must be greater than 0';
    return null;
  }

  String? _validateGuestCount(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Number of guests is required';
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 5 || parsed > 100) return 'Minimum 5 guests, maximum 100 guests';
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
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onBackToDashboard,
              icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0A0A0A)),
              label: const Text(
                'Back to Dashboard',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0A0A0A)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reserve an Event',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Book the café for your private event. Perfect for parties, meetings, and special occasions.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  _FieldLabel('Event Type'),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _eventType,
                    items: _eventTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setState(() => _eventType = value),
                    validator: (value) => value == null ? 'Please select an event type' : null,
                    decoration: _fieldDecoration(hint: 'Select event type'),
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel('Event Date', icon: Icons.calendar_today_outlined, required: true),
                  const SizedBox(height: 4),
                  _PickerField(
                    text: _eventDate == null ? null : DateFormat.yMMMd().format(_eventDate!),
                    hint: 'Select a date',
                    onTap: _pickDate,
                  ),
                  if (_dateError != null) _ErrorText(_dateError!),
                  const SizedBox(height: 20),
                  _FieldLabel('Start Time', icon: Icons.access_time, required: true),
                  const SizedBox(height: 4),
                  _PickerField(
                    text: _startTime?.format(context),
                    hint: 'Select a time',
                    onTap: _pickStartTime,
                  ),
                  if (_timeError != null) _ErrorText(_timeError!),
                  const SizedBox(height: 20),
                  _FieldLabel('Duration (hours)'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _durationController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: _validateDuration,
                    decoration: _fieldDecoration(hint: 'e.g. 2'),
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel('Number of Guests', icon: Icons.people_outline, required: true),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _guestCountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateGuestCount,
                    decoration: _fieldDecoration(hint: '10'),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Minimum 5 guests, maximum 100 guests',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  _buildPackageCard(),
                  const SizedBox(height: 24),
                  _buildPriceCard(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorText(_errorMessage!),
                  ],
                  const SizedBox(height: 32),
                  GradientButton(
                    label: _isSubmitting ? 'Confirming…' : 'Confirm Reservation',
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
    if (_eventDate == null) return 'Event date is required';
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (_eventDate!.isBefore(todayOnly)) return "That date has already passed -- please choose another.";
    return null;
  }

  String? get _timeError {
    if (!_formSubmitted) return null;
    if (_startTime == null) return 'Start time is required';
    return null;
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF3F3F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
      ),
      errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11),
    );
  }

  Widget _buildPackageCard() {
    const bullets = [
      'Exclusive use of the café',
      'Complimentary hookah for all guests',
      'Special event menu available',
      'Dedicated staff service',
      'Sound system and music control',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.membershipPremiumBorder.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Package Includes:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.purple),
          ),
          const SizedBox(height: 8),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $bullet', style: const TextStyle(fontSize: 14, color: AppColors.purple)),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    final total = EventReservationService.estimatedTotal(_durationHours);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          _priceRow('Base rate (per hour)', '\$${EventReservationService.pricePerHour.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _priceRow('Duration', '${_durationController.text.trim().isEmpty ? '0' : _durationController.text.trim()} hours'),
          const SizedBox(height: 8),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 8),
          _priceRow('Estimated Total', '\$${total.toStringAsFixed(2)}', emphasize: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 16 : 14,
            fontWeight: FontWeight.w400,
            color: emphasize ? AppColors.membershipPriceText : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 24 : 14,
            fontWeight: FontWeight.w400,
            color: AppColors.membershipPriceText,
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
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
        ],
        Text(
          required ? '$label *' : label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0A0A0A)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: Text(
          text ?? hint,
          style: TextStyle(fontSize: 14, color: text == null ? AppColors.textMuted : AppColors.textDark),
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
      child: Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
    );
  }
}
