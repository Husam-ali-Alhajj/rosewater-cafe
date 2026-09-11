import 'package:flutter/material.dart';

class OnboardingIconBadge extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;

  const OnboardingIconBadge({
    super.key,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      child: Icon(icon, color: Colors.white, size: 40),
    );
  }
}
