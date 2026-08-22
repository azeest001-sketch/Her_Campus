import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_map/map_kit/map_kit.dart';

import '../services/campus_map_editor_service.dart';
import '../services/college_service.dart';
import '../theme/app_theme.dart';

/// Admin view of the customised campus. Heat overlay will be added later.
class HeatwaveMapScreen extends StatefulWidget {
  const HeatwaveMapScreen({super.key});

  @override
  State<HeatwaveMapScreen> createState() => _HeatwaveMapScreenState();
}

class _HeatwaveMapScreenState extends State<HeatwaveMapScreen> {
  final _editor = CampusMapEditorService.instance;
  TeamMapController? _map;
  var _painting = false;
  var _repaintQueued = false;

  @override
  void initState() {
    super.initState();
    _editor.addListener(_onCampusChanged);
  }

  @override
  void dispose() {
    _editor.removeListener(_onCampusChanged);
    super.dispose();
  }

  void _onCampusChanged() {
    _paintMap();
    if (mounted) setState(() {});
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
        await _drawOnce();
      } while (_repaintQueued && mounted && _map != null);
    } finally {
      _painting = false;
    }
  }

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (error) {
      debugPrint('Heatwave map draw step skipped: $error');
    }
  }

  Future<void> _drawOnce() async {
    final map = _map;
    if (map == null) return;

    await _guard(map.clearMarkers);
    await _guard(() => map.removePolygon('campus_boundary'));
    await _guard(() => map.removePolyline('campus_boundary_stroke'));
    await _guard(() => map.removePolygon('custom_border'));
    await _guard(() => map.removePolyline('custom_border'));
    await _guard(() => map.removePolyline('custom_border_stroke'));

    final college = CollegeService.instance.selectedCollege;
    final custom = _editor.borderPoints;

    for (final place in _editor.places) {
      if (place.name.trim().isEmpty) continue;
      await _guard(
        () => map.addMarker(
          MapMarkerData(
            id: place.id,
            position: place.position,
            title: place.name,
            snippet: place.category,
            iconColor: '#7C3AED',
            iconSize: 1.6,
          ),
        ),
      );
    }

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

    if (custom.length >= 2) {
      final points = List<LatLng>.from(custom);
      final closed = _editor.borderClosed && points.length >= 3;
      if (closed) points.add(points.first);
      if (closed) {
        await _guard(
          () => map.showCampusBoundary(
            id: 'custom_border',
            outline: points,
            fillColor: '#2563EB',
            fillOpacity: 0.12,
            strokeColor: '#1D4ED8',
            strokeWidth: 3.2,
          ),
        );
      } else {
        await _guard(
          () => map.addPolyline(
            id: 'custom_border',
            points: points,
            color: '#1D4ED8',
            width: 3.2,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final college = CollegeService.instance.selectedCollege;

    if (college == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Heatwave Map')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Select a college first to view the campus map.',
              textAlign: TextAlign.center,
              style: GoogleFonts.figtree(color: AppTheme.adminInkMuted),
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
              myLocationEnabled: false,
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
                child: Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
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
                                color: AppTheme.adminInk,
                              ),
                            ),
                            Text(
                              'Your customised campus',
                              style: GoogleFonts.figtree(
                                fontSize: 11,
                                color: AppTheme.adminInkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
