import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:safe_campus/app/firebase_options.dart';

/// Initializes Firebase when real options are configured.
/// Falls back to local-only crowd sync when not configured yet.
class FirebaseBootstrap {
  static bool ready = false;

  static Future<void> init() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        'Firebase not configured — heatwave uses local sync. '
        'Run flutterfire configure and update lib/app/firebase_options.dart '
        'for shared multi-phone maps.',
      );
      ready = false;
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      ready = true;
    } catch (e, st) {
      debugPrint('Firebase init failed: $e\n$st');
      ready = false;
    }
  }
}
