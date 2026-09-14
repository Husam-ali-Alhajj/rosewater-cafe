import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/app_entry_point.dart';
import 'services/secure_local_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
  );
  runApp(const RosewaterCafeApp());
}

class RosewaterCafeApp extends StatelessWidget {
  const RosewaterCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rosewater Café',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppEntryPoint(),
    );
  }
}
