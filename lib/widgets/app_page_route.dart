import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_provider.dart';

/// A drop-in replacement for `MaterialPageRoute` that respects
/// `SettingsProvider.animationsEnabled` (Sprint 8 Task 3): with Animations
/// off, every screen-to-screen transition collapses from the platform's
/// normal ~300ms slide/fade to near-zero instead.
///
/// Not literally [Duration.zero] -- the acceptance criterion itself calls
/// this out: some widgets assume a transition actually completes, and a
/// zero-length one can leave a route's animation status stuck mid-flight
/// instead of settling on `AnimationStatus.completed`/`.dismissed`. 1ms is
/// short enough to read as instant while still being a real, completing
/// animation.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  final bool animationsEnabled;

  AppPageRoute({
    required super.builder,
    required this.animationsEnabled,
    super.settings,
    super.fullscreenDialog,
  });

  static const _normal = Duration(milliseconds: 300); // MaterialPageRoute's own default
  static const _instant = Duration(milliseconds: 1);

  @override
  Duration get transitionDuration => animationsEnabled ? _normal : _instant;

  @override
  Duration get reverseTransitionDuration => animationsEnabled ? _normal : _instant;
}

/// Builds an [AppPageRoute], reading the current `animationsEnabled` value
/// from [SettingsProvider] at push time. The app-wide replacement for
/// `MaterialPageRoute(builder: ...)` at every `Navigator` call site, so the
/// Animations toggle actually reaches every screen transition, not just a
/// few sampled ones.
Route<T> appRoute<T>(BuildContext context, WidgetBuilder builder, {bool fullscreenDialog = false}) {
  return AppPageRoute<T>(
    builder: builder,
    animationsEnabled: _animationsEnabled(context),
    fullscreenDialog: fullscreenDialog,
  );
}

/// Falls back to `true` (animations on -- this route then behaves exactly
/// like a plain `MaterialPageRoute`) when no [SettingsProvider] is in the
/// tree, the same fallback `app_semantic_colors.dart`'s `context.colors`
/// already uses for the same reason: most of this app's existing widget
/// tests build a screen directly (`MaterialApp(home: SomeScreen())`)
/// without registering `SettingsProvider`, and shouldn't all need an
/// explicit `ChangeNotifierProvider` wrapper just because a screen they
/// pump happens to navigate somewhere.
bool _animationsEnabled(BuildContext context) {
  try {
    return context.read<SettingsProvider>().animationsEnabled;
  } on ProviderNotFoundException {
    return true;
  }
}
