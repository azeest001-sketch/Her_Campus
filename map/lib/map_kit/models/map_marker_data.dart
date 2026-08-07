import 'package:maplibre_gl/maplibre_gl.dart';

/// A pin your teammates can drop on the map.
class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.iconImage = 'marker-15',
    this.iconSize = 1.2,
    this.iconColor,
    this.data,
  });

  /// Stable id so you can update / remove later.
  final String id;

  final LatLng position;
  final String? title;
  final String? snippet;

  /// Built-in sprite name from the OpenFreeMap / MapLibre style, or a custom
  /// image you registered with [TeamMapController.addImage].
  final String iconImage;
  final double iconSize;

  /// Optional tint, e.g. `#E53935`.
  final String? iconColor;

  /// Arbitrary payload for your feature (route stop, shop id, …).
  final Map<String, dynamic>? data;
}
