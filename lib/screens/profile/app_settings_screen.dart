import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_settings_service.dart';
import '../../services/settings_provider.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/setting_toggle_row.dart';
import '../auth/sign_out.dart';

// Values follow the same shared/established patterns as the rest of the
// Profile section (Notification settings, Privacy & Security, Help &
// Support), reused rather than re-measured -- the Figma REST API was still
// rate-limited when this screen was built (see decision #47). Sprint 8 Task
// 2 made this screen theme-aware (it's where Dark Mode itself is toggled,
// so it has to actually look right the instant that switch flips): the
// fixed neutral inks/fills this file used to hardcode (title/body text, the
// cache-size row fill, the card divider) are gone -- every build() below
// reads them from `context.colors` instead. The v3 accent rebuild went
// further and tokenized the language-selected wash and the
// destructive-action ink/border too (`colors.accent`/`colors.danger`), so
// both react to the blue-in-dark-mode accent instead of staying the
// design's fixed pink/red literals.

const _hairline = 0.515; // Figma's fractional hairline stroke width

/// One row in the Language list. [label] is always shown in that
/// language's OWN script ("العربية", not "Arabic") -- the standard
/// convention for a language picker, and not something that needs
/// `AppLocalizations` at all, unlike everything else this task touches.
/// [translated] is false for French/Spanish: real, storable picks (the
/// design shows all four as selectable), but `MaterialApp`'s
/// `supportedLocales` only lists en/ar, so picking one of these falls back
/// to English text -- decision #63's "say so plainly in the picker"
/// requirement is [_LanguageRow]'s note, not silence.
class _Language {
  final String code;
  final String label;
  final bool translated;

  const _Language({required this.code, required this.label, required this.translated});
}

const _languages = [
  _Language(code: 'en', label: 'English', translated: true),
  _Language(code: 'ar', label: 'العربية', translated: true),
  _Language(code: 'fr', label: 'Français', translated: false),
  _Language(code: 'es', label: 'Español', translated: false),
];

// pubspec.yaml's real `version: 1.0.0+1` -- shown instead of the design's
// mock "Build 2024.01.14" (a demo date, not anything this project tracks).
// Same idea as decision #3's member-ID fix: real data over plausible-looking
// mock data.
const _appVersion = '1.0.0';
const _appBuild = '1';

