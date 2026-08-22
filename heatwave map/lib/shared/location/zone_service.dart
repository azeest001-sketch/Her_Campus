/// Simple lat/lng — kept for later custom campus map merge.
class LatLng {
  const LatLng(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Demo campus bounding box — replace with real campus coords later.
class CampusBounds {
  static const LatLng center = LatLng(28.5450, 77.1920);
  static const double south = 28.5400;
  static const double north = 28.5500;
  static const double west = 77.1850;
  static const double east = 77.1990;
}

class CampusZoneDef {
  const CampusZoneDef({
    required this.id,
    required this.name,
    required this.center,
  });

  final String id;
  final String name;
  final LatLng center;
}

/// Named demo zones for later map integration (not used by blank hotspot UI).
class ZoneService {
  static final List<CampusZoneDef> demoZones = [
    const CampusZoneDef(
      id: 'library',
      name: 'Library',
      center: LatLng(28.5462, 77.1905),
    ),
    const CampusZoneDef(
      id: 'cafeteria',
      name: 'Cafeteria',
      center: LatLng(28.5445, 77.1935),
    ),
    const CampusZoneDef(
      id: 'main_gate',
      name: 'Main gate',
      center: LatLng(28.5425, 77.1885),
    ),
    const CampusZoneDef(
      id: 'sports',
      name: 'Sports field',
      center: LatLng(28.5475, 77.1950),
    ),
    const CampusZoneDef(
      id: 'lecture_block',
      name: 'Lecture block',
      center: LatLng(28.5455, 77.1915),
    ),
    const CampusZoneDef(
      id: 'hostel',
      name: 'Hostel area',
      center: LatLng(28.5438, 77.1960),
    ),
  ];

  CampusZoneDef nearestZone(LatLng position) {
    CampusZoneDef best = demoZones.first;
    var bestDist = _approxDistSq(position, best.center);
    for (final z in demoZones.skip(1)) {
      final d = _approxDistSq(position, z.center);
      if (d < bestDist) {
        best = z;
        bestDist = d;
      }
    }
    return best;
  }

  CampusZoneDef? byId(String id) {
    for (final z in demoZones) {
      if (z.id == id) return z;
    }
    return null;
  }

  double _approxDistSq(LatLng a, LatLng b) {
    final dy = a.latitude - b.latitude;
    final dx = a.longitude - b.longitude;
    return dx * dx + dy * dy;
  }
}
