import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/secure_local_storage.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
    ),
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
      // Sprint 1 will replace this with the onboarding carousel as the
      // initial route. Kept as a plain placeholder so Sprint 0's
      // acceptance criteria (project runs, theme applied) can be verified
      // on its own before any screens exist.
      home: const _SetupCheckScreen(),
    );
  }
}

class _SetupCheckScreen extends StatelessWidget {
  const _SetupCheckScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_cafe, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Rosewater Café', style: AppTextStyles.logoTitle),
            const SizedBox(height: 8),
            Text('Sprint 0 setup complete ✓', style: AppTextStyles.bodyMuted),
          ],
        ),
      ),
    );
  }
}
