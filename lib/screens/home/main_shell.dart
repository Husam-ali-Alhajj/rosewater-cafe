import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/coming_soon_screen.dart';
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
/// Home is the only tab built out so far; the rest stay `ComingSoonScreen`
/// stubs until their own task/sprint. `IndexedStack` (not swapping the
/// child widget per tap) keeps each tab's state alive across switches,
/// matching how a real tabbed app behaves.
///
/// `_tabs` is built once in [initState], not `static const` anymore --
/// `HomeScreen` needs [_goToTab] itself now (its two quick-action buttons
/// switch to the QR Code/Events tabs the same way the bottom nav does,
/// see docs/decisions.md #29), and a bound instance method can't be a
/// compile-time constant. Built once rather than in [build] so switching
/// tabs doesn't hand `HomeScreen` a new closure identity on every
/// `setState` -- irrelevant here since `HomeScreen` never compares its
/// callback's identity, but there's no reason to allocate one on every
/// tab switch either.
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
  int _index = _homeTab;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeScreen(
        onGoToQrCode: () => _goToTab(_qrCodeTab),
        onGoToEvents: () => _goToTab(_eventsTab),
      ),
      const ComingSoonScreen(label: 'QR Code'),
      const ComingSoonScreen(label: 'Events'),
      const ComingSoonScreen(label: 'Profile', showSignOut: true),
    ];
  }

  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, onTap: _goToTab),
    );
  }
}
