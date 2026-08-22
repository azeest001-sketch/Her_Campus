import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wifi_scan/wifi_scan.dart';

import 'device_id.dart';

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

const int _kWifiRssiThreshold = -70;

const _hotspotKeywords = [
  'iphone', 'ipad', 'android', 'galaxy', 'pixel', 'hotspot',
  'mobile', 'phone', 'moto', 'redmi', 'oneplus', 'realme',
  'oppo', 'vivo', 'poco', 'nokia', 'huawei', 'mi ', 'xiaomi',
  'jio', 'airtel', 'bsnl', 'vi ', 'vodafone', 'idea',
];

class WifiScanService {
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
    var fixedRoutersSkipped = 0;

    for (final ap in results) {
      final rssi = ap.level;
      if (rssi < _kWifiRssiThreshold) {
        fixedRoutersSkipped++;
        continue;
      }
      if (rssi > -35) {
        fixedRoutersSkipped++;
        continue;
      }

      final ssid = ap.ssid.toLowerCase();
      final looksLikeHotspot =
          _hotspotKeywords.any(ssid.contains) || ssid.isEmpty;
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
