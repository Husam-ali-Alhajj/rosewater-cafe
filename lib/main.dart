import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'l10n/app_localizations.dart';
import 'screens/app_entry_point.dart';
import 'services/auth_deep_link_listener.dart';
import 'services/secure_local_storage.dart';
import 'services/settings_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_lock_gate.dart';

/// Lets the password-recovery listener open the "set new password" screen from outside any widget.
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialization = Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
  );
  // We subscribe before awaiting initialize(): on web, a password-reset link fires its event while
  // initialize() is still running, before any widget exists.
  listenForPasswordRecovery(navigatorKey);
  await initialization;
  // Load saved settings before the first frame so the theme doesn't flash from the default to the
  // saved one.
  final settings = await SettingsProvider.load();
  runApp(RosewaterCafeApp(settings: settings));
}

class RosewaterCafeApp extends StatelessWidget {
  final SettingsProvider settings;

  const RosewaterCafeApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    // Provided above MaterialApp so every screen can read the settings.
    return ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      // Rebuilds MaterialApp whenever a setting changes, so theme and language switch live.
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          // Inter has no Arabic letters, so Arabic uses its own font.
          final isArabic = settings.locale == 'ar';
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Rosewater Café',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(isArabic: isArabic),
            darkTheme: AppTheme.dark(isArabic: isArabic),
            themeMode: settings.themeMode,
            // Only English and Arabic have translations. Arabic also switches the whole app to
            // right-to-left.
            locale: Locale(settings.locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const AppEntryPoint(),
            // Wraps every screen so the auto-lock screen can appear on resume wherever the user is.
            builder: (context, child) => AppLockGate(child: child!),
          );
        },
      ),
    );
  }
}
