import 'package:flutter/foundation.dart';

import 'college_service.dart';
import 'supabase_service.dart';

/// Current user's profile row + location / campus sync.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final _supabase = SupabaseService.instance;

  String? get currentUserId =>
      _supabase.isReady ? _supabase.auth.currentUser?.id : null;

  Future<void> ensureProfile({
    required String role,
    String? displayName,
  }) async {
    if (!_supabase.isReady) return;
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) return;

    final campus = CollegeService.instance.selectedCollege?.name;
    try {
      await _supabase.client.from('profiles').upsert({
        'id': user.id,
        'email': user.email!.trim().toLowerCase(),
        'display_name': displayName ??
            user.userMetadata?['display_name'] ??
            user.email!.split('@').first,
        'role': role,
        if (campus != null) 'campus_name': campus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Auth can succeed before SQL schema is applied; don't block login/signup.
      debugPrint('ensureProfile skipped: $e');
    }
  }

  Future<void> setCampusName(String campusName) async {
    final id = currentUserId;
    if (!_supabase.isReady || id == null) return;
    try {
      await _supabase.client.from('profiles').update({
        'campus_name': campusName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      debugPrint('setCampusName skipped: $e');
    }
  }

  Future<void> updateLocation({
    required double lat,
    required double lng,
    bool sharing = true,
  }) async {
    final id = currentUserId;
    if (!_supabase.isReady || id == null) return;
    try {
      await _supabase.client.from('profiles').update({
        'last_lat': lat,
        'last_lng': lng,
        'last_location_at': DateTime.now().toUtc().toIso8601String(),
        'sharing_location': sharing,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      debugPrint('updateLocation skipped: $e');
    }
  }

  Future<Map<String, dynamic>?> findByEmail(String email) async {
    if (!_supabase.isReady) return null;
    final row = await _supabase.client
        .from('profiles')
        .select()
        .eq('email', email.trim().toLowerCase())
        .maybeSingle();
    return row;
  }

  Future<List<Map<String, dynamic>>> campusPeers({
    required String campusName,
    required String excludeUserId,
  }) async {
    if (!_supabase.isReady) return [];
    final rows = await _supabase.client
        .from('profiles')
        .select()
        .eq('campus_name', campusName)
        .eq('sharing_location', true)
        .neq('id', excludeUserId);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
