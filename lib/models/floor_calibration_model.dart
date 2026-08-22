/// One floor inside a campus building, with optional barometer reference.
class FloorLevelModel {
  const FloorLevelModel({
    required this.id,
    required this.label,
    required this.levelIndex,
    this.pressureHpa,
    this.calibratedAt,
  });

  final String id;
  final String label;
  final int levelIndex;
  final double? pressureHpa;
  final DateTime? calibratedAt;

  bool get isCalibrated => pressureHpa != null;

  FloorLevelModel copyWith({
    String? label,
    int? levelIndex,
    double? pressureHpa,
    DateTime? calibratedAt,
    bool clearPressure = false,
  }) {
    return FloorLevelModel(
      id: id,
      label: label ?? this.label,
      levelIndex: levelIndex ?? this.levelIndex,
      pressureHpa: clearPressure ? null : (pressureHpa ?? this.pressureHpa),
      calibratedAt: clearPressure ? null : (calibratedAt ?? this.calibratedAt),
    );
  }
}

/// Building that needs indoor floor detection.
class BuildingCalibrationModel {
  const BuildingCalibrationModel({
    required this.id,
    required this.name,
    required this.floors,
  });

  final String id;
  final String name;
  final List<FloorLevelModel> floors;

  int get calibratedCount => floors.where((f) => f.isCalibrated).length;

  bool get isReady =>
      floors.length >= 2 && calibratedCount == floors.length;

  BuildingCalibrationModel copyWith({
    String? name,
    List<FloorLevelModel>? floors,
  }) {
    return BuildingCalibrationModel(
      id: id,
      name: name ?? this.name,
      floors: floors ?? this.floors,
    );
  }
}
