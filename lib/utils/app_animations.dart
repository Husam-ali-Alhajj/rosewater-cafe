import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_provider.dart';

/// Used when animations are off. 1ms instead of zero, because some widgets expect an animation to
/// actually finish.
const instantAnimationDuration = Duration(milliseconds: 1);

/// [normal] when animations are on, almost instant when off. Use this for every animation duration
/// (page transitions use AppPageRoute).
///
/// Counts as "on" when there's no SettingsProvider (for example, in tests).
extension AnimationDurationX on BuildContext {
  Duration animDuration(Duration normal) {
    try {
      return watch<SettingsProvider>().animationsEnabled ? normal : instantAnimationDuration;
    } on ProviderNotFoundException {
      return normal;
    }
  }
}
