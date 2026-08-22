import 'package:flutter/foundation.dart';

import '../models/floor_calibration_model.dart';

/// In-memory floor calibration mock for admin demos.
///
/// TODO(backend): persist buildings + pressure references in Supabase.
class FloorCalibrationService extends ChangeNotifier {
  FloorCalibrationService._() {
    _seedDemo();
  }

  static final FloorCalibrationService instance = FloorCalibrationService._();

  final List<BuildingCalibrationModel> _buildings = [];

  List<BuildingCalibrationModel> get buildings =>
      List.unmodifiable(_buildings);

  int get readyBuildingCount =>
      _buildings.where((b) => b.isReady).length;

  void _seedDemo() {
    _buildings.add(
      BuildingCalibrationModel(
        id: 'bldg-library',
        name: 'Main Library',
        floors: [
          FloorLevelModel(
            id: 'fl-lib-0',
            label: 'Ground',
            levelIndex: 0,
            pressureHpa: 1012.4,
            calibratedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          const FloorLevelModel(
            id: 'fl-lib-1',
            label: 'Floor 1',
            levelIndex: 1,
          ),
          const FloorLevelModel(
            id: 'fl-lib-2',
            label: 'Floor 2',
            levelIndex: 2,
          ),
        ],
      ),
    );
  }

  void addBuilding(String name, {int floorCount = 3}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final id = 'bldg-${DateTime.now().millisecondsSinceEpoch}';
    final floors = <FloorLevelModel>[
      for (var i = 0; i < floorCount; i++)
        FloorLevelModel(
          id: '$id-fl-$i',
          label: i == 0 ? 'Ground' : 'Floor $i',
          levelIndex: i,
        ),
    ];

    _buildings.insert(
      0,
      BuildingCalibrationModel(id: id, name: trimmed, floors: floors),
    );
    notifyListeners();
  }

  void removeBuilding(String buildingId) {
    _buildings.removeWhere((b) => b.id == buildingId);
    notifyListeners();
  }

  void addFloor(String buildingId, String label) {
    final index = _buildings.indexWhere((b) => b.id == buildingId);
    if (index < 0) return;

    final building = _buildings[index];
    final nextLevel = building.floors.isEmpty
        ? 0
        : building.floors.map((f) => f.levelIndex).reduce((a, b) => a > b ? a : b) +
            1;

    final floors = [
      ...building.floors,
      FloorLevelModel(
        id: '$buildingId-fl-${DateTime.now().millisecondsSinceEpoch}',
        label: label.trim().isEmpty
            ? (nextLevel == 0 ? 'Ground' : 'Floor $nextLevel')
            : label.trim(),
        levelIndex: nextLevel,
      ),
    ];

    _buildings[index] = building.copyWith(floors: floors);
    notifyListeners();
  }

  void removeFloor(String buildingId, String floorId) {
    final index = _buildings.indexWhere((b) => b.id == buildingId);
    if (index < 0) return;
    final building = _buildings[index];
    _buildings[index] = building.copyWith(
      floors: building.floors.where((f) => f.id != floorId).toList(),
    );
    notifyListeners();
  }

  /// Mock "stand on this floor and capture pressure".
  Future<void> calibrateFloor(String buildingId, String floorId) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final index = _buildings.indexWhere((b) => b.id == buildingId);
    if (index < 0) return;
    final building = _buildings[index];
    final floor = building.floors.firstWhere(
      (f) => f.id == floorId,
      orElse: () => throw StateError('Floor not found'),
    );

    // Fake pressure: ~1013 hPa at ground, ~0.35 hPa drop per floor.
    final mockPressure = 1013.0 - (floor.levelIndex * 0.35);

    final floors = building.floors
        .map(
          (f) => f.id == floorId
              ? f.copyWith(
                  pressureHpa: mockPressure,
                  calibratedAt: DateTime.now(),
                )
              : f,
        )
        .toList();

    _buildings[index] = building.copyWith(floors: floors);
    notifyListeners();
  }

  void clearFloorCalibration(String buildingId, String floorId) {
    final index = _buildings.indexWhere((b) => b.id == buildingId);
    if (index < 0) return;
    final building = _buildings[index];
    final floors = building.floors
        .map((f) => f.id == floorId ? f.copyWith(clearPressure: true) : f)
        .toList();
    _buildings[index] = building.copyWith(floors: floors);
    notifyListeners();
  }
}
