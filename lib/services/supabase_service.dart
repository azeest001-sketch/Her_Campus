import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads `.env` and initializes the shared Supabase client once at startup.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  var _ready = false;

  /// True after a successful [initialize] with non-empty URL + anon key.
  bool get isReady => _ready;

  /// Throws if Supabase was not initialized (missing / empty `.env` values).
  SupabaseClient get client {
    if (!_ready) {
      throw StateError(
        'Supabase is not initialized. Add SUPABASE_URL and '
        'SUPABASE_ANON_KEY to .env, then rebuild the app.',
      );
    }
    return Supabase.instance.client;
  }

  GoTrueClient get auth => client.auth;

  /// Load `.env` (bundled asset) and call [Supabase.initialize] when configured.
  Future<void> initialize() async {
    if (_ready) return;

    await dotenv.load(fileName: '.env', isOptional: true);

    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final key = (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
            dotenv.env['SUPABASE_ANON_KEY'])
        ?.trim() ??
        '';

    if (url.isEmpty || key.isEmpty) {
      debugPrint(
        'Supabase skipped: set SUPABASE_URL and SUPABASE_ANON_KEY '
        '(or SUPABASE_PUBLISHABLE_KEY) in .env',
      );
      return;
    }

    await Supabase.initialize(url: url, publishableKey: key);
    _ready = true;
    debugPrint('Supabase initialized');
  }
}
