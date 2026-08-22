import 'package:team_map/map_kit/map_kit.dart';

/// Crowd density sample for the heatwave map mockup.
enum CrowdIntensity { calm, moderate, busy, packed }

class CrowdHotspotModel {
  const CrowdHotspotModel({
    required this.id,
    required this.label,
    required this.position,
    required this.intensity,
    required this.peopleEstimate,
    required this.updatedAt,
  });

  final String id;
  final String label;
  final LatLng position;
  final CrowdIntensity intensity;
  final int peopleEstimate;
  final DateTime updatedAt;

  String get intensityLabel {
    switch (intensity) {
      case CrowdIntensity.calm:
        return 'Calm';
      case CrowdIntensity.moderate:
        return 'Moderate';
      case CrowdIntensity.busy:
        return 'Busy';
      case CrowdIntensity.packed:
        return 'Packed';
    }
  }

  /// Hex color for map markers / legend.
  String get colorHex {
    switch (intensity) {
      case CrowdIntensity.calm:
        return '#22C55E';
      case CrowdIntensity.moderate:
        return '#EAB308';
      case CrowdIntensity.busy:
        return '#F97316';
      case CrowdIntensity.packed:
        return '#EF4444';
    }
  }
}
