import 'package:maplibre_gl/maplibre_gl.dart';

import '../open_free_map_styles.dart';

/// Starting options for [TeamMap].
class MapConfig {
  const MapConfig({
    this.style = OpenFreeMapStyle.liberty,
    this.initialCenter = const LatLng(28.6139, 77.2090), // New Delhi
    this.initialZoom = 12,
    this.initialBearing = 0,
    this.initialTilt = 0,
    this.minZoom = 1,
    this.maxZoom = 20,
    this.enable3dOnStart = false,
    this.myLocationEnabled = false,
    this.compassEnabled = true,
    this.tiltGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
  });

  final OpenFreeMapStyle style;
  final LatLng initialCenter;
  final double initialZoom;
  final double initialBearing;
  final double initialTilt;
  final double minZoom;
  final double maxZoom;

  /// If true, tilts the camera and shows 3D buildings after the style loads.
  final bool enable3dOnStart;

  final bool myLocationEnabled;
  final bool compassEnabled;
  final bool tiltGesturesEnabled;
  final bool rotateGesturesEnabled;

  CameraPosition get initialCamera => CameraPosition(
        target: initialCenter,
        zoom: initialZoom,
        bearing: initialBearing,
        tilt: enable3dOnStart ? 60 : initialTilt,
      );
}
