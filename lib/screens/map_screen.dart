import 'package:flutter/material.dart';
import 'package:team_map/map_kit/map_kit.dart';

import '../services/campus_map_editor_service.dart';
import '../services/college_service.dart';

/// Shared campus map centered on the college selected by an administrator.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final college = CollegeService.instance.selectedCollege;
    final editor = CampusMapEditorService.instance;

    if (college == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The campus map will appear after an administrator selects a college.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          college.name.split(',').first,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: TeamMap(
        config: MapConfig(
          initialCenter: college.position,
          initialZoom: 17.5,
          enable3dOnStart: true,
          myLocationEnabled: true,
        ),
        onReady: (controller) async {
          await controller.flyTo(college.position, zoom: 17.5);
          await controller.addMarker(
            MapMarkerData(
              id: 'campus',
              position: college.position,
              title: college.name.split(',').first,
              iconColor: '#2563EB',
            ),
          );

          final boundary = editor.activeBoundary;
          if (boundary != null && boundary.length >= 3) {
            await controller.showCampusBoundary(outline: boundary);
          }

          for (final place in editor.places) {
            await controller.addMarker(
              MapMarkerData(
                id: place.id,
                position: place.position,
                title: place.name,
                snippet: place.category,
                iconColor: place.fromGps ? '#0F766E' : '#7C3AED',
              ),
            );
          }
        },
      ),
    );
  }
}
