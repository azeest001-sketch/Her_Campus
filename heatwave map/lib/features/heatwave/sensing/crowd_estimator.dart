import 'package:safe_campus/features/heatwave/data/crowd_zone.dart';
import 'package:safe_campus/features/heatwave/sensing/bluetooth_scan_service.dart';
import 'package:safe_campus/features/heatwave/sensing/wifi_scan_service.dart';

class CrowdEstimator {
  CrowdEstimator({
    BluetoothScanService? bluetooth,
    WifiScanService? wifi,
  })  : _bluetooth = bluetooth ?? BluetoothScanService(),
        _wifi = wifi ?? WifiScanService();

  final BluetoothScanService _bluetooth;
  final WifiScanService _wifi;

  /// Approximate people from nearby radio signals (anonymous counts only).
  Future<CrowdEstimate> estimate() async {
    // Run scans sequentially on some phones — parallel BT+WiFi can fail.
    final btCount = await _bluetooth.scanOnce();
    final wifi = await _wifi.scanOnce();

    final wifiCount = wifi.available ? wifi.count : 0;
    final raw = btCount + wifiCount;
    // Mild dampening for multi-gadget inflation.
    final approx = raw == 0 ? 0 : (raw * 0.7).round().clamp(1, 500);

    final details = <String>[];
    if (_bluetooth.lastError != null) details.add(_bluetooth.lastError!);
    if (wifi.message != null) details.add(wifi.message!);

    return CrowdEstimate(
      btCount: btCount,
      wifiCount: wifiCount,
      approxPeople: approx,
      wifiAvailable: wifi.available,
      detail: details.isEmpty ? null : details.join(' · '),
    );
  }
}
