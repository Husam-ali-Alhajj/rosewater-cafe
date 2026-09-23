import 'package:flutter/material.dart';

import '../../services/app_settings_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/setting_toggle_row.dart';
import '../auth/sign_out.dart';

// Values follow the same shared/established patterns as the rest of the
// Profile section (Notification settings, Privacy & Security, Help &
// Support), reused rather than re-measured -- the Figma REST API was still
// rate-limited when this screen was built (see decision #47).
const _titleInk = Color(0xFF1E2939);
const _bodyInk = Color(0xFF4A5565);
const _rowFill = Color(0xFFF9FAFB);
const _dividerInk = Color(0xFFF3F4F6);
const _rowValue = Color(0xFF101828);
const _mutedText = Color(0xFF6A7282);
const _languageSelectedFill = Color(0xFFFFF1F2);
const _languageSelectedBorder = Color(0xFFFFA1AD);
const _destructiveInk = Color(0xFFE7000B);
const _destructiveBorder = Color(0xFFFFA2A2);

const _hairline = 0.515; // Figma's fractional hairline stroke width

const _languages = ['English', 'Arabic', 'French', 'Spanish'];

// pubspec.yaml's real `version: 1.0.0+1` -- shown instead of the design's
// mock "Build 2024.01.14" (a demo date, not anything this project tracks).
// Same idea as decision #3's member-ID fix: real data over plausible-looking
// mock data.
const _appVersion = '1.0.0';
const _appBuild = '1';

/// App Settings (Figma frame "AppSettingsScreen"): Appearance, Language,
/// Interactions, Data & Storage.
///
/// **Dark Mode and Language are exactly decision #5: shown for visual
/// accuracy, built for real nowhere.** Dark Mode is drawn off and inert with
/// the design's own "(Coming Soon)" label. The language list always shows
/// English selected (a plain, static list -- nothing here is tappable);
/// selecting Arabic/French/Spanish was never in scope, so there's nothing to
/// half-build.
///
/// **Animations, Sound Effects and Haptic Feedback are the same kind of
/// placeholder**, for the same reason: this task's acceptance bar is "no
/// functionality built beyond what's decided in scope," and only Dark
/// Mode/Language were explicitly scoped. They're drawn at the state the
/// design shows (on) and are inert -- no `AnimatedContainer` app-wide setting,
/// no `HapticFeedback` calls wired up. (This app's Sound & Vibration toggle on
/// the Notifications screen is a *different* setting -- notification sound,
/// not general UI sound -- kept deliberately separate, the same kind of
/// naming collision decision #33 already called out for two different
/// "guests" fields.)
///
/// **Data & Storage is real**, by this task's explicit "your call": this app
/// has almost nothing to manage locally (no bulk asset/network image
/// caching -- the one real user of Flutter's image cache is the profile
/// photo's signed URL), so "Cache Size" shows the real, computed number of
/// bytes currently cached -- never the design's fabricated "12.5 MB" -- and
/// "Clear Cache" really clears it. "Clear All App Data" really wipes every
/// local preference (`shared_preferences`: the onboarding flag, saved
/// notification settings) and then signs the device out for real, since a
/// device with no local session should not still look signed in.
class AppSettingsScreen extends StatefulWidget {
  final AppSettingsService service;

  /// What runs right after local preferences are cleared and confirmed.
  /// Defaults to [signOutAndShowLanding] -- the real thing, which needs a
  /// live Supabase client. Overridable so this can be proven without one
  /// (widget tests can't initialise Supabase): a test passes a spy here to
  /// confirm this step would run, the same way other screens in this app
  /// inject their services rather than unit-testing a real sign-out call
  /// directly (see ProfileScreen/HomeScreen).
  final Future<void> Function(BuildContext context)? onDataCleared;

  const AppSettingsScreen({
    super.key,
    this.service = const AppSettingsService(),
    this.onDataCleared,
  });

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late int _cacheBytes = widget.service.cacheSizeBytes();
  bool _clearingAll = false;

  void _clearCache() {
    widget.service.clearImageCache();
    setState(() => _cacheBytes = widget.service.cacheSizeBytes());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared.')));
  }

