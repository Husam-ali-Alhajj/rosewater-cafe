import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/membership_plan.dart';
import '../theme/app_colors.dart';
import '../theme/app_semantic_colors.dart';
import '../utils/membership_localization.dart';
import 'gradient_button.dart';
import 'onboarding_icon_badge.dart';

/// The plan's tier icon. [rank] is the plan's position among ALL plans (0 = cheapest), so Premium
/// looks like Premium even on the upgrade screen, where the list is shorter.
IconData iconForPlanRank(int rank) => switch (rank) {
  0 => Icons.star,
  1 => Icons.auto_awesome,
  _ => Icons.workspace_premium,
};

Gradient gradientForPlanRank(int rank) => switch (rank) {
  0 => AppColors.membershipBasicGradient,
  1 => AppColors.membershipPremiumGradient,
  _ => AppColors.membershipVipGradient,
};

/// One plan card, shared by Choose Membership and Upgrade Membership. Only the button labels
/// differ, so they're passed in.
class MembershipPlanCard extends StatelessWidget {
  final MembershipPlan plan;
  final int rank;
  final bool isSubmitting;
  final VoidCallback? onSelect;
  final String actionLabel;
  final String submittingLabel;

  const MembershipPlanCard({
    super.key,
    required this.plan,
    required this.rank,
    required this.isSubmitting,
    required this.onSelect,
    required this.actionLabel,
    required this.submittingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = gradientForPlanRank(rank);
    final icon = iconForPlanRank(rank);
    final highlighted = plan.isPopular;
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          // The highlighted card keeps its purple border in both themes; the others use a theme
          // border so they stay visible in dark mode.
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
              child: Text(
                l10n.mostPopularBadge,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
              ),
            ),
          OnboardingIconBadge(icon: icon, gradient: gradient, size: 64),
          const SizedBox(height: 12),
          Text(
            plan.name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 0.07, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '\$${plan.priceDollars}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.37,
                    color: colors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: l10n.perMonthSuffix,
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
              for (final bullet in localizedFeatureBullets(plan, l10n))
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
            label: isSubmitting ? submittingLabel : actionLabel,
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
