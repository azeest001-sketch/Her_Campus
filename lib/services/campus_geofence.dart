import 'dart:math' as math;

import 'package:team_map/map_kit/map_kit.dart';

import 'campus_map_editor_service.dart';
import 'college_service.dart';

/// Campus presence checks for Heatwave Map.
class CampusGeofence {
  CampusGeofence._();

  /// Custom drawn ring if the student traced ≥3 points.
  static List<LatLng>? customRing() {
    final points = CampusMapEditorService.instance.borderPoints;
    if (points.length < 3) return null;
    return List<LatLng>.from(points);
  }

  /// Automatic OSM college outline from map selection (when available).
  static List<LatLng>? automaticRing() {
    final college = CollegeService.instance.selectedCollege;
    if (college == null || !college.hasBoundary) return null;
    final boundary = college.boundary!;
    if (boundary.length < 3) return null;
    return List<LatLng>.from(boundary);
  }

  /// Best single ring for display helpers (custom preferred, else automatic).
  static List<LatLng>? campusRing() => customRing() ?? automaticRing();

  /// True when there is a college and a usable campus outline (or center).
  static bool get hasCampusMapReady {
    final college = CollegeService.instance.selectedCollege;
    if (college == null) return false;
    if (campusRing() != null) return true;
    // College pin alone is enough to open the map; sensing uses a radius.
    return true;
  }

  @Deprecated('Use hasCampusMapReady')
  static bool get hasConfirmedCustomCampus => hasCampusMapReady;

  /// True inside the manual border **or** the automatic college border
  /// (or within ~500m of the college pin if neither outline exists).
  static bool contains(LatLng point) {
    final custom = customRing();
    if (custom != null && pointInPolygon(point, custom)) return true;

    final automatic = automaticRing();
    if (automatic != null && pointInPolygon(point, automatic)) return true;

    // If either outline exists, stay strict to those polygons (no radius).
    if (custom != null || automatic != null) return false;

    final college = CollegeService.instance.selectedCollege;
    if (college == null) return false;
    return _distanceMeters(point, college.position) <= 500;
  }

  static bool pointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final pi = polygon[i];
      final pj = polygon[j];
      final intersect = ((pi.longitude > point.longitude) !=
              (pj.longitude > point.longitude)) &&
          (point.latitude <
              (pj.latitude - pi.latitude) *
                      (point.longitude - pi.longitude) /
                      (pj.longitude - pi.longitude) +
                  pi.latitude);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * earth * math.asin(math.sqrt(h));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
