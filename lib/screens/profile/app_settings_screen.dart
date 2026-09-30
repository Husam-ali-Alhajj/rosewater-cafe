import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_settings_service.dart';
import '../../services/settings_provider.dart';
import '../../theme/app_semantic_colors.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/setting_toggle_row.dart';
import '../auth/sign_out.dart';

const _hairline = 0.515;

/// A language option, shown in its own script ("العربية", not "Arabic"). French and Spanish are
/// listed but disabled until they're translated.
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

// The real app version instead of the design's demo build date.
const _appVersion = '1.0.0';
const _appBuild = '1';

/// App Settings: Appearance, Language, Interactions, Data & Storage. Every switch here works:
///
/// - Dark Mode and Language change the whole app immediately (Arabic also switches to
/// right-to-left).
/// - Animations, Sound Effects and Haptic Feedback control the app's transitions and feedback.
/// - Cache Size shows the real image-cache size, and Clear Cache empties it.
/// - Clear All App Data removes local settings and signs the user out.
///
/// (The Notifications "Sound & Vibration" switch is a separate setting, for notification sounds.)
class AppSettingsScreen extends StatefulWidget {
  final AppSettingsService service;

  /// Runs after local data is cleared (signs out by default). A parameter so tests can check it
  /// without Supabase.
  final Future<void> Function(BuildContext context)? onDataCleared;

  const AppSettingsScreen({super.key, this.service = const AppSettingsService(), this.onDataCleared});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late int _cacheBytes = widget.service.cacheSizeBytes();
  bool _clearingAll = false;

  void _clearCache() {
    widget.service.clearImageCache();
    setState(() => _cacheBytes = widget.service.cacheSizeBytes());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).cacheClearedMessage)));
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
    // No local data means no session either, so sign out and go back to the start.
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
                ScreenHeader(
                  title: AppLocalizations.of(context).appSettingsLabel,
                  onBack: () => Navigator.of(context).pop(),
                ),
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

/// A card with a title. The first section uses the gradient header, the others a plain one.
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
                    border: Border(
                      bottom: BorderSide(color: colors.border, width: _hairline),
                    ),
                  ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: gradientHeader ? Colors.white : colors.textPrimary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
              // Languages without translations can't be picked.
              onTap: language.translated ? () => settings.setLocale(language.code) : null,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// One language row. Disabled rows (no onTap) are greyed out with "(Coming Soon)".
class _LanguageRow extends StatelessWidget {
  final _Language language;
  final bool selected;

  /// Null disables the row.
  final VoidCallback? onTap;

  const _LanguageRow({required this.language, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            // Light accent tint for the selected language.
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
                    color: selected
                        ? colors.accent
                        : enabled
                        ? colors.textMuted
                        : colors.textMuted.withValues(alpha: 0.45),
                  ),
                ),
              ),
              if (selected) Icon(Icons.check, size: 18, color: colors.accent),
              if (!enabled)
                Text(
                  AppLocalizations.of(context).comingSoonNote,
                  style: TextStyle(fontSize: 12, color: colors.textMuted.withValues(alpha: 0.6)),
                ),
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

/// The outlined button used by "Clear Cache" and "Clear All App Data".
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
        const AppLogo(height: 40),
        const SizedBox(height: 8),
        Text(l10n.versionLine(_appVersion), style: TextStyle(fontSize: 12, color: colors.textMuted)),
        const SizedBox(height: 2),
        Text(l10n.buildLine(_appBuild), style: TextStyle(fontSize: 12, color: colors.textMuted)),
      ],
    );
  }
}
