import 'package:flutter/material.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_page_route.dart';
import '../events/events_tab.dart';
import '../membership/choose_membership_screen.dart';
import '../profile/profile_screen.dart';
import '../qr_access/qr_access_screen.dart';
import 'home_screen.dart';

const _homeTab = 0;
const _qrCodeTab = 1;
const _eventsTab = 2;
const _profileTab = 3;

/// The signed-in app: four tabs (Home, QR Code, Events, Profile). IndexedStack keeps each tab's
/// state when switching.
///
/// The membership and profile are loaded once here and shared with the tabs. If there's no active
/// membership, the user is sent to Choose Membership. A failed profile load doesn't block the app;
/// each tab handles the missing profile itself.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _subscriptionService = const SubscriptionService();
  final _profileService = const ProfileService();

  int _index = _homeTab;
  bool _loading = true;
  late final ActiveMembership _membership;

  /// Kept here so a profile change (new name or photo) shows on every tab at once.
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Profile?> _fetchProfileOrNull() async {
    try {
      return await _profileService.fetchCurrentProfile();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    // Started together so both queries run in parallel.
    final membershipFuture = _subscriptionService.fetchActiveMembership();
    final profileFuture = _fetchProfileOrNull();
    final membership = await membershipFuture;
    final profile = await profileFuture;
    if (!mounted) return;
    if (membership == null) {
      Navigator.of(
        context,
      ).pushAndRemoveUntil(appRoute(context, (_) => const ChooseMembershipScreen()), (route) => false);
      return;
    }
    _membership = membership;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  void _goToTab(int index) => setState(() => _index = index);

  void _onProfileChanged(Profile profile) => setState(() => _profile = profile);

  /// Rebuilt every time so each tab gets the latest profile. IndexedStack keeps their state.
  List<Widget> _buildTabs() => [
    HomeScreen(
      membership: _membership,
      profile: _profile,
      onGoToQrCode: () => _goToTab(_qrCodeTab),
      onGoToEvents: () => _goToTab(_eventsTab),
      onGoToProfile: () => _goToTab(_profileTab),
    ),
    QrAccessScreen(membership: _membership, profile: _profile, onBackToDashboard: () => _goToTab(_homeTab)),
    EventsTab(onGoToHome: () => _goToTab(_homeTab)),
    ProfileScreen(membership: _membership, profile: _profile, onProfileChanged: _onProfileChanged),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: context.colors.pageBackgroundGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return Scaffold(
      body: IndexedStack(index: _index, children: _buildTabs()),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, onTap: _goToTab),
    );
  }
}
