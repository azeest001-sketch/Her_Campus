import 'package:flutter/material.dart';
import 'package:team_map/map_kit/map_kit.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  TeamMap.ensurePlatformConfigured();
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
