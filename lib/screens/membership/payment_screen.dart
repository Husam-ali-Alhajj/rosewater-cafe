import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/membership_plan.dart';
import '../../models/payment_method.dart';
import '../../services/payment_method_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../utils/app_feedback.dart';
import '../../utils/card_brand.dart';
import '../../utils/payment_validators.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/outlined_secondary_button.dart';
import 'payment_success_screen.dart';
import '../../widgets/payment_fields.dart';

/// Complete Payment. There's no real payment processor yet: card details are only checked on the
/// device, never sent or stored.
///
/// Also used for upgrades ([PaymentScreen.upgrade]), which call upgrade_subscription instead of
/// confirm_subscription_payment.
///
/// Saved cards are listed under "Pay with" with the default one selected. "Use a new card" shows
/// the form, with an option to save the card (brand, last 4 and expiry only), which is saved only
/// after the payment succeeds.
class PaymentScreen extends StatefulWidget {
  final String? subscriptionId;
  final MembershipPlan plan;
  final bool isUpgrade;
  final PaymentMethodService paymentMethodService;
  final SubscriptionService subscriptionService;

  const PaymentScreen({
    super.key,
    required this.subscriptionId,
    required this.plan,
    this.paymentMethodService = const PaymentMethodService(),
    this.subscriptionService = const SubscriptionService(),
  }) : isUpgrade = false;

  const PaymentScreen.upgrade({
    super.key,
    required this.plan,
    this.paymentMethodService = const PaymentMethodService(),
    this.subscriptionService = const SubscriptionService(),
  }) : subscriptionId = null,
       isUpgrade = true;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isPaying = false;
  String? _errorMessage;

  /// Null while loading. Empty if there are none or they failed to load; then the plain form is
  /// shown.
  List<PaymentMethod>? _savedCards;

  /// The selected saved card, or null for "Use a new card".
  String? _selectedCardId;
  bool _saveNewCard = false;

  bool get _usingNewCard => _selectedCardId == null;

  static bool _isExpired(PaymentMethod card) {
    final now = DateTime.now();
    return card.expYear < now.year || (card.expYear == now.year && card.expMonth < now.month);
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    List<PaymentMethod> cards;
    try {
      cards = await widget.paymentMethodService.list();
    } catch (_) {
      cards = const [];
    }
    if (!mounted) return;
    final usable = cards.where((c) => !_isExpired(c)).toList();
    setState(() {
      _savedCards = cards;
      // The default card if it's usable, otherwise the newest one.
      _selectedCardId = usable.isEmpty ? null : (usable.firstWhere((c) => c.isDefault, orElse: () => usable.first)).id;
    });
  }

