import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/map_config.dart';
import '../team_map_controller.dart';

/// Drop-in OpenFreeMap view your teammates embed in their screens.
///
/// ```dart
/// TeamMap(
///   config: const MapConfig(enable3dOnStart: false),
///   onReady: (controller) async {
///     await controller.addMarker(...);
///     controller.onMapTapped = (pos) { ... };
///   },
/// )
/// ```
class TeamMap extends StatefulWidget {
  const TeamMap({
    super.key,
    this.config = const MapConfig(),
    this.onReady,
    this.overlayBuilder,
  });

  final MapConfig config;

  /// Called once the map style is loaded and [TeamMapController] is ready.
  final void Function(TeamMapController controller)? onReady;

  /// Optional UI layered on top of the map (FABs, search bar, legend, …).
  final Widget Function(BuildContext context, TeamMapController controller)?
      overlayBuilder;

  static var _platformConfigured = false;

  /// Puts the Android platform view into Hybrid Composition.
  ///
  /// `maplibre_gl` still defaults to the legacy Virtual Display mode, which
  /// renders the map black and drops text input whenever a dialog, bottom sheet
  /// or keyboard is shown over it. Runs once, before the first map is built.
  static void ensurePlatformConfigured() {
    if (_platformConfigured) return;
    _platformConfigured = true;
    MapLibreMap.useHybridComposition = true;
  }

  @override
  State<TeamMap> createState() => _TeamMapState();
}

class _TeamMapState extends State<TeamMap> {
  TeamMapController? _controller;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    TeamMap.ensurePlatformConfigured();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MapLibreMap(
          styleString: widget.config.style.url,
          initialCameraPosition: widget.config.initialCamera,
          minMaxZoomPreference: MinMaxZoomPreference(
            widget.config.minZoom,
            widget.config.maxZoom,
          ),
          compassEnabled: widget.config.compassEnabled,
          tiltGesturesEnabled: widget.config.tiltGesturesEnabled,
          rotateGesturesEnabled: widget.config.rotateGesturesEnabled,
          myLocationEnabled: widget.config.myLocationEnabled,
          // Without this, tapping fills/lines/markers never fires onMapClick —
          // which breaks border drawing over campus polygons.
          featureTapsTriggersMapClick: true,
          // Later entries draw on top. The default puts fills last, so a campus
          // boundary would cover its own pins.
          annotationOrder: const [
            AnnotationType.fill,
            AnnotationType.line,
            AnnotationType.circle,
            AnnotationType.symbol,
          ],
          trackCameraPosition: true,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          onMapClick: (point, latLng) {
            _controller?.onMapTapped?.call(latLng);
          },
          onMapLongClick: (point, latLng) {
            _controller?.onMapLongPressed?.call(latLng);
          },
        ),
        if (_ready &&
            _controller != null &&
            widget.overlayBuilder != null)
          widget.overlayBuilder!(context, _controller!),
      ],
    );
  }

  void _onMapCreated(MapLibreMapController mapController) {
    final team = TeamMapController(
      mapController,
      fallbackCenter: widget.config.initialCenter,
      fallbackZoom: widget.config.initialZoom,
    );
    team.bindStyle(
      widget.config.style,
      startIn3d: widget.config.enable3dOnStart,
    );
    mapController.onSymbolTapped.add(team.handleSymbolTapped);
    _controller = team;
  }

  Future<void> _onStyleLoaded() async {
    final team = _controller;
    if (team == null) return;

    await team.onStyleLoaded(startIn3d: widget.config.enable3dOnStart);

    if (!mounted) return;
    setState(() => _ready = true);
    widget.onReady?.call(team);
  }

  @override
  void dispose() {
    final map = _controller?.raw;
    final team = _controller;
    if (map != null && team != null) {
      map.onSymbolTapped.remove(team.handleSymbolTapped);
    }
    super.dispose();
  }
}
