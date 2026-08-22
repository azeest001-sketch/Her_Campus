import 'dart:collection';
import 'dart:math' show Point;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    double fallbackZoom = 12,
  }) {
    _fallbackCenter = fallbackCenter;
    _fallbackZoom = fallbackZoom;
  }

  final MapLibreMapController _map;
  late LatLng _fallbackCenter;
  late double _fallbackZoom;

  OpenFreeMapStyle _style = OpenFreeMapStyle.liberty;
  bool _is3d = false;
  bool _buildings3dAdded = false;
  var _symbolOverlapReady = false;

  final Map<String, Symbol> _symbols = {};
  final Map<String, Circle> _circles = {};
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
    _symbolOverlapReady = false;
    resetAnnotationCache();
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
    return CameraPosition(target: _fallbackCenter, zoom: _fallbackZoom);
  }

  /// Current map center (camera target). Safe for drop-pin / draw tools.
  LatLng get cameraCenter => _currentCamera().target;

  /// Convert a local map-widget pixel to lat/lng.
  Future<LatLng> toLatLng(Offset localOffset) {
    return _map.toLatLng(Point(localOffset.dx, localOffset.dy));
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
    Duration duration = const Duration(milliseconds: 900),
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
        duration: duration,
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

  /// Drops a pin with its name drawn *into the image*.
  ///
  /// MapLibre symbol text uses Open Sans / Arial Unicode, which OpenFreeMap
  /// does not ship — so a `textField` label is silently blank. Circles draw a
  /// dot but cannot carry text. Baking the name into a PNG and using that as
  /// `icon-image` is the one path that actually shows "Library" on the map.
  Future<void> addMarker(MapMarkerData marker) async {
    await removeMarker(marker.id);

    final imageId = 'team_pin_${marker.id}';
    final bytes = await paintMarkerPinPng(
      title: marker.title,
      fillHex: marker.iconColor ?? '#2563EB',
      iconSize: marker.iconSize,
    );
    await _map.addImage(imageId, bytes);

    final symbol = await _map.addSymbol(
      SymbolOptions(
        geometry: marker.position,
        iconImage: imageId,
        iconSize: 1,
        iconAnchor: 'top',
      ),
      {
        'markerId': marker.id,
        ...?marker.data,
      },
    );
    _symbols[marker.id] = symbol;
    _markers[marker.id] = marker;

    await _ensureSymbolOverlap();
  }

  Future<void> _ensureSymbolOverlap() async {
    if (_symbolOverlapReady) return;
    _symbolOverlapReady = true;
    try {
      await _map.setSymbolIconAllowOverlap(true);
      await _map.setSymbolIconIgnorePlacement(true);
      await _map.setSymbolTextAllowOverlap(true);
      await _map.setSymbolTextIgnorePlacement(true);
    } catch (error) {
      debugPrint('Symbol overlap flags skipped: $error');
    }
  }

  /// Forgets cached annotation handles.
  ///
  /// MapLibre destroys every annotation when the style reloads or the platform
  /// view is recreated, so the cached handles are dangling at that point and
  /// removing them would throw.
  void resetAnnotationCache() {
    _symbols.clear();
    _circles.clear();
    _markers.clear();
    _lines.clear();
    _fills.clear();
    _symbolOverlapReady = false;
  }

  Future<void> addMarkers(Iterable<MapMarkerData> markers) async {
    for (final marker in markers) {
      await addMarker(marker);
    }
  }

  Future<void> removeMarker(String id) async {
    final symbol = _symbols.remove(id);
    final circle = _circles.remove(id);
    _markers.remove(id);

    // Handles go stale after a style reload; the cache entries are already
    // dropped above, so a failure here is safe to ignore.
    if (circle != null) {
      try {
        await _map.removeCircle(circle);
      } catch (error) {
        debugPrint('removeMarker($id) circle ignored: $error');
      }
    }
    if (symbol != null) {
      try {
        await _map.removeSymbol(symbol);
      } catch (error) {
        debugPrint('removeMarker($id) label ignored: $error');
      }
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

  /// Soft fill + bold outline so campus edges are easy to see.
  Future<void> showCampusBoundary({
    required List<LatLng> outline,
    String id = 'campus_boundary',
    String fillColor = '#3B82F6',
    double fillOpacity = 0.14,
    String strokeColor = '#1D4ED8',
    double strokeWidth = 3.5,
  }) async {
    if (outline.length < 3) return;
    await addPolygon(
      id: id,
      outline: outline,
      fillColor: fillColor,
      fillOpacity: fillOpacity,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
    await addPolyline(
      id: '${id}_stroke',
      points: outline,
      color: strokeColor,
      width: strokeWidth,
      opacity: 0.95,
    );
  }

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
    if (line == null) return;
    try {
      await _map.removeLine(line);
    } catch (error) {
      debugPrint('removePolyline($id) ignored: $error');
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
    if (fill == null) return;
    try {
      await _map.removeFill(fill);
    } catch (error) {
      debugPrint('removePolygon($id) ignored: $error');
    }
  }

  // ── Custom images for markers ──────────────────────────────────────────

  Future<void> addImage(String name, Uint8List bytes) async {
    await _map.addImage(name, bytes);
  }

  /// Hides OpenFreeMap place / POI names (e.g. the college title printed
  /// by the base map) so only admin-placed labels remain.
  Future<void> hideBasemapPlaceLabels() async {
    const layerIds = [
      'poi_r20',
      'poi_r7',
      'poi_r1',
      'poi_transit',
      'label_other',
      'label_village',
      'label_town',
    ];
    for (final id in layerIds) {
      try {
        await _map.setLayerVisibility(id, false);
      } catch (error) {
        debugPrint('hideBasemapPlaceLabels($id) skipped: $error');
      }
    }
  }

  // ── Internal wiring from TeamMap ───────────────────────────────────────

  void bindStyle(OpenFreeMapStyle style, {required bool startIn3d}) {
    _style = style;
    _is3d = startIn3d;
  }

  Future<void> onStyleLoaded({required bool startIn3d}) async {
    // A style (re)load destroys every annotation, so previously cached handles
    // are dangling. Callers repaint from their own state after this.
    resetAnnotationCache();
    _buildings3dAdded = false;

    // Web (MapLibre GL JS v5) may ignore initialCameraPosition when the style
    // JSON defines center/zoom — re-apply our fallback once.
    await _map.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _fallbackCenter,
          zoom: _fallbackZoom,
        ),
      ),
    );

    if (startIn3d) {
      await enable3d();
    }
  }

  void handleSymbolTapped(Symbol symbol) {
    final marker = markerBySymbol(symbol);
    if (marker != null) {
      onMarkerTapped?.call(marker);
      // Markers used to swallow map clicks; still report a map tap so drawing
      // / labeling keep working when the user taps near an existing pin.
      onMapTapped?.call(marker.position);
    }
  }
}

