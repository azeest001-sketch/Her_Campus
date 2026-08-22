import 'package:maplibre_gl/maplibre_gl.dart';

/// A pin your teammates can drop on the map.
class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.iconImage = 'marker',
    this.iconSize = 1.2,
    this.iconColor,
    this.data,
  });

  /// Stable id so you can update / remove later.
  final String id;

  final LatLng position;
  final String? title;
  final String? snippet;

  /// Sprite name, only used if you draw the symbol yourself via
  /// `TeamMapController.raw`.
  ///
  /// [TeamMapController.addMarker] ignores this and draws a circle instead,
  /// because sprite names vary per style and a missing one makes MapLibre drop
  /// the whole symbol, label included.
  final String iconImage;

  /// Scales the pin dot (1.0 ≈ 7px radius).
  final double iconSize;

  /// Pin fill colour, e.g. `#E53935`.
  final String? iconColor;

  /// Arbitrary payload for your feature (route stop, shop id, …).
  final Map<String, dynamic>? data;
}
