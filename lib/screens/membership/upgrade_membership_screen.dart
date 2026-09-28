import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/membership_plan.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/membership_plan_card.dart';
import '../../widgets/screen_header.dart';
import 'payment_screen.dart';

/// Sprint 9 Task 4 -- Upgrade Membership: only ever reachable from
/// Profile's own gate (a plan strictly more expensive than the current
/// one must exist, checked there via [SubscriptionService.hasUpgradeOption]
/// before the button even shows), so this screen doesn't re-check that
/// and show its own empty state for the ordinary case -- a defensive
/// message below covers the narrow window where it could still happen
/// (prices changed server-side between Profile's check and this screen's
/// own fetch).
///
/// Deliberately fetches the FULL plan catalog itself, live, rather than
/// taking a pre-filtered list -- [rank] (the tier icon/gradient) has to
/// be each plan's position in the full price-sorted catalog, not this
/// screen's own shorter one, or a Premium card shown here would render
/// with the wrong tier's icon and colour.
///
/// Selecting a plan routes straight into the existing [PaymentScreen]
/// (`.upgrade` constructor) -- no ID Upload step, unlike the
/// Choose-Membership-on-signup flow: an upgrade doesn't need the member
/// re-verified, they're already a verified, paying member.
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
      // Cheapest first, same as Choose Membership -- so `rank` (this
      // list's own index) always matches each plan's real tier.
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
    Navigator.of(context).push(
      appRoute(context, (_) => PaymentScreen.upgrade(plan: plan)),
    );
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
                                // Defensive only -- Profile's own gate
                                // (hasUpgradeOption) should mean this
                                // screen is never reached with nothing
                                // to show. Covers the narrow race where
                                // plan prices changed between that check
                                // and this screen's own fetch.
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
