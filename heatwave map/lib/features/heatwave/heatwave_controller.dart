import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safe_campus/features/heatwave/data/crowd_zone.dart';
import 'package:safe_campus/features/heatwave/sensing/crowd_estimator.dart';
import 'package:safe_campus/shared/device_id.dart';

class CrowdHotspot {
  CrowdHotspot({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.approxCount,
    required this.btCount,
    required this.wifiCount,
    required this.updatedAt,
    required this.live,
  });

  final String id;
  final double latitude;
  final double longitude;
  int approxCount;
  int btCount;
  int wifiCount;
  DateTime updatedAt;
  bool live;
}

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
  double? myLat;
  double? myLng;

  /// Only places where crowd was actually detected (approx > 0).
  final List<CrowdHotspot> hotspots = [];

  Future<void> start() async {
    deviceId ??= await DeviceId.get();
    permissionsOk = await ensurePermissions();
    if (!permissionsOk) {
      statusMessage =
          'Allow Location + Bluetooth (+ nearby WiFi on Android), then tap Scan.';
      notifyListeners();
      return;
    }

    await _tick();
    _loop ??= Timer.periodic(const Duration(seconds: 20), (_) => _tick());
  }

  Future<bool> ensurePermissions() async {
    // Location service must be ON for Android WiFi/BLE scans on many phones.
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      statusMessage =
          'Turn ON Location/GPS on this phone, then reopen Heatwave.';
      notifyListeners();
      await Geolocator.openLocationSettings();
      return false;
    }

    final location = await Permission.locationWhenInUse.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.nearbyWifiDevices.request();

    if (!location.isGranted) {
      statusMessage =
          'Allow Location permission for this app (needed for WiFi/BT scan).';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> _tick() async {
    if (scanning) return;
    scanning = true;
    statusMessage =
        'Scanning… keep WiFi + Bluetooth ON on THIS phone. Wait ~15s.';
    notifyListeners();

    try {
      await _updateLocation();
      final estimate = await _estimator.estimate();
      lastEstimate = estimate;

      if (estimate.approxPeople > 0) {
        _upsertHotspot(estimate);
        statusMessage =
            'Detected ~${estimate.approxPeople} nearby '
            '(BT ${estimate.btCount}'
            '${estimate.wifiAvailable ? ', WiFi ${estimate.wifiCount}' : ', WiFi N/A'})';
      } else {
        final extra = estimate.detail == null ? '' : '\n${estimate.detail}';
        statusMessage =
            'No signals yet (BT ${estimate.btCount}'
            '${estimate.wifiAvailable ? ', WiFi ${estimate.wifiCount}' : ', WiFi N/A'}).'
            '$extra\n'
            'On THIS phone: WiFi ON + Location ON. '
            'On OTHER phone: turn on Personal Hotspot, then Scan again.';
      }
    } catch (e) {
      statusMessage = 'Scan error: $e';
      debugPrint(statusMessage);
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  Future<void> _updateLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      myLat = position.latitude;
      myLng = position.longitude;
    } catch (e) {
      debugPrint('Location unavailable: $e');
    }
  }

  void _upsertHotspot(CrowdEstimate estimate) {
    final lat = myLat ?? 0;
    final lng = myLng ?? 0;
    // Snap to ~25m grid so nearby scans merge into one hotspot.
    final gridLat = (lat * 4000).round() / 4000;
    final gridLng = (lng * 4000).round() / 4000;
    final id = '${gridLat.toStringAsFixed(5)}_${gridLng.toStringAsFixed(5)}';

    final existing = hotspots.where((h) => h.id == id).toList();
    if (existing.isNotEmpty) {
      final h = existing.first;
      h.approxCount = estimate.approxPeople;
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

    // Mark older hotspots as not live if far from now.
    final now = DateTime.now();
    for (final h in hotspots) {
      if (now.difference(h.updatedAt) > const Duration(minutes: 3)) {
        h.live = false;
      }
    }
  }

  Future<void> refreshNow() => _tick();

  /// Project hotspots onto a unit square for the blank canvas.
  List<OffsetHotspot> projectedHotspots() {
    if (hotspots.isEmpty) return [];

    var minLat = hotspots.first.latitude;
    var maxLat = hotspots.first.latitude;
    var minLng = hotspots.first.longitude;
    var maxLng = hotspots.first.longitude;
    for (final h in hotspots) {
      minLat = math.min(minLat, h.latitude);
      maxLat = math.max(maxLat, h.latitude);
      minLng = math.min(minLng, h.longitude);
      maxLng = math.max(maxLng, h.longitude);
    }
    if (myLat != null && myLng != null) {
      minLat = math.min(minLat, myLat!);
      maxLat = math.max(maxLat, myLat!);
      minLng = math.min(minLng, myLng!);
      maxLng = math.max(maxLng, myLng!);
    }

    var dLat = maxLat - minLat;
    var dLng = maxLng - minLng;
    if (dLat < 0.0003) {
      minLat -= 0.0002;
      maxLat += 0.0002;
      dLat = maxLat - minLat;
    }
    if (dLng < 0.0003) {
      minLng -= 0.0002;
      maxLng += 0.0002;
      dLng = maxLng - minLng;
    }

    return [
      for (final h in hotspots)
        OffsetHotspot(
          hotspot: h,
          x: ((h.longitude - minLng) / dLng).clamp(0.0, 1.0),
          y: (1 - (h.latitude - minLat) / dLat).clamp(0.0, 1.0),
        ),
    ];
  }

  Offset? projectedMe() {
    if (myLat == null || myLng == null || hotspots.isEmpty) {
      if (myLat != null && myLng != null && hotspots.isEmpty) {
        return const Offset(0.5, 0.5);
      }
      return null;
    }
    final pts = projectedHotspots();
    if (pts.isEmpty) return const Offset(0.5, 0.5);
    // Recompute same bounds as projectedHotspots — use me via a temp list.
    var minLat = hotspots.first.latitude;
    var maxLat = hotspots.first.latitude;
    var minLng = hotspots.first.longitude;
    var maxLng = hotspots.first.longitude;
    for (final h in hotspots) {
      minLat = math.min(minLat, h.latitude);
      maxLat = math.max(maxLat, h.latitude);
      minLng = math.min(minLng, h.longitude);
      maxLng = math.max(maxLng, h.longitude);
    }
    minLat = math.min(minLat, myLat!);
    maxLat = math.max(maxLat, myLat!);
    minLng = math.min(minLng, myLng!);
    maxLng = math.max(maxLng, myLng!);
    var dLat = maxLat - minLat;
    var dLng = maxLng - minLng;
    if (dLat < 0.0003) {
      minLat -= 0.0002;
      maxLat += 0.0002;
      dLat = maxLat - minLat;
    }
    if (dLng < 0.0003) {
      minLng -= 0.0002;
      maxLng += 0.0002;
      dLng = maxLng - minLng;
    }
    return Offset(
      ((myLng! - minLng) / dLng).clamp(0.0, 1.0),
      (1 - (myLat! - minLat) / dLat).clamp(0.0, 1.0),
    );
  }

  @override
  void dispose() {
    _loop?.cancel();
    super.dispose();
  }
}

class OffsetHotspot {
  const OffsetHotspot({
    required this.hotspot,
    required this.x,
    required this.y,
  });

  final CrowdHotspot hotspot;
  final double x;
  final double y;
}
