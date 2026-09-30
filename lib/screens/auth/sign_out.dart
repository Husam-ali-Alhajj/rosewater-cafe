import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/supabase_client.dart';
import '../../widgets/app_page_route.dart';
import 'auth_landing_screen.dart';

/// Ends the current session and returns to Auth Landing, clearing the whole
/// navigation stack so Back can't return to an authenticated screen (see
/// docs/decisions.md #21/#26).
///
/// Shared by every "Sign Out"/"Logout" control (Profile tab, Home header) so
/// they can't drift apart. Returns false -- after showing a SnackBar -- if
/// the sign-out call itself fails, so the caller can re-enable its button.
Future<bool> signOutAndShowLanding(BuildContext context) async {
  try {
    await supabase.auth.signOut();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).couldntSignOutError)),
      );
    }
    return false;
  }
  if (!context.mounted) return true;
  Navigator.of(context).pushAndRemoveUntil(
    appRoute(context, (_) => const AuthLandingScreen()),
    (route) => false,
  );
  return true;
}
