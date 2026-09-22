import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/membership_plan.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/payment_validators.dart';
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
class PaymentScreen extends StatefulWidget {
  final String subscriptionId;
  final MembershipPlan plan;

  const PaymentScreen({super.key, required this.subscriptionId, required this.plan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subscriptionService = const SubscriptionService();

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isPaying = false;
  String? _errorMessage;

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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPaying = true;
      _errorMessage = null;
    });
    try {
      await _subscriptionService.confirmSubscriptionPayment(widget.subscriptionId);
      if (!mounted) return;
      // Card fields are discarded here, never read again after validation —
      // clearing explicitly before navigating away, on top of dispose().
      _cardNumberController.clear();
      _expiryController.clear();
      _cvvController.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PaymentSuccessScreen(plan: widget.plan)),
        (route) => false,
      );
    } on ConfirmPaymentFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isPaying = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPaying = false;
        _errorMessage = 'Payment failed. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.credit_card_outlined, size: 64, color: Color(0xFFFF2056)),
                      const SizedBox(height: 12),
                      const Text(
                        'Complete Payment',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: 0.07, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plan.name} Plan',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.31, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Monthly Subscription',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.31, color: AppColors.textMuted),
                                ),
                                Text(
                                  '\$${plan.priceDollars}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.31, color: AppColors.membershipPriceText),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: Colors.black12, height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.31, color: AppColors.membershipPriceText),
                                ),
                                Text(
                                  '\$${plan.priceDollars}',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0.07, color: AppColors.membershipPriceText),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      PaymentField(
                        label: 'Card Number',
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
                              label: 'Expiry Date',
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
                              label: 'CVV',
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
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: TextStyle(color: AppColors.danger, fontSize: 12), textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedSecondaryButton(
                              label: 'Back',
                              buttonHeight: 36,
                              borderWidth: 1,
                              onPressed: _isPaying ? null : () => Navigator.of(context).maybePop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              label: _isPaying ? 'Paying…' : 'Pay \$${plan.priceDollars}',
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
