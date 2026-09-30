import 'package:flutter/material.dart';
import 'app_semantic_colors.dart';

/// Text styles. They take a context so their colour follows the theme; [button] is always white on
/// the gradient buttons.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading1(BuildContext context) =>
      TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.colors.textPrimary);

  static TextStyle heading2(BuildContext context) =>
      TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textPrimary);

  static TextStyle body(BuildContext context) => TextStyle(fontSize: 14, color: context.colors.textPrimary);

  static TextStyle bodyMuted(BuildContext context) => TextStyle(fontSize: 13, color: context.colors.textMuted);

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.44,
    height: 28 / 18,
    color: Colors.white,
  );
}
