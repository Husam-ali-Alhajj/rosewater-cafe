import 'package:flutter/material.dart';
import '../../models/membership_plan.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/onboarding_icon_badge.dart';
import 'id_upload_screen.dart';

/// Real "Choose Your Membership" screen (Figma page 8): fetches
/// membership_plans live from Supabase (no hardcoded plans, no hardcoded
/// "Most Popular" index) and, on selection, calls the start_subscription
/// RPC (see docs/decisions.md #4 and the Task 1 migration) to create a
/// real pending subscription row before moving on to ID Upload.
class ChooseMembershipScreen extends StatefulWidget {
  const ChooseMembershipScreen({super.key});

  @override
  State<ChooseMembershipScreen> createState() => _ChooseMembershipScreenState();
}

class _ChooseMembershipScreenState extends State<ChooseMembershipScreen> {
  final _subscriptionService = const SubscriptionService();

  bool _loading = true;
  List<MembershipPlan> _plans = [];
  String? _selectingPlanId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Always shows the plan cards — deliberately does NOT check for an
  /// existing pending subscription and auto-skip to ID Upload the way an
  /// earlier version did. That auto-resume behavior was explicitly reversed
  /// by the user after live testing: signing in should show Choose
  /// Membership first, full stop. Actual duplicate-prevention still lives
  /// where it belongs regardless — start_subscription's own
  /// `pending_subscription_exists` check (Task 1) — so re-selecting a plan
  /// while one is already pending surfaces a clear inline message instead
  /// of silently creating a second row; it just no longer happens via a
  /// surprise redirect before the user ever sees the cards.
  Future<void> _init() async {
    try {
      final plans = await _subscriptionService.fetchPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Could not load membership plans. Check your connection and try again.';
      });
    }
  }

  /// Pushed (not replaced) deliberately: Choose Membership must still be
  /// reachable by backing out of ID Upload. Regardless of *how* the ID
  /// Upload route ends up popped — hardware back, "Back to Plans" (which
  /// already cancelled the pending subscription itself), or the whole
  /// stack being cleared by a successful Payment further up — the cards
  /// are already loaded and remain valid, so there's nothing to redo here
  /// beyond clearing the "Selecting…" state so the buttons are usable
  /// again.
  void _goToIdUpload(String subscriptionId) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => IdUploadScreen(subscriptionId: subscriptionId),
          ),
        )
        .then((_) {
          if (!mounted) return;
          setState(() {
            _selectingPlanId = null;
            _errorMessage = null;
          });
        });
  }

  Future<void> _selectPlan(MembershipPlan plan) async {
    if (_selectingPlanId != null) return; // same re-entry guard used on Sign In / Create Account
    setState(() {
      _selectingPlanId = plan.id;
      _errorMessage = null;
    });
    try {
      final subscriptionId = await _subscriptionService.startSubscription(plan.id);
      if (!mounted) return;
      _goToIdUpload(subscriptionId);
    } on StartSubscriptionFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _selectingPlanId = null;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectingPlanId = null;
        _errorMessage = 'Something went wrong. Check your connection and try again.';
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Choose Your Membership',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.37,
                                color: colors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select the plan that fits your lifestyle',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.31,
                                color: colors.textMuted,
                              ),
                              textAlign: TextAlign.center,
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
                              ),
                            for (final entry in _plans.asMap().entries) ...[
                              _MembershipCard(
                                plan: entry.value,
                                rank: entry.key,
                                isSubmitting: _selectingPlanId == entry.value.id,
                                onSelect: _selectingPlanId == null ? () => _selectPlan(entry.value) : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'All plans include member discounts. Guest orders not included in allowance.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.15,
                                  color: colors.textMuted,
                                ),
                                textAlign: TextAlign.center,
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

IconData _iconForRank(int rank) => switch (rank) {
  0 => Icons.star,
  1 => Icons.auto_awesome,
  _ => Icons.workspace_premium,
};

Gradient _gradientForRank(int rank) => switch (rank) {
  0 => AppColors.membershipBasicGradient,
  1 => AppColors.membershipPremiumGradient,
  _ => AppColors.membershipVipGradient,
};

class _MembershipCard extends StatelessWidget {
  final MembershipPlan plan;
  final int rank;
  final bool isSubmitting;
  final VoidCallback? onSelect;

  const _MembershipCard({
    required this.plan,
    required this.rank,
    required this.isSubmitting,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientForRank(rank);
    final icon = _iconForRank(rank);
    final highlighted = plan.isPopular;
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          // The highlighted card's border stays the brand's premium-lilac
          // accent in both modes; the plain cards' border is a theme-aware
          // hairline so it doesn't vanish against a dark card.
          color: highlighted ? AppColors.membershipPremiumBorder : colors.border,
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        children: [
          if (highlighted)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.membershipPopularBadge,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Most Popular',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
              ),
            ),
          OnboardingIconBadge(icon: icon, gradient: gradient, size: 64),
          const SizedBox(height: 12),
          Text(
            plan.name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: 0.07, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '\$${plan.priceDollars}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.37,
                    color: colors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: '/month',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.31,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Column(
            children: [
              for (final bullet in plan.featureBullets)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 16, color: AppColors.membershipCheckmark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bullet,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.15,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 48),
          GradientButton(
            label: isSubmitting ? 'Selecting…' : 'Select ${plan.name}',
            gradient: gradient,
            onPressed: onSelect,
            height: 38,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}
