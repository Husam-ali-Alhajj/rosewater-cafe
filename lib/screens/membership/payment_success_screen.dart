import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/membership_plan.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/onboarding_icon_badge.dart';
import '../home/main_shell.dart';

/// Temporary payment-success confirmation screen — no Figma frame exists
/// for this specific state (searched the whole file via the API; the only
/// "Payment Successful" text in the design is a notification list item, not
/// a dedicated screen), and the task itself frames this as a placeholder
/// ahead of the real Home Dashboard (Sprint 3). Built to match the app's
/// existing visual language (same card/gradient treatment as every other
/// screen in this flow) rather than inventing an unrelated look.
///
/// Takes the plan via constructor from PaymentScreen's own already-known
/// state — the last hop in a chain that started with Choose Membership's
/// real fetch, so this screen (like every screen before it in the flow)
/// makes zero database reads and has zero hardcoded plan data.
class PaymentSuccessScreen extends StatelessWidget {
  final MembershipPlan plan;

  const PaymentSuccessScreen({super.key, required this.plan});

  void _continue(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      appRoute(context, (_) => const MainShell()),
      (route) => false,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: OnboardingIconBadge(
                        icon: Icons.check,
                        gradient: LinearGradient(
                          colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        size: 88,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.youAreMember,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.welcomeMembershipActive(plan.name),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: colors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    GradientButton(label: l10n.continueButton, onPressed: () => _continue(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
