import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset;
import 'package:maplibre_gl/maplibre_gl.dart';

import 'models/map_marker_data.dart';
import 'open_free_map_styles.dart';

typedef MapTapCallback = void Function(LatLng position);
typedef MarkerTapCallback = void Function(MapMarkerData marker);

/// High-level API your teammates should use.
///
/// Prefer these helpers over raw MapLibre calls. When you need something
/// advanced, use [raw] to reach the underlying [MapLibreMapController].
class TeamMapController {
  TeamMapController(
    this._map, {
    LatLng fallbackCenter = const LatLng(28.6139, 77.2090),
  }) {
    _fallbackCenter = fallbackCenter;
  }

  final MapLibreMapController _map;
  late LatLng _fallbackCenter;

  OpenFreeMapStyle _style = OpenFreeMapStyle.liberty;
  bool _is3d = false;
  bool _buildings3dAdded = false;

  final Map<String, Symbol> _symbols = {};
  final Map<String, MapMarkerData> _markers = {};
  final Map<String, Line> _lines = {};
  final Map<String, Fill> _fills = {};

  MarkerTapCallback? onMarkerTapped;
  MapTapCallback? onMapTapped;
  MapTapCallback? onMapLongPressed;

  /// Escape hatch for advanced MapLibre features (sources, custom layers, …).
  MapLibreMapController get raw => _map;

  OpenFreeMapStyle get style => _style;
  bool get is3dEnabled => _is3d;
  UnmodifiableMapView<String, MapMarkerData> get markers =>
      UnmodifiableMapView(_markers);

  // ── Style ──────────────────────────────────────────────────────────────

  Future<void> setStyle(OpenFreeMapStyle style) async {
    _style = style;
    _buildings3dAdded = false;
    _symbols.clear();
    _markers.clear();
    _lines.clear();
    _fills.clear();
    await _map.setStyle(style.url);
  }

  // ── Camera ─────────────────────────────────────────────────────────────

  /// Prefer tracked [MapLibreMapController.cameraPosition].
  ///
  /// Do **not** call [MapLibreMapController.queryCameraPosition] on web — it
  /// throws [UnimplementedError] there and used to break 3D mode.
  CameraPosition _currentCamera() {
    final tracked = _map.cameraPosition;
    if (tracked != null) {
      _fallbackCenter = tracked.target;
      return tracked;
    }
    return CameraPosition(target: _fallbackCenter, zoom: 13);
  }

