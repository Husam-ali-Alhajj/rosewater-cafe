import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_provider.dart';

/// A page route that follows the Animations setting: when it's off, transitions are almost instant
/// (1ms, since some widgets expect an animation to finish).
class AppPageRoute<T> extends MaterialPageRoute<T> {
  final bool animationsEnabled;

  AppPageRoute({required super.builder, required this.animationsEnabled, super.settings, super.fullscreenDialog});

  static const _normal = Duration(milliseconds: 300); // Flutter's default
  static const _instant = Duration(milliseconds: 1);

  @override
  Duration get transitionDuration => animationsEnabled ? _normal : _instant;

  @override
  Duration get reverseTransitionDuration => animationsEnabled ? _normal : _instant;
}

/// Creates an [AppPageRoute] using the current Animations setting. Use this instead of
/// MaterialPageRoute everywhere.
Route<T> appRoute<T>(BuildContext context, WidgetBuilder builder, {bool fullscreenDialog = false}) {
  return AppPageRoute<T>(
    builder: builder,
    animationsEnabled: _animationsEnabled(context),
    fullscreenDialog: fullscreenDialog,
  );
}

/// Counts as "on" when there's no SettingsProvider (for example, in tests).
bool _animationsEnabled(BuildContext context) {
  try {
    return context.read<SettingsProvider>().animationsEnabled;
  } on ProviderNotFoundException {
    return true;
  }
}
