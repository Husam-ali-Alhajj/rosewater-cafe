import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/payment_method_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/card_brand.dart';
import '../../utils/payment_validators.dart';
import '../../widgets/form_buttons.dart';
import '../../widgets/payment_fields.dart';
import '../../widgets/screen_header.dart';

const _hairline = 0.515; // Figma's fractional hairline stroke width

/// Add Payment Method.
///
/// **There is no Figma frame for this screen** -- the design has only the
/// "Add New Payment Method" button on the list, not the form behind it -- so
/// it's built to match the app's own Complete Payment form (Figma node
/// 1213:1281): the same card fields, and the same header/card/buttons as the
/// other Profile sub-screens. (Same situation as the Payment Success screen,
/// decision #23.)
///
/// **The real Payment flow's rules apply exactly** (decision #22): Card Number
/// / Expiry / CVV use [PaymentValidators] -- 16 digits, MM/YY not in the past,
/// 3-digit CVV -- and are checked before anything is saved.
///
/// **Only metadata is stored:** brand, last 4, expiry and the default flag. The
/// brand and last 4 are derived here from the typed number ([CardBrand]) purely
/// for display -- the same accepted training-project simplification as
/// `confirm_subscription_payment`, not a new one. The full number and the CVV
/// are validated for shape and then discarded: they are never passed to the
/// service (it has no parameter for them), never logged, never sent anywhere,
/// and the controllers are cleared and disposed. No autofill hints, so the
/// OS/browser never offers to save a card.
///
/// A user's first card becomes their default automatically (enforced in the
/// database); for later cards a checkbox asks whether to make this one the
/// default. Pops with `true` once saved.
class AddPaymentMethodScreen extends StatefulWidget {
  /// True when the user has no cards yet: the checkbox is hidden, since the
  /// first card is always the default.
  final bool isFirstCard;
  final PaymentMethodService service;

  const AddPaymentMethodScreen({
    super.key,
    required this.isFirstCard,
    this.service = const PaymentMethodService(),
  });

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
    // The card fields never leave this screen -- disposing (and clearing, in
    // _save) is belt-and-suspenders on top of the values never being copied
    // into any variable that outlives this State.
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    // Same shape checks as the real Payment flow, before anything is saved.
    if (!_formKey.currentState!.validate()) return;

    // The validators guarantee 16 digits and a well-formed, unexpired MM/YY.
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
      // Card fields are discarded here, never read again.
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
        _errorMessage = "Couldn't save your card. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                  title: 'Add Payment Method',
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
                          label: 'Card Number',
                          controller: _cardNumberController,
                          hint: '1234 5678 9012 3456',
                          validator: PaymentValidators.cardNumber,
                          keyboardType: TextInputType.number,
                          enabled: !_saving,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: PaymentField(
                                label: 'Expiry Date',
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
                                label: 'CVV',
                                controller: _cvvController,
                                hint: '123',
                                validator: PaymentValidators.cvv,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                enabled: !_saving,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
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
                                    'Set as default payment method',
                                    style: TextStyle(fontSize: 14, height: 20 / 14, letterSpacing: -0.15, color: colors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'For your security, only the card type, last 4 digits and expiry date '
                          'are saved — never your full card number or CVV.',
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
                    Expanded(child: CancelButton(onTap: _saving ? null : () => Navigator.of(context).pop())),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SaveButton(label: 'Save Card', saving: _saving, onTap: _saving ? null : _save),
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