  Future<void> _confirmClearAllData() async {
    if (_clearingAll) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all app data?'),
        content: const Text(
          'This removes every saved preference from this device and signs you out. '
          "Your account and its data aren't affected -- you can sign back in normally.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear & Sign Out', style: TextStyle(color: _destructiveInk)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearingAll = true);
    widget.service.clearImageCache();
    await widget.service.clearLocalPreferences();
    if (!mounted) return;
    // A device with no local preferences shouldn't still look signed in --
    // clears the session too, and returns to Auth Landing.
    if (widget.onDataCleared != null) {
      await widget.onDataCleared!(context);
    } else {
      await signOutAndShowLanding(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: 'App Settings', onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                const _AppearanceCard(),
                const SizedBox(height: 24),
                const _InteractionsCard(),
                const SizedBox(height: 24),
                _DataStorageCard(
                  cacheBytes: _cacheBytes,
                  onClearCache: _clearCache,
                  onClearAllData: _clearingAll ? null : _confirmClearAllData,
                ),
                const SizedBox(height: 24),
                const _FooterInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A white card with a titled header. [gradientHeader] matches the
/// Notification/Security Options band pattern for the section that leads the
/// screen; the others use a plain header with a hairline divider, matching
/// Privacy & Security's Password/Privacy cards.
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool gradientHeader;
  final Widget child;

  const _Card({required this.title, required this.icon, required this.gradientHeader, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: gradientHeader
                ? const BoxDecoration(gradient: AppColors.primaryGradient)
                : const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _dividerInk, width: _hairline)),
                  ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: gradientHeader ? Colors.white : _titleInk),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 28 / 18,
                    letterSpacing: -0.44,
                    color: gradientHeader ? Colors.white : _titleInk,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      gradientHeader: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingToggleRow(
            icon: Icons.dark_mode_outlined,
            iconSize: 20,
            label: 'Dark Mode',
            description: 'Switch to dark theme',
            value: false,
            onToggle: null, // decision #5: shown, never built
            showDivider: true,
            note: '(Coming Soon)',
            switchKey: ValueKey('placeholder-dark-mode'),
          ),
          const SettingToggleRow(
            icon: Icons.motion_photos_auto_outlined,
            iconSize: 20,
            label: 'Animations',
            description: 'Enable smooth animations throughout the app',
            value: true,
            onToggle: null, // out of this task's scope; drawn at the design's state
            showDivider: false,
            switchKey: ValueKey('placeholder-animations'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Language',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.15,
                color: _titleInk,
              ),
            ),
          ),
          for (final language in _languages) _LanguageRow(language: language, selected: language == 'English'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// One language option. Decision #5: only English actually works, so this
/// list is entirely static -- English always shows selected, and no row is
/// tappable (there's nothing a tap could meaningfully do yet).
class _LanguageRow extends StatelessWidget {
  final String language;
  final bool selected;

  const _LanguageRow({required this.language, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _languageSelectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: _languageSelectedBorder, width: _hairline) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.bottomNavActive : _bodyInk,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check, size: 18, color: AppColors.bottomNavActive),
          ],
        ),
      ),
    );
  }
}

class _InteractionsCard extends StatelessWidget {
  const _InteractionsCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      title: 'Interactions',
      icon: Icons.touch_app_outlined,
      gradientHeader: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingToggleRow(
            icon: Icons.volume_up_outlined,
            iconSize: 20,
            label: 'Sound Effects',
            description: 'Play sounds for actions and notifications',
            value: true,
            onToggle: null, // out of scope; see the class doc comment
            showDivider: true,
            switchKey: ValueKey('placeholder-sound-effects'),
          ),
          SettingToggleRow(
            icon: Icons.vibration,
            iconSize: 20,
            label: 'Haptic Feedback',
            description: 'Vibrate on button presses and interactions',
            value: true,
            onToggle: null,
            showDivider: false,
            switchKey: ValueKey('placeholder-haptic-feedback'),
          ),
        ],
      ),
    );
  }
}

class _DataStorageCard extends StatelessWidget {
  final int cacheBytes;
  final VoidCallback onClearCache;
  final VoidCallback? onClearAllData;

  const _DataStorageCard({required this.cacheBytes, required this.onClearCache, required this.onClearAllData});

  static String _format(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Data & Storage',
      icon: Icons.storage_outlined,
      gradientHeader: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: _rowFill, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cache Size',
                    style: TextStyle(fontSize: 14, letterSpacing: -0.15, color: _bodyInk),
                  ),
                  Text(
                    _format(cacheBytes),
                    style: const TextStyle(fontSize: 16, letterSpacing: -0.31, color: _rowValue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _OutlinedActionButton(
              icon: Icons.cleaning_services_outlined,
              label: 'Clear Cache',
              ink: _titleInk,
              borderColor: Colors.black.withValues(alpha: 0.1),
              onTap: onClearCache,
            ),
            const SizedBox(height: 12),
            _OutlinedActionButton(
              icon: Icons.delete_sweep_outlined,
              label: 'Clear All App Data',
              ink: _destructiveInk,
              borderColor: _destructiveBorder,
              onTap: onClearAllData,
            ),
          ],
        ),
      ),
    );
  }
}

/// The full-width outlined button shape shared by "Clear Cache" and "Clear
/// All App Data" (Figma-consistent with Profile's Edit Profile / Sign Out
/// buttons -- same 51.09 height, radius 8, hairline border).
class _OutlinedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color ink;
  final Color borderColor;
  final VoidCallback? onTap;

  const _OutlinedActionButton({
    required this.icon,
    required this.label,
    required this.ink,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: 1.545),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            height: 51.09,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: ink),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.15, color: ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterInfo extends StatelessWidget {
  const _FooterInfo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Rosewater Café',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _titleInk),
        ),
        SizedBox(height: 4),
        Text('Version $_appVersion', style: TextStyle(fontSize: 12, color: _mutedText)),
        SizedBox(height: 2),
        Text('Build $_appBuild', style: TextStyle(fontSize: 12, color: _mutedText)),
      ],
    );
  }
}
