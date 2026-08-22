import 'package:safe_campus/shared/location/zone_service.dart';

/// Thin map abstraction for later custom campus map handoff.
abstract class CampusMapController {
  void moveTo(LatLng target, {double zoom = 15.5});
  void dispose();
}
