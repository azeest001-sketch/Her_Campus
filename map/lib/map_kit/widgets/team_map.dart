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

  @override
  State<TeamMap> createState() => _TeamMapState();
}

class _TeamMapState extends State<TeamMap> {
  TeamMapController? _controller;
  var _ready = false;

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