/// Raster pins are drawn at 3× so they stay sharp on phone screens.
const kMarkerPinPixelRatio = 3.0;

Color _colorFromHex(String hex) {
  var value = hex.replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}

/// Coloured dot + name chip, as PNG bytes. Used as a MapLibre `icon-image`
/// so the label does not depend on the style's glyph fonts.
Future<Uint8List> paintMarkerPinPng({
  required String? title,
  required String fillHex,
  required double iconSize,
}) async {
  final radius = 8.0 * iconSize;
  final titleText = title?.trim();
  final hasTitle = titleText != null && titleText.isNotEmpty;

  TextPainter? textPainter;
  if (hasTitle) {
    textPainter = TextPainter(
      text: TextSpan(
        text: titleText,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF14293A),
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: 280);
  }

  const chipPadH = 10.0;
  const chipPadV = 6.0;
  final chipW = hasTitle ? textPainter!.width + chipPadH * 2 : 0.0;
  final chipH = hasTitle ? textPainter!.height + chipPadV * 2 : 0.0;
  const gap = 5.0;
  final dotExtent = radius * 2 + 6;
  final logicalW = hasTitle && chipW > dotExtent ? chipW : dotExtent;
  final logicalH = dotExtent + (hasTitle ? gap + chipH : 0);

  final widthPx = (logicalW * kMarkerPinPixelRatio).ceil();
  final heightPx = (logicalH * kMarkerPinPixelRatio).ceil();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(kMarkerPinPixelRatio);

  final fill = _colorFromHex(fillHex);
  final cx = logicalW / 2;
  final cy = radius + 3;

  canvas.drawCircle(
    Offset(cx, cy),
    radius + 2.4,
    Paint()..color = Colors.white,
  );
  canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = fill);

  if (hasTitle && textPainter != null) {
    final chipTop = dotExtent + gap;
    final chipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, chipTop + chipH / 2),
        width: chipW,
        height: chipH,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(chipRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      chipRect,
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, chipTop + chipPadV),
    );
  }

  final image = await recorder.endRecording().toImage(widthPx, heightPx);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
