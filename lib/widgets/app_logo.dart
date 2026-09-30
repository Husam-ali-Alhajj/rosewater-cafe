import 'package:flutter/material.dart';

/// The Rosewater VIP Cafe logo. In dark mode it uses a version where the black hookah is light, so
/// it stays visible on the dark background.
class AppLogo extends StatelessWidget {
  final double height;

  const AppLogo({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo.png',
      height: height,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Rosewater VIP Cafe',
    );
  }
}
