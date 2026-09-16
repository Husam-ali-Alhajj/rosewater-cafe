import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/coming_soon_screen.dart';
import '../events/events_tab.dart';
import '../membership/choose_membership_screen.dart';
import '../qr_access/qr_access_screen.dart';
import 'home_screen.dart';

const _homeTab = 0;
const _qrCodeTab = 1;
const _eventsTab = 2;
// Profile is index 3, referenced only positionally below -- no named
// constant needed since nothing ever navigates to it programmatically.

/// The authenticated app's real entry point once a member has an active
/// subscription: a persistent 4-tab bottom nav (Home / QR Code / Events /
/// Profile) matching the Figma `BottomNav` component, replacing the old
/// flat `ComingSoonScreen(label: 'Home')` destination used everywhere
/// before this sprint.
///
/// Home, QR Code, and Events are built out so far; Profile stays a
/// `ComingSoonScreen` stub until its own task. `IndexedStack`
/// (not swapping the child widget per tap) keeps each tab's state alive
/// across switches, matching how a real tabbed app behaves.
///
/// `ActiveMembership` is fetched exactly once, here, and handed down to
/// both `HomeScreen` and `QrAccessScreen` -- Sprint 4 Task 2 explicitly
/// asked for the QR screen's guest-count cap to reuse Home's already-
/// fetched plan data rather than re-querying it a second time, so the
/// fetch (and the "no active membership -- bounce to Choose Membership"
/// defensive check from decision #27) moved up from `HomeScreen` to here,
/// the one place both tabs can share it.
///
/// Sign Out moved here from the old Home placeholder onto the Profile tab
/// -- see docs/decisions.md #21/#26 -- since Profile is the natural
/// interim home for it even as a stub, closer to where the design actually
/// puts account actions than a bare Home screen ever was.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _subscriptionService = const SubscriptionService();

  int _index = _homeTab;
  bool _loading = true;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final membership = await _subscriptionService.fetchActiveMembership();
    if (!mounted) return;
    if (membership == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ChooseMembershipScreen()),
        (route) => false,
      );
      return;
    }
    _tabs = [
      HomeScreen(
        membership: membership,
        onGoToQrCode: () => _goToTab(_qrCodeTab),
        onGoToEvents: () => _goToTab(_eventsTab),
      ),
      QrAccessScreen(
        membership: membership,
        onBackToDashboard: () => _goToTab(_homeTab),
      ),
      EventsTab(onGoToHome: () => _goToTab(_homeTab)),
      const ComingSoonScreen(label: 'Profile', showSignOut: true),
    ];
    setState(() => _loading = false);
  }

  void _goToTab(int index) => setState(() => _index = index);

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
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, onTap: _goToTab),
    );
  }
}
