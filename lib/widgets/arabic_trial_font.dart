import 'package:flutter/material.dart';

/// TRIAL: renders [child]'s Arabic text in Thmanyah Sans (bundled in
/// assets/fonts/thmanyah/, see pubspec.yaml) instead of the app-wide
/// Cairo, so the two can be compared screen-to-screen before deciding
/// app-wide. English is left completely untouched.
///
/// Two layers, because a screen's text gets its font two ways: the
/// `Theme` override covers Material widgets that read the theme's
/// textTheme directly, and `DefaultTextStyle.merge` covers plain `Text`s
/// whose `TextStyle(...)` names no fontFamily -- those inherit the
/// DefaultTextStyle that Scaffold set ABOVE the screen, from the
/// app-wide (Cairo) theme, so a Theme override alone misses them.
class ArabicTrialFont extends StatelessWidget {
  static const family = 'ThmanyahSans';

  final Widget child;

  const ArabicTrialFont({super.key, required this.child});

  /// TRIAL: Thmanyah's Bold (700) for text picked to stand out in Arabic,
  /// or [english] -- the Figma design's own weight -- otherwise, so the
  /// English screens stay exactly as designed.
  static FontWeight boldInArabic(BuildContext context, FontWeight english) =>
      Localizations.localeOf(context).languageCode == 'ar' ? FontWeight.w700 : english;

  @override
  Widget build(BuildContext context) {
    if (Localizations.localeOf(context).languageCode != 'ar') return child;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: family),
        primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: family),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: family),
        child: child,
      ),
    );
  }
}
