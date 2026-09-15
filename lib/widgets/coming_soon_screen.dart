import 'package:flutter/material.dart';
import '../screens/auth/auth_landing_screen.dart';
import '../services/supabase_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared placeholder for a destination that isn't built yet, so in-progress
/// flows stay testable end-to-end without a bespoke stub per screen.
class ComingSoonScreen extends StatelessWidget {
  final String label;

  /// True for authenticated destinations (Home, Choose Membership) so
  /// there's a way to actually sign out and verify Task 8's "signing out
  /// returns to Landing" requirement — false for stubs reached while
  /// already signed out (e.g. Forgot Password had no real screen yet).
  final bool showSignOut;

  /// Optional extra line under the main label — e.g. an id carried forward
  /// from the previous real screen, so it stays visible/verifiable while
  /// this destination is still a stub.
  final String? subtitle;

  const ComingSoonScreen({super.key, required this.label, this.showSignOut = false, this.subtitle});

  Future<void> _signOut(BuildContext context) async {
    await supabase.auth.signOut();
    if (!context.mounted) return;
    // pushAndRemoveUntil clears the whole stack so the back button can't
    // return to an authenticated screen after signing out.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthLandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageBackgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  if (showSignOut)
                    TextButton(
                      onPressed: () => _signOut(context),
                      child: Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$label — coming in a future task',
                        style: AppTextStyles.bodyMuted,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(subtitle!, style: AppTextStyles.bodyMuted),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