  /// The payment already went through, so a failed save is ignored.
  Future<void> _saveEnteredCard() async {
    final number = _cardNumberController.text;
    final expiry = _expiryController.text;
    try {
      await widget.paymentMethodService.add(
        brand: CardBrand.detect(number),
        last4: CardBrand.lastFour(number)!,
        expMonth: int.parse(expiry.substring(0, 2)),
        expYear: 2000 + int.parse(expiry.substring(3, 5)),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    // Clear the card fields when leaving.
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_isPaying) return;
    // Nothing to check when paying with a saved card.
    if (_usingNewCard && !_formKey.currentState!.validate()) return;

    setState(() {
      _isPaying = true;
      _errorMessage = null;
    });
    try {
      if (widget.isUpgrade) {
        await widget.subscriptionService.upgradeSubscription(widget.plan.id);
      } else {
        await widget.subscriptionService.confirmSubscriptionPayment(widget.subscriptionId!);
      }
      if (_usingNewCard && _saveNewCard) await _saveEnteredCard();
      if (!mounted) return;
      context.triggerSuccess();
      // Clear the card fields before leaving.
      _cardNumberController.clear();
      _expiryController.clear();
      _cvvController.clear();
      Navigator.of(
        context,
      ).pushAndRemoveUntil(appRoute(context, (_) => PaymentSuccessScreen(plan: widget.plan)), (route) => false);
    } on ConfirmPaymentFailure catch (e) {
      if (!mounted) return;
      context.triggerError();
      setState(() {
        _isPaying = false;
        _errorMessage = e.message;
      });
    } on UpgradeSubscriptionFailure catch (e) {
      if (!mounted) return;
      context.triggerError();
      setState(() {
        _isPaying = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      context.triggerError();
      setState(() {
        _isPaying = false;
        _errorMessage = AppLocalizations.of(context).paymentFailedError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.credit_card_outlined, size: 64, color: Color(0xFFFF2056)),
                      const SizedBox(height: 12),
                      Text(
                        l10n.completePayment,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.07,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.planSuffix(plan.name),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.31,
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.monthlySubscription,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.31,
                                    color: colors.textMuted,
                                  ),
                                ),
                                Text(
                                  '\$${plan.priceDollars}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.31,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Divider(color: colors.border, height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.totalLabel,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.31,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '\$${plan.priceDollars}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.07,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (_savedCards == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        if (_savedCards!.isNotEmpty) ...[
                          Text(
                            l10n.payWithLabel,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          for (final card in _savedCards!)
                            _PayOption(
                              key: ValueKey('saved-card-${card.id}'),
                              selected: _selectedCardId == card.id,
                              enabled: !_isExpired(card) && !_isPaying,
                              onTap: () => setState(() => _selectedCardId = card.id),
                              title: '${card.brand} •••• ${card.last4}',
                              subtitle: _isExpired(card)
                                  ? l10n.cardExpiredLabel
                                  : l10n.cardExpiryShort(
                                      '${card.expMonth.toString().padLeft(2, '0')}/${(card.expYear % 100).toString().padLeft(2, '0')}',
                                    ),
                              badge: card.isDefault ? l10n.defaultBadge : null,
                            ),
                          _PayOption(
                            key: const ValueKey('new-card-option'),
                            selected: _usingNewCard,
                            enabled: !_isPaying,
                            onTap: () => setState(() => _selectedCardId = null),
                            title: l10n.useNewCardOption,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_usingNewCard) ...[
                          PaymentField(
                            label: l10n.cardNumberLabel,
                            controller: _cardNumberController,
                            hint: '1234 5678 9012 3456',
                            validator: PaymentValidators.cardNumber,
                            keyboardType: TextInputType.number,
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
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // A plain checkbox and label; a CheckboxListTile can't draw on this
                          // coloured card.
                          InkWell(
                            key: const ValueKey('save-card-checkbox'),
                            onTap: _isPaying ? null : () => setState(() => _saveNewCard = !_saveNewCard),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _saveNewCard,
                                  activeColor: colors.accent,
                                  onChanged: _isPaying ? null : (v) => setState(() => _saveNewCard = v ?? false),
                                ),
                                Expanded(
                                  child: Text(
                                    l10n.saveCardForNextTime,
                                    style: TextStyle(fontSize: 14, color: colors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: colors.danger, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedSecondaryButton(
                              label: l10n.backButton,
                              buttonHeight: 36,
                              borderWidth: 1,
                              onPressed: _isPaying ? null : () => Navigator.of(context).maybePop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              label: _isPaying ? l10n.payingEllipsis : l10n.payAmountButton('\$${plan.priceDollars}'),
                              height: 36,
                              fontSize: 14,
                              onPressed: _isPaying ? null : _pay,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One "Pay with" option: a saved card or "Use a new card".
class _PayOption extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final String? badge;

  const _PayOption({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = !enabled && !selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.accent.withValues(alpha: 0.08) : colors.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? colors.accent : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? colors.accent : colors.textMuted.withValues(alpha: muted ? 0.4 : 1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: muted ? colors.textMuted.withValues(alpha: 0.5) : colors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: TextStyle(fontSize: 12, color: muted ? colors.danger : colors.textMuted)),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.success),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
