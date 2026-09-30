import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/membership_plan.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/membership_plan_card.dart';
import '../../widgets/screen_header.dart';
import 'payment_screen.dart';

/// Shows only the plans that cost more than the current one. Profile hides the button when there
/// are none (VIP).
///
/// Loads the full plan list so each card keeps its real tier colour. Choosing a plan goes straight
/// to payment; no new ID check is needed.
class UpgradeMembershipScreen extends StatefulWidget {
  final MembershipPlan currentPlan;

  const UpgradeMembershipScreen({super.key, required this.currentPlan});

  @override
  State<UpgradeMembershipScreen> createState() => _UpgradeMembershipScreenState();
}

class _UpgradeMembershipScreenState extends State<UpgradeMembershipScreen> {
  final _subscriptionService = const SubscriptionService();

  bool _loading = true;
  List<MembershipPlan> _eligiblePlans = [];
  List<int> _eligibleRanks = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Cheapest first, so the index matches each plan's tier.
      final allPlans = await _subscriptionService.fetchPlans();
      if (!mounted) return;
      final plans = <MembershipPlan>[];
      final ranks = <int>[];
      for (var rank = 0; rank < allPlans.length; rank++) {
        final plan = allPlans[rank];
        if (plan.priceCents > widget.currentPlan.priceCents) {
          plans.add(plan);
          ranks.add(rank);
        }
      }
      setState(() {
        _eligiblePlans = plans;
        _eligibleRanks = ranks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = AppLocalizations.of(context).couldNotLoadPlansError;
      });
    }
  }

  void _selectPlan(MembershipPlan plan) {
    Navigator.of(context).push(appRoute(context, (_) => PaymentScreen.upgrade(plan: plan)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: l10n.upgradeMembershipButton, onBack: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.upgradeMembershipSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.31,
                                  color: colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: colors.danger),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else if (_eligiblePlans.isEmpty)
                                // Shouldn't happen (Profile hides the button), but covers prices
                                // changing in the meantime.
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32),
                                  child: Text(
                                    l10n.noUpgradeAvailable,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, color: colors.textMuted),
                                  ),
                                )
                              else
                                for (var i = 0; i < _eligiblePlans.length; i++) ...[
                                  MembershipPlanCard(
                                    plan: _eligiblePlans[i],
                                    rank: _eligibleRanks[i],
                                    isSubmitting: false,
                                    onSelect: () => _selectPlan(_eligiblePlans[i]),
                                    actionLabel: l10n.upgradeToPlanButton(_eligiblePlans[i].name),
                                    submittingLabel: l10n.upgradingEllipsis,
                                  ),
                                  if (i < _eligiblePlans.length - 1) const SizedBox(height: 16),
                                ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
