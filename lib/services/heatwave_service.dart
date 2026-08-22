import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:team_map/map_kit/map_kit.dart';

import '../models/crowd_data_model.dart';
import 'campus_map_editor_service.dart';
import 'college_service.dart';

/// Mock crowd heatwave data for the admin demo.
///
/// TODO(backend): replace with live Wi‑Fi / Bluetooth / check-in density.
class HeatwaveService extends ChangeNotifier {
  HeatwaveService._();
  static final HeatwaveService instance = HeatwaveService._();

  final _rng = Random();
  List<CrowdHotspotModel> _hotspots = [];
  var _lastRefreshed = DateTime.now();
  var _autoDemo = true;

  List<CrowdHotspotModel> get hotspots => List.unmodifiable(_hotspots);
  DateTime get lastRefreshed => _lastRefreshed;
  bool get autoDemo => _autoDemo;

  int get packedCount =>
      _hotspots.where((h) => h.intensity == CrowdIntensity.packed).length;

  void setAutoDemo(bool value) {
    _autoDemo = value;
    notifyListeners();
  }

  /// Builds mock hotspots on custom campus places when they exist.
  void ensureSeeded() {
    if (_hotspots.isNotEmpty) return;
    refreshMockData();
  }

  void refreshMockData() {
    final namedPlaces = CampusMapEditorService.instance.places
        .where((place) => place.name.trim().isNotEmpty)
        .toList();

    if (namedPlaces.isNotEmpty) {
      _hotspots = [
        for (var i = 0; i < namedPlaces.length; i++)
          _rollIntensity(
            id: 'heat-${namedPlaces[i].id}',
            label: namedPlaces[i].name,
            position: namedPlaces[i].position,
          ),
      ];
    } else {
      final college = CollegeService.instance.selectedCollege;
      final center = college?.position ?? const LatLng(12.9716, 77.5946);
      const labels = [
        'Main Gate',
        'Canteen',
        'Library lawn',
        'Hostel block',
        'Sports ground',
        'Admin plaza',
        'Parking lot',
        'Auditorium',
      ];
      _hotspots = [
        for (var i = 0; i < labels.length; i++)
          _rollIntensity(
            id: 'heat-$i',
            label: labels[i],
            position: LatLng(
              center.latitude +
                  ((i % 4) - 1.5) * 0.00055 +
                  (_rng.nextDouble() - 0.5) * 0.0002,
              center.longitude +
                  ((i ~/ 4) - 0.5) * 0.0007 +
                  (_rng.nextDouble() - 0.5) * 0.00025,
            ),
          ),
      ];
    }

    _lastRefreshed = DateTime.now();
    notifyListeners();
  }

  CrowdHotspotModel _rollIntensity({
    required String id,
    required String label,
    required LatLng position,
  }) {
    final roll = _rng.nextDouble();
    final CrowdIntensity intensity;
    final int people;
    if (roll > 0.82) {
      intensity = CrowdIntensity.packed;
      people = 120 + _rng.nextInt(80);
    } else if (roll > 0.55) {
      intensity = CrowdIntensity.busy;
      people = 60 + _rng.nextInt(50);
    } else if (roll > 0.28) {
      intensity = CrowdIntensity.moderate;
      people = 25 + _rng.nextInt(30);
    } else {
      intensity = CrowdIntensity.calm;
      people = 5 + _rng.nextInt(18);
    }

    return CrowdHotspotModel(
      id: id,
      label: label,
      position: position,
      intensity: intensity,
      peopleEstimate: people,
      updatedAt: DateTime.now(),
    );
  }
}
