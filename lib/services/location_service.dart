import 'package:geolocator/geolocator.dart';
import 'package:team_map/map_kit/map_kit.dart';

/// Device GPS helpers for precise campus pin placement.
///
/// TODO(backend): optional — location stays on-device unless you choose to log it.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<LatLng?> getCurrentLatLng() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw StateError('Location services are turned off');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission denied');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }
}
