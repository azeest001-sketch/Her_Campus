import 'package:flutter/material.dart';
import 'package:team_map/map_kit/map_kit.dart';

import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TeamMap.ensurePlatformConfigured();

  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  runApp(const HerCampusApp());
}

/// App entry — starts with the branded opening animation.
class HerCampusApp extends StatelessWidget {
  const HerCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Her Campus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
