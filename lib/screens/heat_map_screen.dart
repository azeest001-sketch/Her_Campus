import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_map/map_kit/map_kit.dart';

import '../services/campus_geofence.dart';
import '../services/campus_map_editor_service.dart';
import '../services/college_service.dart';
import '../services/heatwave/heatwave_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/heat_map_overlay.dart';
import 'college_setup_screen.dart';
import 'customisable_map_screen.dart';

/// Student Heatwave Map: campus boundary + live GPS + colour crowd circles.
class HeatMapScreen extends StatefulWidget {
  const HeatMapScreen({super.key});

  @override
  State<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends State<HeatMapScreen> {
  final _editor = CampusMapEditorService.instance;
  final _controller = HeatwaveController();

  TeamMapController? _map;
  var _painting = false;
  var _repaintQueued = false;
  var _is3d = false;
  var _toggling3d = false;
  var _locationReady = false;
  var _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _editor.addListener(_onCampusChanged);
    _controller.addListener(_onHeatChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _editor.removeListener(_onCampusChanged);
    _controller.removeListener(_onHeatChanged);
    _controller.stop();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (CollegeService.instance.selectedCollege == null) {
      if (mounted) setState(() => _bootstrapping = false);
      return;
    }
    if (mounted) setState(() => _bootstrapping = true);
    final ok = await _controller.ensurePermissions();
    if (!mounted) return;
    setState(() {
      _locationReady = ok;
      _bootstrapping = false;
    });
    if (ok) {
      await _controller.start();
    }
  }

  void _onCampusChanged() {
    _paintMap();
    if (mounted) setState(() {});
  }

  void _onHeatChanged() {
    _paintHeatCircles();
    if (mounted) setState(() {});
  }

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (error) {
      debugPrint('HeatMap draw step skipped: $error');
    }
  }

  Future<void> _paintMap() async {
    if (_map == null) return;
    if (_painting) {
      _repaintQueued = true;
      return;
    }
    _painting = true;
    try {
      do {
        _repaintQueued = false;
        await _drawCampus();
        await _paintHeatCircles();
      } while (_repaintQueued && mounted && _map != null);
    } finally {
      _painting = false;
    }
  }

  Future<void> _drawCampus() async {
    final map = _map;
    if (map == null) return;

    await _guard(map.clearMarkers);
    await _guard(() => map.removePolygon('campus_boundary'));
    await _guard(() => map.removePolyline('campus_boundary_stroke'));
    await _guard(() => map.removePolygon('custom_border'));
    await _guard(() => map.removePolyline('custom_border'));
    await _guard(() => map.removePolyline('custom_border_stroke'));

    final college = CollegeService.instance.selectedCollege;

    for (final place in _editor.places) {
      if (place.name.trim().isEmpty) continue;
      await _guard(
        () => map.addMarker(
          MapMarkerData(
            id: place.id,
            position: place.position,
            title: place.name,
            snippet: place.category,
            iconColor: '#DB2777',
            iconSize: 1.5,
          ),
        ),
      );
    }

    // Same automatic OSM outline shown during college / map selection.
    if (college != null &&
        college.hasBoundary &&
        college.boundary!.length >= 3) {
      await _guard(
        () => map.showCampusBoundary(
          outline: college.boundary!,
          fillOpacity: 0.08,
          strokeWidth: 2.4,
        ),
      );
    }

    final custom = _editor.borderPoints;
    if (custom.length >= 2) {
      final points = List<LatLng>.from(custom);
      final closed = _editor.borderClosed && points.length >= 3;
      if (closed) points.add(points.first);
      if (closed) {
        await _guard(
          () => map.showCampusBoundary(
            id: 'custom_border',
            outline: points,
            fillColor: '#EC4899',
            fillOpacity: 0.12,
            strokeColor: '#BE185D',
            strokeWidth: 3.2,
          ),
        );
      } else {
        await _guard(
          () => map.addPolyline(
            id: 'custom_border',
            points: points,
            color: '#BE185D',
            width: 3.2,
          ),
        );
      }
    }
  }

  Future<void> _paintHeatCircles() async {
    final map = _map;
    if (map == null) return;

    await _guard(() => map.clearHeatCircles());

    for (final hotspot in _controller.hotspots) {
      if (!hotspot.live && hotspot.approxCount <= 0) continue;
      final pos = LatLng(hotspot.latitude, hotspot.longitude);
      if (!CampusGeofence.contains(pos)) continue;

      await _guard(
        () => map.addHeatCircle(
          id: 'heat_${hotspot.id}',
          position: pos,
          colorHex: HeatwaveController.heatColorHex(hotspot.approxCount),
          radius: HeatwaveController.heatRadius(hotspot.approxCount),
          opacity: hotspot.live ? 0.55 : 0.28,
        ),
      );
    }
  }

  Future<void> _toggle3d() async {
    final map = _map;
    if (map == null || _toggling3d) return;
    setState(() => _toggling3d = true);
    try {
      if (_is3d) {
        await map.disable3d();
        _is3d = false;
      } else {
        await map.enable3d();
        _is3d = true;
      }
    } catch (e) {
      debugPrint('3D toggle failed: $e');
    } finally {
      if (mounted) setState(() => _toggling3d = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final college = CollegeService.instance.selectedCollege;

    if (college == null || !CampusGeofence.hasCampusMapReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Heatwave Map')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  college == null
                      ? 'Select your college first, then open Heatwave Map again.'
                      : 'Campus map is not ready yet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(color: AppTheme.inkMuted),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => college == null
                            ? const CollegeSetupScreen(forStudent: true)
                            : const CustomisableMapScreen(confirmMode: true),
                      ),
                    );
                  },
                  child: Text(college == null ? 'Select college' : 'Edit campus map'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_bootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_locationReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Heatwave Map')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, size: 48, color: Colors.orange),
                const SizedBox(height: 12),
                Text(
                  _controller.statusMessage ??
                      'Location must be ON for Heatwave Map on your phone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _bootstrap,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          TeamMap(
            config: MapConfig(
              initialCenter: college.position,
              initialZoom: 18,
              myLocationEnabled: true,
              enable3dOnStart: false,
            ),
            onReady: (controller) async {
              _map = controller;
              await _guard(() => controller.flyTo(college.position, zoom: 18));
              await _guard(controller.hideBasemapPlaceLabels);
              await _paintMap();
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                            iconSize: 20,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Heatwave Map',
                                  style: GoogleFonts.figtree(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.ink,
                                  ),
                                ),
                                Text(
                                  _controller.statusMessage ??
                                      'Live campus crowd sensing',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.figtree(
                                    fontSize: 11,
                                    color: AppTheme.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_controller.scanning)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          IconButton(
                            tooltip: _is3d ? '2D map' : '3D map',
                            onPressed: _toggling3d ? null : _toggle3d,
                            icon: Icon(
                              _is3d ? Icons.view_in_ar : Icons.threed_rotation,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const HeatMapLegend(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _controller.onCampus
                          ? Icons.my_location
                          : Icons.location_off_outlined,
                      color: _controller.onCampus
                          ? AppTheme.pinkSoft
                          : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _controller.onCampus
                            ? 'On campus — colours show how busy it is nearby'
                            : (_controller.statusMessage ??
                                'Enable location and stay inside campus border'),
                        style: GoogleFonts.figtree(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