/// App Settings (Figma frame "AppSettingsScreen"): Appearance, Language,
/// Interactions, Data & Storage.
///
/// **Dark Mode is real now (Sprint 8 Task 2)** -- decision #5 originally
/// scoped it out alongside Language, but this task un-scopes exactly Dark
/// Mode: the toggle reads and writes `SettingsProvider.themeMode` (the same
/// provider `main.dart`'s `MaterialApp` watches for `themeMode`), so
/// flipping it here changes every screen's theme immediately, with no
/// restart and no "(Coming Soon)" label anymore.
///
/// **Language is real for English/Arabic as of Sprint 8 Task 6** (decision
/// #63, superseding decision #5's original "shown for visual accuracy,
/// built nowhere"): tapping a row calls `SettingsProvider.setLocale`, which
/// `main.dart`'s `MaterialApp.locale` reads -- Arabic switches every
/// translated string AND flips `Directionality` to RTL app-wide, live, no
/// restart. French/Spanish are real, storable picks too (the row is
/// tappable and shows selected), they just have no ARB translation yet --
/// `MaterialApp.supportedLocales` only lists en/ar, so picking one of them
/// falls back to English TEXT, with a caption saying so, rather than a
/// missing-key crash or silently wrong text.
///
/// **Animations is real too** (Sprint 8 Task 3, decision #60): the toggle
/// reads/writes `SettingsProvider.animationsEnabled`, which
/// `AppPageRoute`/`appRoute` (every screen transition) and
/// `context.animDuration` (every explicit `Animated*` widget duration)
/// read at the moment they'd animate.
///
/// **Sound Effects and Haptic Feedback are real as of Sprint 8 Task 4**
/// (decision #61): each toggle reads/writes its own
/// `SettingsProvider.soundEnabled`/`.hapticsEnabled`, and
/// `context.triggerButtonPress`/`.triggerSuccess`/`.triggerError`
/// (`lib/utils/app_feedback.dart`) gate sound and haptics independently
/// through them at a small, fixed set of real trigger points -- not every
/// tap. (This app's Sound & Vibration toggle on the Notifications screen is
/// a *different* setting -- notification sound, not general UI sound --
/// kept deliberately separate, the same kind of naming collision decision
/// #33 already called out for two different "guests" fields.)
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).cacheClearedMessage)),
    );
  }

  Future<void> _confirmClearAllData() async {
    if (_clearingAll) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearAllAppDataTitle),
        content: Text(l10n.clearAllAppDataBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.clearAndSignOutButton, style: TextStyle(color: ctx.colors.danger)),
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
        decoration: BoxDecoration(gradient: context.colors.pageBackgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: AppLocalizations.of(context).appSettingsLabel, onBack: () => Navigator.of(context).pop()),
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
    final colors = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: gradientHeader
                ? BoxDecoration(gradient: colors.accentGradient)
                : BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.border, width: _hairline)),
                  ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: gradientHeader ? Colors.white : colors.textPrimary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 28 / 18,
                    letterSpacing: -0.44,
                    color: gradientHeader ? Colors.white : colors.textPrimary,
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
    // Real now (Sprint 8 Task 2) -- `watch`, not `read`, so this row's
    // switch reflects `SettingsProvider.themeMode` immediately if it's
    // changed anywhere else (there's nowhere else yet, but the same
    // `ChangeNotifierProvider` this reads from is what `main.dart`'s
    // `MaterialApp` also watches, so the two never disagree).
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context);
    return _Card(
      title: l10n.appearanceCardTitle,
      icon: Icons.palette_outlined,
      gradientHeader: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingToggleRow(
            icon: Icons.dark_mode_outlined,
            iconSize: 20,
            label: l10n.darkModeLabel,
            description: l10n.darkModeDescription,
            value: isDark,
            onToggle: () => settings.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
            showDivider: true,
            switchKey: const ValueKey('dark-mode'),
          ),
          SettingToggleRow(
            icon: Icons.motion_photos_auto_outlined,
            iconSize: 20,
            label: l10n.animationsLabel,
            description: l10n.animationsDescription,
            // Real now (Sprint 8 Task 3): page transitions (AppPageRoute,
            // via every screen's `appRoute` call) and every explicit
            // Animated* widget duration (this very switch included --
            // SettingSwitch's AnimatedContainer/AnimatedPositioned read
            // `context.animDuration`) collapse to near-zero the instant
            // this flips off.
            value: settings.animationsEnabled,
            onToggle: () => settings.setAnimationsEnabled(!settings.animationsEnabled),
            showDivider: false,
            switchKey: const ValueKey('animations'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              l10n.languageSectionLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.15,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          for (final language in _languages)
            _LanguageRow(
              language: language,
              selected: language.code == settings.locale,
              onTap: () => settings.setLocale(language.code),
            ),
          if (!_languages.firstWhere((l) => l.code == settings.locale).translated)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                // Sprint 8 Task 6 (decision #63): "say so plainly in the
                // picker rather than silently showing wrong text" -- this
                // is that line, shown only while an untranslated language
                // is actually the current pick.
                l10n.frenchSpanishNotTranslatedNote,
                style: TextStyle(fontSize: 12, height: 16 / 12, color: context.colors.textMuted),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// One language option (Sprint 8 Task 6, decision #63): English and Arabic
/// are real (tapping one calls `SettingsProvider.setLocale`, live-switching
/// the whole app -- and, for Arabic, its `Directionality`); French/Spanish
/// are real, storable picks too (the design shows all four as selectable),
/// they just render English text until translated -- see the caption
/// `_AppearanceCard` shows underneath when one of them is picked.
class _LanguageRow extends StatelessWidget {
  final _Language language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({required this.language, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            // A light accent wash, not the design's fixed pink literals --
            // derived from `colors.accent` so it's pink-tinted in light mode
            // and blue-tinted in dark, matching whatever the accent is.
            color: selected ? colors.accent.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: colors.accent.withValues(alpha: 0.4), width: _hairline) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  language.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? colors.accent : colors.textMuted,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check, size: 18, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractionsCard extends StatelessWidget {
  const _InteractionsCard();

  @override
  Widget build(BuildContext context) {
    // Real now (Sprint 8 Task 4) -- same `watch` reasoning as Dark
    // Mode/Animations above: this row's own switches need to reflect
    // SettingsProvider immediately.
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    return _Card(
      title: l10n.interactionsCardTitle,
      icon: Icons.touch_app_outlined,
      gradientHeader: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingToggleRow(
            icon: Icons.volume_up_outlined,
            iconSize: 20,
            label: l10n.soundEffectsLabel,
            description: l10n.soundEffectsDescription,
            value: settings.soundEnabled,
            onToggle: () => settings.setSoundEnabled(!settings.soundEnabled),
            showDivider: true,
            switchKey: const ValueKey('sound-effects'),
          ),
          SettingToggleRow(
            icon: Icons.vibration,
            iconSize: 20,
            label: l10n.hapticFeedbackLabel,
            description: l10n.hapticFeedbackDescription,
            value: settings.hapticsEnabled,
            onToggle: () => settings.setHapticsEnabled(!settings.hapticsEnabled),
            showDivider: false,
            switchKey: const ValueKey('haptic-feedback'),
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
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return _Card(
      title: l10n.dataStorageCardTitle,
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
              decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.cacheSizeLabel,
                    style: TextStyle(fontSize: 14, letterSpacing: -0.15, color: colors.textMuted),
                  ),
                  Text(
                    _format(cacheBytes),
                    style: TextStyle(fontSize: 16, letterSpacing: -0.31, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _OutlinedActionButton(
              icon: Icons.cleaning_services_outlined,
              label: l10n.clearCacheButton,
              ink: colors.textPrimary,
              borderColor: colors.border,
              onTap: onClearCache,
            ),
            const SizedBox(height: 12),
            _OutlinedActionButton(
              icon: Icons.delete_sweep_outlined,
              label: l10n.clearAllAppDataButton,
              ink: colors.danger,
              borderColor: colors.danger.withValues(alpha: 0.4),
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
        color: context.colors.surface,
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
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // "Rosewater Café" is the app's own name, kept as-is in every
        // locale -- same convention as versionFooter's brand tail elsewhere.
        Text(
          'Rosewater Café',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(l10n.versionLine(_appVersion), style: TextStyle(fontSize: 12, color: colors.textMuted)),
        const SizedBox(height: 2),
        Text(l10n.buildLine(_appBuild), style: TextStyle(fontSize: 12, color: colors.textMuted)),
      ],
    );
  }
}
