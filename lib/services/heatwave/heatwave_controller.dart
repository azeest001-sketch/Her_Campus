import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:team_map/map_kit/map_kit.dart';

import '../campus_geofence.dart';
import '../college_service.dart';
import 'crowd_estimate.dart';
import 'crowd_estimator.dart';
import 'device_id.dart';

/// Live Wi‑Fi / Bluetooth crowd sensing for the student Heatwave Map.
class HeatwaveController extends ChangeNotifier {
  HeatwaveController({CrowdEstimator? estimator})
      : _estimator = estimator ?? CrowdEstimator();

  final CrowdEstimator _estimator;

  Timer? _loop;
  String? deviceId;
  CrowdEstimate? lastEstimate;
  String? statusMessage;
  bool scanning = false;
  bool permissionsOk = false;
  bool onCampus = false;
  double? myLat;
  double? myLng;

  final List<CrowdHotspot> hotspots = [];

  Future<void> start() async {
    deviceId ??= await DeviceId.get();
    permissionsOk = await ensurePermissions();
    if (!permissionsOk) {
      notifyListeners();
      return;
    }

    await _tick();
    _loop ??= Timer.periodic(const Duration(seconds: 20), (_) => _tick());
  }

  Future<void> stop() async {
    _loop?.cancel();
    _loop = null;
    scanning = false;
    notifyListeners();
  }

  /// Location must be on + granted before the map blue-dot / scans work on phones.
  Future<bool> ensurePermissions() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      statusMessage =
          'Turn ON Location/GPS in phone settings, then tap Retry.';
      notifyListeners();
      try {
        await Geolocator.openLocationSettings();
      } catch (_) {}
      return false;
    }

    var geo = await Geolocator.checkPermission();
    if (geo == LocationPermission.denied) {
      geo = await Geolocator.requestPermission();
    }
    if (geo == LocationPermission.deniedForever) {
      statusMessage =
          'Location is blocked. Open App Settings → enable Location, then Retry.';
      notifyListeners();
      try {
        await openAppSettings();
      } catch (_) {}
      return false;
    }
    if (geo == LocationPermission.denied) {
      statusMessage = 'Allow Location permission to use Heatwave Map.';
      notifyListeners();
      return false;
    }

    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.nearbyWifiDevices.request();

    permissionsOk = true;
    statusMessage = 'Location ready.';
    notifyListeners();
    return true;
  }

  Future<void> _tick() async {
    if (scanning) return;
    scanning = true;
    statusMessage = 'Checking campus location…';
    notifyListeners();

    try {
      await _updateLocation();
      if (myLat == null || myLng == null) {
        statusMessage =
            'Could not read GPS. Try outdoors / near a window, then Retry.';
        return;
      }

      if (CollegeService.instance.selectedCollege == null) {
        onCampus = false;
        statusMessage = 'Select your college before scanning.';
        return;
      }

      final here = LatLng(myLat!, myLng!);
      onCampus = CampusGeofence.contains(here);
      if (!onCampus) {
        statusMessage =
            'You are outside campus. Walk inside the automatic or drawn border to scan.';
        return;
      }

      statusMessage = 'Scanning… keep Wi‑Fi + Bluetooth ON. Wait ~15s.';
      notifyListeners();

      final estimate = await _estimator.estimate();
      lastEstimate = estimate;

      if (estimate.approxPeople > 0) {
        _mergeHotspot(
          lat: myLat!,
          lng: myLng!,
          estimate: estimate,
        );
      }

      statusMessage = estimate.detail ??
          (estimate.approxPeople <= 0
              ? 'No crowd signal nearby'
              : 'Nearby looks ${heatLevelLabel(estimate.approxPeople).toLowerCase()}');
    } catch (e) {
      statusMessage = 'Scan failed: $e';
      debugPrint(statusMessage);
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  Future<void> _updateLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      myLat = pos.latitude;
      myLng = pos.longitude;
    } catch (e) {
      debugPrint('GPS error: $e');
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          myLat = last.latitude;
          myLng = last.longitude;
          return;
        }
      } catch (_) {}
      myLat = null;
      myLng = null;
    }
  }

  void _mergeHotspot({
    required double lat,
    required double lng,
    required CrowdEstimate estimate,
  }) {
    final gridLat = (lat * 4000).round() / 4000;
    final gridLng = (lng * 4000).round() / 4000;
    final id = '${gridLat}_$gridLng';

    final existing = hotspots.where((h) => h.id == id).toList();
    if (existing.isNotEmpty) {
      final h = existing.first;
      h.approxCount = math.max(h.approxCount, estimate.approxPeople);
      h.btCount = estimate.btCount;
      h.wifiCount = estimate.wifiCount;
      h.updatedAt = DateTime.now();
      h.live = true;
    } else {
      hotspots.add(
        CrowdHotspot(
          id: id,
          latitude: gridLat,
          longitude: gridLng,
          approxCount: estimate.approxPeople,
          btCount: estimate.btCount,
          wifiCount: estimate.wifiCount,
          updatedAt: DateTime.now(),
          live: true,
        ),
      );
    }

    final cutoff = DateTime.now().subtract(const Duration(minutes: 3));
    for (final h in hotspots) {
      if (h.updatedAt.isBefore(cutoff)) h.live = false;
    }
    hotspots.removeWhere(
      (h) => !h.live &&
          h.updatedAt.isBefore(
            DateTime.now().subtract(const Duration(minutes: 15)),
          ),
    );
  }

  /// Calm / Moderate / Busy / Packed — shown as colours only in the UI.
  static String heatLevelLabel(int approxCount) {
    if (approxCount <= 4) return 'Calm';
    if (approxCount <= 10) return 'Moderate';
    if (approxCount <= 20) return 'Busy';
    return 'Packed';
  }

  static String heatColorHex(int approxCount) {
    switch (heatLevelLabel(approxCount)) {
      case 'Calm':
        return '#22C55E';
      case 'Moderate':
        return '#EAB308';
      case 'Busy':
        return '#F97316';
      default:
        return '#EF4444';
    }
  }

  static double heatRadius(int approxCount) {
    switch (heatLevelLabel(approxCount)) {
      case 'Calm':
        return 28;
      case 'Moderate':
        return 38;
      case 'Busy':
        return 50;
      default:
        return 64;
    }
  }
}