  Future<void> flyTo(
    LatLng target, {
    double? zoom,
    double? bearing,
    double? tilt,
    Duration duration = const Duration(milliseconds: 900),
  }) async {
    final current = _currentCamera();
    _fallbackCenter = target;
    await _map.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom ?? current.zoom,
          bearing: bearing ?? current.bearing,
          tilt: tilt ?? (_is3d ? 55 : current.tilt),
        ),
      ),
      duration: duration,
    );
  }

  Future<void> zoomBy(double delta) async {
    await _map.animateCamera(CameraUpdate.zoomBy(delta));
  }

  Future<void> fitBounds(
    LatLngBounds bounds, {
    double padding = 48,
  }) async {
    await _map.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: padding,
        top: padding,
        right: padding,
        bottom: padding,
      ),
    );
  }

  // ── 3D mode ────────────────────────────────────────────────────────────

  /// Tilts the camera and ensures extruded buildings are visible.
  ///
  /// Liberty already includes `building-3d`. Other styles get a fill-extrusion
  /// layer from OpenFreeMap's planet tiles when 3D is turned on.
  ///
  /// Zoom ≥ 14 is required for OpenFreeMap building extrusions.
  Future<void> enable3d({
    double tilt = 55,
    double bearing = -20,
  }) async {
    try {
      await _ensure3dBuildings();
      final current = _currentCamera();
      final zoom = current.zoom < 14.5 ? 15.5 : current.zoom;
      await _map.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: current.target,
            zoom: zoom,
            bearing: bearing,
            tilt: tilt,
          ),
        ),
        duration: const Duration(milliseconds: 900),
      );
      // Extra nudge — some web builds ignore pitch inside combined flyTo.
      await _map.animateCamera(CameraUpdate.tiltTo(tilt));
      _is3d = true;
    } catch (e, st) {
      _is3d = false;
      debugPrint('enable3d failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> disable3d() async {
    try {
      final current = _currentCamera();
      await _map.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: current.target,
            zoom: current.zoom,
            bearing: 0,
            tilt: 0,
          ),
        ),
        duration: const Duration(milliseconds: 600),
      );
      await _map.animateCamera(CameraUpdate.tiltTo(0));
      _is3d = false;
    } catch (e, st) {
      debugPrint('disable3d failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> toggle3d() async {
    if (_is3d) {
      await disable3d();
    } else {
      await enable3d();
    }
  }

  Future<void> _ensure3dBuildings() async {
    if (_style.hasBuiltIn3dBuildings) {
      try {
        await _map.setLayerVisibility('building-3d', true);
      } catch (_) {
        // Layer name may differ after a custom style edit — ignore.
      }
      return;
    }

    if (_buildings3dAdded) return;

    try {
      await _map.addSource(
        'openfreemap-planet',
        const VectorSourceProperties(
          url: 'https://tiles.openfreemap.org/planet',
        ),
      );
    } catch (_) {
      // Source may already exist after a previous enable.
    }

    try {
      await _map.addFillExtrusionLayer(
        'openfreemap-planet',
        'team-map-3d-buildings',
        FillExtrusionLayerProperties(
          fillExtrusionColor: [
            'interpolate',
            ['linear'],
            ['get', 'render_height'],
            0,
            'lightgray',
            200,
            'royalblue',
            400,
            'lightblue',
          ],
          fillExtrusionHeight: [
            'interpolate',
            ['linear'],
            ['zoom'],
            15,
            0,
            16,
            ['get', 'render_height'],
          ],
          fillExtrusionBase: [
            'case',
            [
              '>=',
              ['zoom'],
              16,
            ],
            ['get', 'render_min_height'],
            0,
          ],
          fillExtrusionOpacity: 0.85,
        ),
        sourceLayer: 'building',
        minzoom: 15,
        filter: [
          '!=',
          ['get', 'hide_3d'],
          true,
        ],
      );
      _buildings3dAdded = true;
    } catch (e, st) {
      debugPrint('Could not add 3D buildings layer: $e\n$st');
    }
  }

  // ── Markers ────────────────────────────────────────────────────────────

  Future<void> addMarker(MapMarkerData marker) async {
    await removeMarker(marker.id);
    final symbol = await _map.addSymbol(
      SymbolOptions(
        geometry: marker.position,
        iconImage: marker.iconImage,
        iconSize: marker.iconSize,
        iconColor: marker.iconColor,
        textField: marker.title,
        textOffset: marker.title == null ? null : const Offset(0, 1.4),
        textSize: 12,
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.2,
      ),
      {
        'markerId': marker.id,
        ...?marker.data,
      },
    );
    _symbols[marker.id] = symbol;
    _markers[marker.id] = marker;
  }

  Future<void> addMarkers(Iterable<MapMarkerData> markers) async {
    for (final marker in markers) {
      await addMarker(marker);
    }
  }

  Future<void> removeMarker(String id) async {
    final symbol = _symbols.remove(id);
    _markers.remove(id);
    if (symbol != null) {
      await _map.removeSymbol(symbol);
    }
  }

  Future<void> clearMarkers() async {
    final ids = _markers.keys.toList();
    for (final id in ids) {
      await removeMarker(id);
    }
  }

  MapMarkerData? markerBySymbol(Symbol symbol) {
    for (final entry in _symbols.entries) {
      if (entry.value.id == symbol.id) {
        return _markers[entry.key];
      }
    }
    return null;
  }

  // ── Lines & polygons (routes, zones, …) ────────────────────────────────

  Future<String> addPolyline({
    required String id,
    required List<LatLng> points,
    String color = '#1565C0',
    double width = 4,
    double opacity = 0.9,
  }) async {
    await removePolyline(id);
    final line = await _map.addLine(
      LineOptions(
        geometry: points,
        lineColor: color,
        lineWidth: width,
        lineOpacity: opacity,
      ),
    );
    _lines[id] = line;
    return id;
  }

  Future<void> removePolyline(String id) async {
    final line = _lines.remove(id);
    if (line != null) {
      await _map.removeLine(line);
    }
  }

  Future<String> addPolygon({
    required String id,
    required List<LatLng> outline,
    String fillColor = '#43A047',
    double fillOpacity = 0.25,
    String strokeColor = '#2E7D32',
    double strokeWidth = 2,
  }) async {
    await removePolygon(id);
    final fill = await _map.addFill(
      FillOptions(
        geometry: [outline],
        fillColor: fillColor,
        fillOpacity: fillOpacity,
        fillOutlineColor: strokeColor,
      ),
    );
    _fills[id] = fill;
    // Outline width is style-driven; strokeWidth kept for teammate API clarity.
    assert(strokeWidth >= 0);
    return id;
  }

  Future<void> removePolygon(String id) async {
    final fill = _fills.remove(id);
    if (fill != null) {
      await _map.removeFill(fill);
    }
  }

  // ── Custom images for markers ──────────────────────────────────────────

  Future<void> addImage(String name, Uint8List bytes) async {
    await _map.addImage(name, bytes);
  }

  // ── Internal wiring from TeamMap ───────────────────────────────────────

  void bindStyle(OpenFreeMapStyle style, {required bool startIn3d}) {
    _style = style;
    _is3d = startIn3d;
  }

  Future<void> onStyleLoaded({required bool startIn3d}) async {
    // Web (MapLibre GL JS v5) may ignore initialCameraPosition when the style
    // JSON defines center/zoom — re-apply our fallback once.
    final tracked = _map.cameraPosition;
    if (tracked == null) {
      await _map.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _fallbackCenter, zoom: 13),
        ),
      );
    }

    if (startIn3d) {
      await enable3d();
    }
  }

  void handleSymbolTapped(Symbol symbol) {
    final marker = markerBySymbol(symbol);
    if (marker != null) {
      onMarkerTapped?.call(marker);
    }
  }
}
