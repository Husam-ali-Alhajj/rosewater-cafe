import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/app_entry_point.dart';
import 'services/auth_deep_link_listener.dart';
import 'services/secure_local_storage.dart';
import 'services/settings_provider.dart';
import 'theme/app_theme.dart';

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
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Rosewater Café',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AppEntryPoint(),
      ),
    );
  }
}
