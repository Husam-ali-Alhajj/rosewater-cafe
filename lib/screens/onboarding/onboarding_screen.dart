import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  static const List<OnboardingPageData> _pages = [
    OnboardingPageData(
      icon: Icons.wine_bar,
      accentGradient: LinearGradient(
        colors: [Color(0xFFFF637E), Color(0xFFEC003F)],
      ),
      heading: 'Welcome to Rosewater Café',
      body:
          'Experience the finest hookah lounge with exclusive VIP memberships, premium services, and a luxurious atmosphere.',
    ),
    OnboardingPageData(
      icon: Icons.qr_code_2,
      accentGradient: LinearGradient(
        colors: [Color(0xFFC27AFF), Color(0xFF9810FA)],
      ),
      heading: 'QR Code Door Access',
      body:
          'Unlock the café with your personal QR code. Bring guests and track your visits effortlessly.',
    ),
    OnboardingPageData(
      icon: Icons.card_giftcard,
      accentGradient: LinearGradient(
        colors: [Color(0xFFFB84B6), Color(0xFFE60076)],
      ),
      heading: 'Monthly Allowances',
      body:
          'Enjoy included hookah sessions and drinks every month. Track your usage and maximize your membership benefits.',
    ),
    OnboardingPageData(
      icon: Icons.event,
      accentGradient: LinearGradient(
        colors: [Color(0xFFFFB900), Color(0xFFE17100)],
      ),
      heading: 'Exclusive Events',
      body:
          'Reserve the entire café for private events. Get priority booking and VIP discounts on special occasions.',
    ),
  ];

  final PageController _controller = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pages.length - 1;

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
    final currentGradient = _pages[_currentPage].accentGradient;
    final colors = context.colors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageBackgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _isLastPage
                      ? null
                      : TextButton(
                          onPressed: _goToNextDestination,
                          child: Text(
                            'Skip',
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
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) => Center(
                    child: _OnboardingCard(page: _pages[index]),
                  ),
                ),
              ),
              DotsIndicator(
                itemCount: _pages.length,
                currentIndex: _currentPage,
                activeGradient: currentGradient,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: _currentPage == 0
                    ? GradientButton(
                        label: 'Next',
                        onPressed: _next,
                        gradient: currentGradient,
                        trailingIcon: Icons.chevron_right,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedSecondaryButton(
                              label: 'Previous',
                              onPressed: _previous,
                              leadingIcon: Icons.chevron_left,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GradientButton(
                              label: _isLastPage ? 'Get Started' : 'Next',
                              onPressed: _next,
                              gradient: currentGradient,
                              trailingIcon: Icons.chevron_right,
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
                fontWeight: FontWeight.w500,
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
