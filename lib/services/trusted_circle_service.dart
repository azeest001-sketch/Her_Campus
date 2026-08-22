import 'dart:math' as math;

import 'college_service.dart';
import 'profile_service.dart';
import 'supabase_service.dart';

class TrustedMember {
  const TrustedMember({
    required this.id,
    required this.memberId,
    required this.labelName,
    required this.email,
    this.displayName,
    this.lat,
    this.lng,
    this.locationAt,
    this.sharingLocation = false,
  });

  final String id;
  final String memberId;
  final String labelName;
  final String email;
  final String? displayName;
  final double? lat;
  final double? lng;
  final DateTime? locationAt;
  final bool sharingLocation;

  bool get hasLiveLocation =>
      sharingLocation && lat != null && lng != null;

  String get locationLabel {
    if (!hasLiveLocation) return 'Location unavailable';
    final college = CollegeService.instance.selectedCollege;
    if (college != null) {
      final m = _meters(lat!, lng!, college.position.latitude, college.position.longitude);
      return 'On campus · ~${m.round()} m from college pin';
    }
    return 'Live · ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}';
  }
}

/// Trusted circle backed by Supabase (`trusted_circle` + `profiles`).
class TrustedCircleService {
  TrustedCircleService._();
  static final TrustedCircleService instance = TrustedCircleService._();

  final _supabase = SupabaseService.instance;

  Future<List<TrustedMember>> listMine() async {
    if (!_supabase.isReady) return [];
    final uid = ProfileService.instance.currentUserId;
    if (uid == null) return [];

    final rows = await _supabase.client
        .from('trusted_circle')
        .select('id, label_name, member_id')
        .eq('owner_id', uid)
        .order('created_at', ascending: false);

    final out = <TrustedMember>[];
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final memberId = map['member_id'] as String;
      final profile = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', memberId)
          .maybeSingle();
      final p = profile != null
          ? Map<String, dynamic>.from(profile)
          : <String, dynamic>{};
      out.add(
        TrustedMember(
          id: map['id'] as String,
          memberId: memberId,
          labelName: map['label_name'] as String? ?? 'Friend',
          email: p['email'] as String? ?? '',
          displayName: p['display_name'] as String?,
          lat: (p['last_lat'] as num?)?.toDouble(),
          lng: (p['last_lng'] as num?)?.toDouble(),
          locationAt: p['last_location_at'] != null
              ? DateTime.tryParse(p['last_location_at'].toString())
              : null,
          sharingLocation: p['sharing_location'] as bool? ?? false,
        ),
      );
    }
    return out;
  }

  /// Step flow: [labelName] then signup [email].
  Future<String?> addByEmail({
    required String labelName,
    required String email,
  }) async {
    if (!_supabase.isReady) return 'Supabase is not connected.';
    final uid = ProfileService.instance.currentUserId;
    if (uid == null) return 'Please log in first.';

    final name = labelName.trim();
    if (name.isEmpty) return 'Enter a name for this person.';

    final profile = await ProfileService.instance.findByEmail(email);
    if (profile == null) {
      return 'No account found for that email. They must sign up first.';
    }
    final memberId = profile['id'] as String;
    if (memberId == uid) return 'You cannot add yourself.';

    try {
      await _supabase.client.from('trusted_circle').insert({
        'owner_id': uid,
        'member_id': memberId,
        'label_name': name,
      });
      return null;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('duplicate') || msg.contains('unique')) {
        return 'That person is already in your trusted circle.';
      }
      return 'Could not add: $e';
    }
  }

  Future<void> remove(String rowId) async {
    if (!_supabase.isReady) return;
    await _supabase.client.from('trusted_circle').delete().eq('id', rowId);
  }
}

double _meters(double lat1, double lng1, double lat2, double lng2) {
  const earth = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return 2 * earth * math.asin(math.sqrt(a));
}

double _rad(double deg) => deg * math.pi / 180;
