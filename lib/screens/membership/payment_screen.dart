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

/// Real "Complete Payment" screen (Figma node 1213:1281). Card fields are
/// validated client-side purely for realistic UX (this is a training
/// project with no real payment processor — see docs/decisions.md #4) and
/// are never sent anywhere: not to Supabase, not logged, not persisted.
/// `confirm_subscription_payment` takes only the subscription id.
///
/// Plan comes in via constructor from IdUploadScreen's own already-fetched
/// state, not re-fetched here — this screen makes zero database reads.
///
/// Sprint 9 Task 4: reused as-is for Upgrade Membership too, via the
/// [PaymentScreen.upgrade] constructor -- same card form, same "Pay"
/// button, same success screen; only [_pay] branches on [isUpgrade] to
/// call `upgrade_subscription(plan.id)` instead of
/// `confirm_subscription_payment(subscriptionId)`. [subscriptionId] is
/// null in that mode: an upgrade has no separate pending row to confirm,
/// unlike a brand-new signup.
///
/// **Saved cards (decision #77):** the user's saved payment methods are
/// listed under "Pay with", default (non-expired) card preselected, so
/// paying is one tap; "Use a new card" shows the card form, with a "Save
/// this card for next time" checkbox. Payment is still simulated, so
/// "paying with" a saved card means choosing it instead of typing -- no
/// card data goes to the payment RPCs either way. A new card is saved
/// (brand/last 4/expiry only, same as Payment Methods) only AFTER the
/// payment succeeds, and a failure to save it never undoes the payment.
/// With no saved cards (e.g. a brand-new signup) the screen is exactly the
/// plain form it always was.
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

  /// Null while loading; empty if the user has none (or they couldn't be
  /// loaded -- then the plain form is shown, as before).
  List<PaymentMethod>? _savedCards;

  /// The saved card being paid with, or null for "Use a new card".
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
      cards = const []; // fall back to the plain form rather than an error
    }
    if (!mounted) return;
    final usable = cards.where((c) => !_isExpired(c)).toList();
    setState(() {
      _savedCards = cards;
      // Default card first (list() orders it first), else the newest usable one.
      _selectedCardId = usable.isEmpty
          ? null
          : (usable.firstWhere((c) => c.isDefault, orElse: () => usable.first)).id;
    });
  }

  /// Best-effort: the payment already succeeded, so a failure here is
  /// swallowed rather than shown as if the payment had failed.
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
    // Card fields never leave this screen — clearing on the way out is
    // belt-and-suspenders on top of the controllers being destroyed here;
    // neither ever wrote these values to a variable outside this State.
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_isPaying) return;
    // A saved card has nothing to type, so nothing to validate.
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
      context.triggerSuccess(); // Sprint 8 Task 4: payment confirmed
      // Card fields are discarded here, never read again after validation —
      // clearing explicitly before navigating away, on top of dispose().
      _cardNumberController.clear();
      _expiryController.clear();
      _cvvController.clear();
      Navigator.of(context).pushAndRemoveUntil(
        appRoute(context, (_) => PaymentSuccessScreen(plan: widget.plan)),
        (route) => false,
      );
    } on ConfirmPaymentFailure catch (e) {
      if (!mounted) return;
      context.triggerError(); // Sprint 8 Task 4: failed payment
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
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 0.07, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.planSuffix(plan.name),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.31, color: colors.textMuted),
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.inputFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.monthlySubscription,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.31, color: colors.textMuted),
                                ),
                                Text(
                                  '\$${plan.priceDollars}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.31, color: colors.textPrimary),
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
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.31, color: colors.textPrimary),
                                ),
                                Text(
                                  '\$${plan.priceDollars}',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 0.07, color: colors.textPrimary),
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
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
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
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // A plain Checkbox + label rather than CheckboxListTile:
                          // a ListTile can't paint on this screen's coloured card.
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
                        Text(_errorMessage!, style: TextStyle(color: colors.danger, fontSize: 12), textAlign: TextAlign.center),
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

/// One "Pay with" choice: a saved card, or "Use a new card".
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
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: muted ? colors.danger : colors.textMuted),
                      ),
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
