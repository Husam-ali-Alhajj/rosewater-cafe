import 'package:flutter/material.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_nav.dart';
import '../events/events_tab.dart';
import '../membership/choose_membership_screen.dart';
import '../profile/profile_screen.dart';
import '../qr_access/qr_access_screen.dart';
import 'home_screen.dart';

const _homeTab = 0;
const _qrCodeTab = 1;
const _eventsTab = 2;
// Profile is index 3, referenced only positionally below -- no named
// constant needed since nothing ever navigates to it programmatically.
// (Its real screen is `ProfileScreen`, Sprint 5 Task 1.)

/// The authenticated app's real entry point once a member has an active
/// subscription: a persistent 4-tab bottom nav (Home / QR Code / Events /
/// Profile) matching the Figma `BottomNav` component, replacing the old
/// flat `ComingSoonScreen(label: 'Home')` destination used everywhere
/// before this sprint.
///
/// All four tabs are built out. `IndexedStack` (not swapping the child
/// widget per tap) keeps each tab's state alive across switches, matching
/// how a real tabbed app behaves.
///
/// `ActiveMembership` and the user's `Profile` are each fetched exactly once,
/// here, and handed down to `HomeScreen`, `QrAccessScreen` and
/// `ProfileScreen` -- Sprint 4 Task 2 explicitly asked for the QR screen's
/// guest-count cap to reuse Home's already-fetched plan data rather than
/// re-querying it, and the profile (Home's greeting/member ID, QR's member
/// ID, Profile's details) is shared the same way instead of three screens
/// each querying the same row. So the fetch (and the "no active membership
/// -- bounce to Choose Membership" defensive check from decision #27) lives
/// here, the one place every tab can share it.
///
/// A failed profile fetch does not block the app: it becomes `null`, and
/// each tab degrades on its own (Home's plain "Welcome!", QR's "Unable to
/// load your member ID", Profile's retry prompt). The shell also owns the
/// profile afterwards: Edit Profile and the Profile tab's retry hand a new
/// one back here, and every tab is rebuilt with it.
///
/// Sign Out lives on the Profile tab (and Logout in Home's header, as the
/// design has both) -- see docs/decisions.md #21/#26/#41.
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

  /// Owned here (not by the tabs) so a change made on one tab -- Edit Profile
  /// saving a new name or photo -- shows on all of them at once.
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
    // Started together so the two queries run in parallel.
    final membershipFuture = _subscriptionService.fetchActiveMembership();
    final profileFuture = _fetchProfileOrNull();
    final membership = await membershipFuture;
    final profile = await profileFuture;
    if (!mounted) return;
    if (membership == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ChooseMembershipScreen()),
        (route) => false,
      );
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

  /// Built on every build (not once): the tabs are cheap widgets, and
  /// rebuilding them is what hands a changed profile to each one. Flutter
  /// keeps every tab's State across these rebuilds because each keeps its
  /// position and type in the `IndexedStack`.
  List<Widget> _buildTabs() => [
    HomeScreen(
      membership: _membership,
      profile: _profile,
      onGoToQrCode: () => _goToTab(_qrCodeTab),
      onGoToEvents: () => _goToTab(_eventsTab),
    ),
    QrAccessScreen(
      membership: _membership,
      profile: _profile,
      onBackToDashboard: () => _goToTab(_homeTab),
    ),
    EventsTab(onGoToHome: () => _goToTab(_homeTab)),
    ProfileScreen(
      membership: _membership,
      profile: _profile,
      onProfileChanged: _onProfileChanged,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
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
