import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:team_map/map_kit/map_kit.dart';

import 'campus_geofence.dart';
import 'college_service.dart';
import 'profile_service.dart';
import 'supabase_service.dart';

class NearbyBuddy {
  const NearbyBuddy({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.distanceMeters,
  });

  final String userId;
  final String email;
  final String displayName;
  final double distanceMeters;
}

class BuddyNotificationItem {
  const BuddyNotificationItem({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.read,
    this.requestId,
  });

  final String id;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String? requestId;
}

/// Buddy Finder: same campus + within 300 m, in-app notifications.
class BuddyService {
  BuddyService._();
  static final BuddyService instance = BuddyService._();

  static const nearbyMeters = 300.0;

  final _supabase = SupabaseService.instance;

  Future<Position?> _myPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<({List<NearbyBuddy> nearby, String? error})> findNearby({
    required String destination,
  }) async {
    if (!_supabase.isReady) {
      return (nearby: <NearbyBuddy>[], error: 'Supabase is not connected.');
    }
    final uid = ProfileService.instance.currentUserId;
    if (uid == null) {
      return (nearby: <NearbyBuddy>[], error: 'Please log in first.');
    }

    final college = CollegeService.instance.selectedCollege;
    if (college == null) {
      return (
        nearby: <NearbyBuddy>[],
        error: 'Select your campus first (map setup).',
      );
    }

    final pos = await _myPosition();
    if (pos == null) {
      return (
        nearby: <NearbyBuddy>[],
        error: 'Turn on location to find nearby students.',
      );
    }

    final hereLat = pos.latitude;
    final hereLng = pos.longitude;
    if (!CampusGeofence.contains(LatLng(hereLat, hereLng))) {
      return (
        nearby: <NearbyBuddy>[],
        error: 'Buddy Finder only works when you are on campus.',
      );
    }

    await ProfileService.instance.updateLocation(lat: hereLat, lng: hereLng);
    await ProfileService.instance.setCampusName(college.name);

    final peers = await ProfileService.instance.campusPeers(
      campusName: college.name,
      excludeUserId: uid,
    );

    final nearby = <NearbyBuddy>[];
    for (final p in peers) {
      final lat = (p['last_lat'] as num?)?.toDouble();
      final lng = (p['last_lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final d = _meters(hereLat, hereLng, lat, lng);
      if (d <= nearbyMeters) {
        nearby.add(
          NearbyBuddy(
            userId: p['id'] as String,
            email: p['email'] as String? ?? '',
            displayName: p['display_name'] as String? ?? 'Student',
            distanceMeters: d,
          ),
        );
      }
    }
    nearby.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    final request = await _supabase.client
        .from('buddy_requests')
        .insert({
          'requester_id': uid,
          'destination': destination.trim(),
          'campus_name': college.name,
          'lat': hereLat,
          'lng': hereLng,
          'status': 'open',
        })
        .select()
        .single();

    final requestId = request['id'] as String;
    final me = _supabase.auth.currentUser;
    final myName = me?.userMetadata?['display_name'] ??
        me?.email?.split('@').first ??
        'A student';

    if (nearby.isNotEmpty) {
      await _supabase.client.from('buddy_notifications').insert(
            nearby
                .map(
                  (n) => {
                    'request_id': requestId,
                    'recipient_id': n.userId,
                    'message':
                        '$myName wants a buddy to “${destination.trim()}” (~${n.distanceMeters.round()} m away).',
                  },
                )
                .toList(),
          );
    }

    return (nearby: nearby, error: null);
  }

  Future<List<BuddyNotificationItem>> myNotifications() async {
    if (!_supabase.isReady) return [];
    final uid = ProfileService.instance.currentUserId;
    if (uid == null) return [];

    final rows = await _supabase.client
        .from('buddy_notifications')
        .select()
        .eq('recipient_id', uid)
        .order('created_at', ascending: false)
        .limit(40);

    return (rows as List)
        .map((r) {
          final m = Map<String, dynamic>.from(r as Map);
          return BuddyNotificationItem(
            id: m['id'] as String,
            message: m['message'] as String? ?? '',
            createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
                DateTime.now(),
            read: m['read'] as bool? ?? false,
            requestId: m['request_id'] as String?,
          );
        })
        .toList();
  }

  Future<void> markRead(String id) async {
    if (!_supabase.isReady) return;
    await _supabase.client
        .from('buddy_notifications')
        .update({'read': true}).eq('id', id);
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
