import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_id.dart';

/// RSSI threshold ≈ devices within ~15 m.
const int _kRssiThreshold = -70;

class BluetoothScanService {
  final Set<String> _seen = {};
  StreamSubscription<List<ScanResult>>? _sub;
  bool _scanning = false;
  String? lastError;

  bool get isScanning => _scanning;
  int get uniqueCount => _seen.length;

  Future<bool> isSupported() async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<int> scanOnce({Duration timeout = const Duration(seconds: 12)}) async {
    _seen.clear();
    lastError = null;

    if (!await isSupported()) {
      lastError = 'BLE not supported';
      return 0;
    }

    if (Platform.isAndroid) {
      try {
        final adapter = await FlutterBluePlus.adapterState
            .first
            .timeout(const Duration(seconds: 3));
        if (adapter != BluetoothAdapterState.on) {
          try {
            await FlutterBluePlus.turnOn();
          } catch (e) {
            lastError = 'Turn on Bluetooth on this phone';
            debugPrint('Could not turn Bluetooth on: $e');
            return 0;
          }
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      } catch (_) {
        lastError = 'Bluetooth adapter check failed';
      }
    }

    await _sub?.cancel();
    _sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.rssi < _kRssiThreshold) continue;
        final raw = r.device.remoteId.str;
        if (raw.isEmpty) continue;
        _seen.add(DeviceId.hashSignalId(raw));
      }
    }, onError: (Object e) {
      lastError = 'BLE scan stream error: $e';
    });

    try {
      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
        androidScanMode: AndroidScanMode.lowLatency,
      );
      _scanning = true;
      await Future<void>.delayed(timeout + const Duration(milliseconds: 500));
    } catch (e) {
      lastError = 'BLE startScan failed: $e';
      _scanning = false;
    } finally {
      await stop();
    }

    return _seen.length;
  }

  Future<void> stop() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _sub?.cancel();
    _sub = null;
    _scanning = false;
  }
}
