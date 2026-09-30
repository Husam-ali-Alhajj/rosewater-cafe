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

/// Shared across the app so `listenForPasswordRecovery` can push the "set
/// new password" screen from outside any BuildContext, the moment a
/// password-recovery deep link is opened -- regardless of whatever screen
/// happens to be on top of the navigation stack at that moment.
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialization = Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
  );
  // `Supabase.initialize()` is itself an async function: calling it (without
  // awaiting yet) still runs its synchronous prefix immediately -- which is
  // where `Supabase.instance.client` gets created -- before it suspends at
  // ITS OWN first `await` to process any session-recovery deep link. On
  // Flutter Web, that whole deep-link exchange (including firing
  // AuthChangeEvent.passwordRecovery for a password-reset link) happens
  // entirely inside that awaited portion -- before the `await` below
  // returns, and long before `runApp()` builds a single widget. No widget's
  // `initState` could ever subscribe in time to catch it (confirmed live:
  // an earlier version of this file awaited initialize() first, and the
  // reset link landed on the normal signed-in Home screen instead of Set
  // New Password -- the event had already fired into a stream nobody was
  // listening to yet). Subscribing here, in the gap between calling
  // `initialize()` and awaiting it, is the only point early enough.
  listenForPasswordRecovery(navigatorKey);
  await initialization;
  // Awaited here, before runApp(), for the same reason `Supabase.initialize()`
  // is: reading every stored setting first means the first frame is already
  // correct, instead of showing in-memory defaults that then flip once the
  // real stored values load a moment later -- see SettingsProvider's own doc
  // comment for why that flash would actually be visible (theme mode).
  final settings = await SettingsProvider.load();
  runApp(RosewaterCafeApp(settings: settings));
}

class RosewaterCafeApp extends StatelessWidget {
  final SettingsProvider settings;

  const RosewaterCafeApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    // Registered once, above MaterialApp, so any screen can reach it via
    // context.watch<SettingsProvider>()/context.read<SettingsProvider>()
    // without prop-drilling -- Sprint 8's foundation task. `.value` because
    // `settings` is already constructed (via the async `load()` above), not
    // something this widget should create or dispose itself.
    return ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      // A Consumer, not `context.watch` right here -- this method's own
      // `context` is RosewaterCafeApp's position in the tree, ABOVE the
      // ChangeNotifierProvider it just returned, so nothing below it could
      // be found by watching from here. The Consumer sits inside the
      // provider instead, so `MaterialApp` (and everything under it)
      // rebuilds the instant `SettingsProvider.setThemeMode` calls
      // `notifyListeners()` -- Dark Mode flips live, with no restart.
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          // Inter (this app's Latin typeface) has no Arabic glyphs at all,
          // so it can't just stay the fontFamily when the locale is Arabic
          // -- see AppTheme's own doc comment on why Noto Naskh Arabic,
          // replaces it. Re-evaluated on every rebuild (this Consumer
          // already rebuilds on any SettingsProvider change, locale
          // included), so switching languages in App Settings swaps the
          // font live, the same way Dark Mode already swaps theme live.
          final isArabic = settings.locale == 'ar';
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Rosewater Café',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(isArabic: isArabic),
            darkTheme: AppTheme.dark(isArabic: isArabic),
            themeMode: settings.themeMode,
            // Sprint 8 Task 6: `supportedLocales` only lists the two ARB
            // files that actually exist (en/ar) -- French/Spanish are real,
            // storable picks in `SettingsProvider.locale` (App Settings'
            // Language list still shows all four, per the design), but
            // MaterialApp's own locale-resolution algorithm falls back to
            // the first supported locale (English) for anything it doesn't
            // recognize, rather than crashing or showing missing-key
            // fallback text. Arabic being in `supportedLocales` is also what
            // makes `Directionality` flip to RTL app-wide -- that's derived
            // from the resolved `Locale`, not set separately.
            locale: Locale(settings.locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const AppEntryPoint(),
            // Sprint 8 Task 5: wraps the app's whole navigated content (every
            // route, regardless of which one is on top) so Auto-Lock's lock
            // screen can appear on resume no matter where the user was --
            // MaterialApp's own `builder`, not something bolted onto
            // AppEntryPoint, which only ever runs once at cold start.
            builder: (context, child) => AppLockGate(child: child!),
          );
        },
      ),
    );
  }
}
