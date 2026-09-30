import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/payment_method_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/card_brand.dart';
import '../../utils/payment_validators.dart';
import '../../widgets/form_buttons.dart';
import '../../widgets/payment_fields.dart';
import '../../widgets/screen_header.dart';

const _hairline = 0.515;

/// Add a card. Not in the design, so it reuses the payment form's fields and the Profile screens'
/// layout.
///
/// Only the brand, last 4 digits, expiry and default flag are saved. The full number and CVV are
/// only checked, then thrown away; they're never stored or sent.
///
/// The first card becomes the default automatically. Returns true once saved.
class AddPaymentMethodScreen extends StatefulWidget {
  /// True if this is the user's first card (then it's always the default, so no checkbox).
  final bool isFirstCard;
  final PaymentMethodService service;

  const AddPaymentMethodScreen({super.key, required this.isFirstCard, this.service = const PaymentMethodService()});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _makeDefault = false;
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    // Clear the card fields when leaving.
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    // Same checks as the payment form.
    if (!_formKey.currentState!.validate()) return;

    // The validators already guarantee 16 digits and a valid MM/YY.
    final number = _cardNumberController.text;
    final brand = CardBrand.detect(number);
    final last4 = CardBrand.lastFour(number)!;
    final expiry = _expiryController.text;
    final expMonth = int.parse(expiry.substring(0, 2));
    final expYear = 2000 + int.parse(expiry.substring(3, 5));

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.service.add(
        brand: brand,
        last4: last4,
        expMonth: expMonth,
        expYear: expYear,
        makeDefault: widget.isFirstCard || _makeDefault,
      );
      if (!mounted) return;
      // Clear the card fields; they're not needed anymore.
      _cardNumberController.clear();
      _expiryController.clear();
      _cvvController.clear();
      Navigator.of(context).pop(true);
    } on PaymentMethodFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = AppLocalizations.of(context).couldntSaveCardError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                ScreenHeader(
                  title: l10n.addPaymentMethodHeading,
                  onBack: _saving ? null : () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border, width: _hairline),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PaymentField(
                          label: l10n.cardNumberLabel,
                          controller: _cardNumberController,
                          hint: '1234 5678 9012 3456',
                          validator: PaymentValidators.cardNumber,
                          keyboardType: TextInputType.number,
                          enabled: !_saving,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: PaymentField(
                                label: l10n.expiryDateLabel,
                                controller: _expiryController,
                                hint: 'MM/YY',
                                validator: PaymentValidators.expiry,
                                keyboardType: TextInputType.number,
                                enabled: !_saving,
                                inputFormatters: [ExpiryInputFormatter()],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: PaymentField(
                                label: l10n.cvvLabel,
                                controller: _cvvController,
                                hint: '123',
                                validator: PaymentValidators.cvv,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                enabled: !_saving,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!widget.isFirstCard) ...[
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _saving ? null : () => setState(() => _makeDefault = !_makeDefault),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _makeDefault,
                                  onChanged: _saving ? null : (v) => setState(() => _makeDefault = v ?? false),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Expanded(
                                  child: Text(
                                    l10n.setAsDefaultPaymentCheckbox,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 20 / 14,
                                      letterSpacing: -0.15,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          l10n.cardSecurityNote,
                          style: TextStyle(fontSize: 12, height: 16 / 12, color: colors.textMuted),
                        ),
                      ],
                    ),
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
                        label: l10n.saveCardButton,
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
