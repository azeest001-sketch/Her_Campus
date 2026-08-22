import 'bluetooth_scan_service.dart';
import 'crowd_estimate.dart';
import 'wifi_scan_service.dart';

class CrowdEstimator {
  CrowdEstimator({
    BluetoothScanService? bluetooth,
    WifiScanService? wifi,
  })  : _bluetooth = bluetooth ?? BluetoothScanService(),
        _wifi = wifi ?? WifiScanService();

  final BluetoothScanService _bluetooth;
  final WifiScanService _wifi;

  Future<CrowdEstimate> estimate() async {
    final btCount = await _bluetooth.scanOnce();
    final wifi = await _wifi.scanOnce();

    final wifiCount = wifi.available ? wifi.count : 0;
    final raw = btCount + wifiCount;
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
