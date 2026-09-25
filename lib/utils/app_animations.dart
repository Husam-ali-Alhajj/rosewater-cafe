import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_provider.dart';

/// Sprint 8 Task 3: the near-zero duration `Animations` off collapses every
/// explicit animation duration to. Not literally [Duration.zero] -- some
/// widgets (implicit `Animated*` ones especially) assume a transition
/// actually completes, and a zero-length one can leave things stuck
/// mid-animation instead of settling cleanly on their end state. 1ms reads
/// as instant while still completing.
const instantAnimationDuration = Duration(milliseconds: 1);

/// `normal` if `SettingsProvider.animationsEnabled` is true,
/// [instantAnimationDuration] if not. The one place every explicit
/// `Animated*` widget duration in the app should read the Animations
/// toggle through -- route transitions go through `AppPageRoute`/`appRoute`
/// instead (a route's own `transitionDuration` isn't rebuilt by
/// `notifyListeners()` the way a widget's `build()` is, so it reads the
/// setting once, at push time, rather than watching it).
///
/// Falls back to `normal` (animations on) when no [SettingsProvider] is in
/// the tree -- same reasoning as `AppPageRoute`'s own fallback: most of
/// this app's existing widget tests pump a screen/widget directly without
/// registering one.
extension AnimationDurationX on BuildContext {
  Duration animDuration(Duration normal) {
    try {
      return watch<SettingsProvider>().animationsEnabled ? normal : instantAnimationDuration;
    } on ProviderNotFoundException {
      return normal;
    }
  }
}
