import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/membership_plan.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/membership_plan_card.dart';
import 'id_upload_screen.dart';

/// Lists the plans from the database. Choosing one creates a pending subscription
/// (start_subscription) and moves on to ID upload.
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

  /// Always shows the plans. Choosing one replaces any unpaid membership from earlier.
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
        _errorMessage = AppLocalizations.of(context).couldNotLoadPlansError;
      });
    }
  }

  /// Pushed (not replaced) so the user can come back here from ID upload. The plans are still
  /// loaded, so we only reset the "Selecting..." state.
  void _goToIdUpload(String subscriptionId) {
    Navigator.of(context).push(appRoute(context, (_) => IdUploadScreen(subscriptionId: subscriptionId))).then((_) {
      if (!mounted) return;
      setState(() {
        _selectingPlanId = null;
        _errorMessage = null;
      });
    });
  }

  Future<void> _selectPlan(MembershipPlan plan) async {
    if (_selectingPlanId != null) return;
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
        _errorMessage = AppLocalizations.of(context).genericConnectionError;
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.chooseYourMembership,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.37,
                          color: colors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.selectPlanSubtitle,
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
                        MembershipPlanCard(
                          plan: entry.value,
                          rank: entry.key,
                          isSubmitting: _selectingPlanId == entry.value.id,
                          onSelect: _selectingPlanId == null ? () => _selectPlan(entry.value) : null,
                          actionLabel: l10n.selectPlanButton(entry.value.name),
                          submittingLabel: l10n.selectingEllipsis,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          l10n.allPlansFooter,
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
