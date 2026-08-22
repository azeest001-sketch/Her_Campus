import 'package:team_map/map_kit/map_kit.dart';

/// College selected by an administrator as the campus map center.
class CollegeModel {
  const CollegeModel({
    required this.name,
    required this.position,
    this.boundary,
  });

  final String name;
  final LatLng position;

  /// Natural campus outline from OpenStreetMap when available.
  /// Null means OSM has no campus-sized polygon for this place.
  final List<LatLng>? boundary;

  bool get hasBoundary => boundary != null && boundary!.length >= 4;
}
