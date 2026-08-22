import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:safe_campus/shared/device_id.dart';

class WifiScanResultSummary {
  const WifiScanResultSummary({
    required this.available,
    required this.count,
    this.message,
  });

  final bool available;
  final int count;
  final String? message;
}

/// WiFi RSSI threshold for proximity filtering.
/// -70 dBm ≈ 10–15 m in open space for WiFi.
/// -60 dBm ≈ ~5–8 m (stricter, fewer false positives).
const int _kWifiRssiThreshold = -70;

/// SSID keywords that strongly suggest a mobile personal hotspot.
const _hotspotKeywords = [
  'iphone', 'ipad', 'android', 'galaxy', 'pixel', 'hotspot',
  'mobile', 'phone', 'moto', 'redmi', 'oneplus', 'realme',
  'oppo', 'vivo', 'poco', 'nokia', 'huawei', 'mi ', 'xiaomi',
  'jio', 'airtel', 'bsnl', 'vi ', 'vodafone', 'idea',
];

class WifiScanService {
  /// Real WiFi AP / hotspot scan on Android. iOS cannot scan nearby APs.
  Future<WifiScanResultSummary> scanOnce() async {
    if (!Platform.isAndroid) {
      return const WifiScanResultSummary(
        available: false,
        count: 0,
        message: 'WiFi crowd scan unavailable on iOS',
      );
    }

    try {
      final can = await WiFiScan.instance.canStartScan(askPermissions: true);
      if (can != CanStartScan.yes) {
        // Still try cached results — useful if scan is throttled.
        final cached = await _readResults();
        if (cached.count > 0) return cached;

        return WifiScanResultSummary(
          available: false,
          count: 0,
          message: _canStartMessage(can),
        );
      }

      final started = await WiFiScan.instance.startScan();
      if (!started) {
        final cached = await _readResults();
        if (cached.count > 0) return cached;
        return const WifiScanResultSummary(
          available: false,
          count: 0,
          message: 'WiFi scan failed — turn WiFi ON on this phone',
        );
      }

      await Future<void>.delayed(const Duration(seconds: 4));
      return _readResults();
    } catch (e) {
      debugPrint('WiFi scan error: $e');
      return WifiScanResultSummary(
        available: false,
        count: 0,
        message: 'WiFi scan error: $e',
      );
    }
  }

  Future<WifiScanResultSummary> _readResults() async {
    final canGet = await WiFiScan.instance.canGetScannedResults(
      askPermissions: true,
    );
    if (canGet != CanGetScannedResults.yes) {
      return WifiScanResultSummary(
        available: false,
        count: 0,
        message: _canGetMessage(canGet),
      );
    }

    final results = await WiFiScan.instance.getScannedResults();
    final unique = <String>{};
    int fixedRoutersSkipped = 0;

    for (final ap in results) {
      // --- Filter: keep only likely mobile hotspots ---
      //
      final rssi = ap.level; // dBm, negative — closer to 0 = stronger

      // 1. Distance filter: skip anything beyond ~15 m (RSSI too weak).
      if (rssi < _kWifiRssiThreshold) {
        fixedRoutersSkipped++;
        continue; // Too far away — not a nearby person's hotspot
      }

      // 2. Skip extremely strong fixed APs (bolted to walls/ceilings).
      if (rssi > -35) {
        fixedRoutersSkipped++;
        continue; // Right next to a fixed router — skip it
      }

      // 3. SSID keyword matching — hotspots commonly contain these strings.
      final ssid = ap.ssid.toLowerCase();
      final looksLikeHotspot = _hotspotKeywords.any(ssid.contains) ||
          ssid.isEmpty; // hidden SSID — could be a hotspot

      if (!looksLikeHotspot) {
        fixedRoutersSkipped++;
        continue;
      }

      final raw = ap.bssid.isNotEmpty ? ap.bssid : ap.ssid;
      if (raw.isEmpty) continue;
      unique.add(DeviceId.hashSignalId(raw));
    }

    debugPrint(
      'WiFi hotspots: ${unique.length} (skipped $fixedRoutersSkipped fixed APs)',
    );
    return WifiScanResultSummary(
      available: true,
      count: unique.length,
      message: unique.isEmpty
          ? 'No mobile hotspots nearby (fixed routers excluded)'
          : null,
    );
  }

  String _canStartMessage(CanStartScan can) {
    switch (can) {
      case CanStartScan.notSupported:
        return 'WiFi scan not supported on this phone';
      case CanStartScan.noLocationPermissionRequired:
      case CanStartScan.noLocationPermissionDenied:
      case CanStartScan.noLocationPermissionUpgradeAccuracy:
        return 'Allow Location permission for WiFi scan';
      case CanStartScan.noLocationServiceDisabled:
        return 'Turn ON Location (GPS) for WiFi scan';
      case CanStartScan.failed:
        return 'WiFi scan failed to start';
      case CanStartScan.yes:
        return 'OK';
    }
  }

  String _canGetMessage(CanGetScannedResults can) {
    switch (can) {
      case CanGetScannedResults.notSupported:
        return 'WiFi results not supported';
      case CanGetScannedResults.noLocationPermissionRequired:
      case CanGetScannedResults.noLocationPermissionDenied:
      case CanGetScannedResults.noLocationPermissionUpgradeAccuracy:
        return 'Allow Location permission to read WiFi results';
      case CanGetScannedResults.noLocationServiceDisabled:
        return 'Turn ON Location (GPS) to read WiFi results';
      case CanGetScannedResults.yes:
        return 'OK';
    }
  }
}
