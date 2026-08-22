import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

/// Builds / validates closed campus outlines.
class CampusBoundary {
  CampusBoundary._();

  /// Soft upper size for a single campus footprint (~10 km across).
  /// Bigger shapes are usually cities/districts, not the campus.
  static const maxCampusSpanMeters = 10000.0;

  /// Approximate circle around [center] — kept for rare explicit callers.
  static List<LatLng> circular(
    LatLng center, {
    double radiusMeters = 180,
    int steps = 64,
  }) {
    final latRad = center.latitude * math.pi / 180;
    final dLat = radiusMeters / 111320.0;
    final cosLat = math.cos(latRad).abs().clamp(0.2, 1.0);
    final dLon = radiusMeters / (111320.0 * cosLat);

    final points = <LatLng>[];
    for (var i = 0; i <= steps; i++) {
      final t = (i / steps) * math.pi * 2;
      points.add(
        LatLng(
          center.latitude + dLat * math.sin(t),
          center.longitude + dLon * math.cos(t),
        ),
      );
    }
    return points;
  }

  /// Nominatim / GeoJSON geometry → natural outer ring.
  ///
  /// Ignores points and lines. For multipolygons, picks the ring closest to
  /// [near] when provided, otherwise the largest plausible campus-sized ring.
  static List<LatLng>? fromGeoJson(
    dynamic geojson, {
    LatLng? near,
  }) {
    if (geojson is! Map) return null;
    final type = geojson['type']?.toString();
    final coordinates = geojson['coordinates'];
    if (coordinates is! List) return null;

    if (type == 'Polygon') {
      final ring =
          _ringFromCoords(coordinates.isNotEmpty ? coordinates.first : null);
      return _acceptCampusRing(ring, near: near);
    }

    if (type == 'MultiPolygon') {
      final rings = <List<LatLng>>[];
      for (final polygon in coordinates) {
        if (polygon is! List || polygon.isEmpty) continue;
        final ring = _ringFromCoords(polygon.first);
        final accepted = _acceptCampusRing(ring, near: near);
        if (accepted != null) rings.add(accepted);
      }
      if (rings.isEmpty) return null;
      if (near != null) {
        rings.sort(
          (a, b) => _distanceMeters(near, _ringCentroid(a))
              .compareTo(_distanceMeters(near, _ringCentroid(b))),
        );
        return rings.first;
      }
      rings.sort((a, b) => _ringArea(b).compareTo(_ringArea(a)));
      return rings.first;
    }

    return null;
  }

  /// Rejects city/district-scale shapes and rings far from the campus pin.
  static List<LatLng>? sanitize(
    List<LatLng>? ring, {
    LatLng? near,
  }) =>
      _acceptCampusRing(ring, near: near);

  /// Rejects city/district-scale shapes and rings far from the campus pin.
  static List<LatLng>? _acceptCampusRing(
    List<LatLng>? ring, {
    LatLng? near,
  }) {
    if (ring == null || ring.length < 4) return null;
    final span = spanMeters(ring);
    if (span <= 0 || span > maxCampusSpanMeters) return null;
    if (near != null) {
      final centroid = _ringCentroid(ring);
      // Pin should sit on / near the campus, not kilometers away.
      if (_distanceMeters(near, centroid) > math.max(span, 1500)) {
        return null;
      }
    }
    return ring;
  }

  static double spanMeters(List<LatLng> ring) {
    var minLat = ring.first.latitude;
    var maxLat = ring.first.latitude;
    var minLon = ring.first.longitude;
    var maxLon = ring.first.longitude;
    for (final p in ring) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLon = math.min(minLon, p.longitude);
      maxLon = math.max(maxLon, p.longitude);
    }
    final sw = LatLng(minLat, minLon);
    final ne = LatLng(maxLat, maxLon);
    return _distanceMeters(sw, ne);
  }

  static List<LatLng>? _ringFromCoords(dynamic ring) {
    if (ring is! List || ring.length < 4) return null;

    final points = <LatLng>[];
    for (final raw in ring) {
      if (raw is! List || raw.length < 2) continue;
      final lon = (raw[0] as num?)?.toDouble();
      final lat = (raw[1] as num?)?.toDouble();
      if (lat == null || lon == null) continue;
      points.add(LatLng(lat, lon));
    }
    if (points.length < 4) return null;
    return _ensureClosed(points);
  }

  static LatLng _ringCentroid(List<LatLng> ring) {
    var lat = 0.0;
    var lon = 0.0;
    final n = ring.length > 1 &&
            ring.first.latitude == ring.last.latitude &&
            ring.first.longitude == ring.last.longitude
        ? ring.length - 1
        : ring.length;
    for (var i = 0; i < n; i++) {
      lat += ring[i].latitude;
      lon += ring[i].longitude;
    }
    return LatLng(lat / n, lon / n);
  }

  static double _ringArea(List<LatLng> ring) {
    var sum = 0.0;
    for (var i = 0; i < ring.length - 1; i++) {
      sum += ring[i].longitude * ring[i + 1].latitude;
      sum -= ring[i + 1].longitude * ring[i].latitude;
    }
    return sum.abs();
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * earth * math.asin(math.sqrt(h));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  static List<LatLng> _ensureClosed(List<LatLng> points) {
    if (points.isEmpty) return points;
    final first = points.first;
    final last = points.last;
    if (first.latitude == last.latitude &&
        first.longitude == last.longitude) {
      return List<LatLng>.from(points);
    }
    return [...points, first];
  }
}
