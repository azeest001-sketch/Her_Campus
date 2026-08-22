import 'package:team_map/map_kit/map_kit.dart';

/// A labelled place on the campus map (canteen, library, …).
class CampusPlaceModel {
  const CampusPlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    this.fromGps = false,
  });

  final String id;
  final String name;
  final String category;
  final LatLng position;

  /// True when the admin dropped this pin from device GPS.
  final bool fromGps;

  CampusPlaceModel copyWith({String? name, String? category}) {
    return CampusPlaceModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      position: position,
      fromGps: fromGps,
    );
  }
}
