import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/onboarding_prefs.dart';
import '../../services/settings_provider.dart';
import '../../theme/app_semantic_colors.dart';
import '../auth/auth_landing_screen.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/dots_indicator.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/onboarding_icon_badge.dart';
import '../../widgets/outlined_secondary_button.dart';
import 'onboarding_page_data.dart';

/// The 4-slide onboarding carousel shown on first launch (a future task will
/// decide exactly when this is skipped for returning users). Pure
/// UI/navigation — no backend calls.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<OnboardingPageData> _pages(AppLocalizations l10n) => [
        OnboardingPageData(
          icon: Icons.wine_bar,
          accentGradient: const LinearGradient(
            colors: [Color(0xFFFF637E), Color(0xFFEC003F)],
          ),
          heading: l10n.onboardingWelcomeHeading,
          body: l10n.onboardingWelcomeBody,
        ),
        OnboardingPageData(
          icon: Icons.qr_code_2,
          accentGradient: const LinearGradient(
            colors: [Color(0xFFC27AFF), Color(0xFF9810FA)],
          ),
          heading: l10n.onboardingQrHeading,
          body: l10n.onboardingQrBody,
        ),
        OnboardingPageData(
          icon: Icons.card_giftcard,
          accentGradient: const LinearGradient(
            colors: [Color(0xFFFB84B6), Color(0xFFE60076)],
          ),
          heading: l10n.onboardingAllowancesHeading,
          body: l10n.onboardingAllowancesBody,
        ),
        OnboardingPageData(
          icon: Icons.event,
          accentGradient: const LinearGradient(
            colors: [Color(0xFFFFB900), Color(0xFFE17100)],
          ),
          heading: l10n.onboardingEventsHeading,
          body: l10n.onboardingEventsBody,
        ),
      ];

  // The slide count itself doesn't depend on locale (same 4 slides for
  // every language), so this stays a plain constant rather than routing
  // through _pages(l10n) just to read a length.
  static const int _pageCount = 4;

  final PageController _controller = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pageCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToNextDestination() {
    // Fire-and-forget: a fast local write, not worth blocking navigation on.
    const OnboardingPrefs().markOnboardingSeen();
    Navigator.of(context).pushReplacement(
      appRoute(context, (_) => const AuthLandingScreen()),
    );
  }

  // Sprint 8 Task 3: the swipe/tap-through animation between slides is its
  // own explicit duration (a `PageController.nextPage`/`.previousPage` call,
  // not a route transition `appRoute` already covers) -- reads
  // `animationsEnabled` the same way, near-zero (not literally 0, same
  // reasoning as `AppPageRoute`) instead of removed outright.
  Duration get _pageAnimationDuration =>
      context.read<SettingsProvider>().animationsEnabled ? const Duration(milliseconds: 300) : const Duration(milliseconds: 1);

  void _next() {
    if (_isLastPage) {
      _goToNextDestination();
    } else {
      _controller.nextPage(
        duration: _pageAnimationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _previous() {
    _controller.previousPage(
      duration: _pageAnimationDuration,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final currentGradient = pages[_currentPage].accentGradient;
    final colors = context.colors;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // "Next" points toward reading-forward, "Previous" toward reading-back --
    // that's chevron_right/chevron_left in LTR and the reverse in RTL, not a
    // fixed pair of icons.
    final nextIcon = isRtl ? Icons.chevron_left : Icons.chevron_right;
    final previousIcon = isRtl ? Icons.chevron_right : Icons.chevron_left;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _isLastPage
                      ? null
                      : TextButton(
                          onPressed: _goToNextDestination,
                          child: Text(
                            l10n.skipButton,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              letterSpacing: -0.15,
                              height: 20 / 14,
                            ),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) => Center(
                    child: _OnboardingCard(page: pages[index]),
                  ),
                ),
              ),
              DotsIndicator(
                itemCount: pages.length,
                currentIndex: _currentPage,
                activeGradient: currentGradient,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: _currentPage == 0
                    ? GradientButton(
                        label: l10n.nextButton,
                        onPressed: _next,
                        gradient: currentGradient,
                        trailingIcon: nextIcon,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedSecondaryButton(
                              label: l10n.previousButton,
                              onPressed: _previous,
                              leadingIcon: previousIcon,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GradientButton(
                              label: _isLastPage ? l10n.getStartedButton : l10n.nextButton,
                              onPressed: _next,
                              gradient: currentGradient,
                              trailingIcon: nextIcon,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  final OnboardingPageData page;

  const _OnboardingCard({required this.page});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 50,
              offset: const Offset(0, 25),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OnboardingIconBadge(icon: page.icon, gradient: page.accentGradient),
            const SizedBox(height: 24),
            Text(
              page.heading,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                height: 36 / 30,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.44,
                height: 29.3 / 18,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
