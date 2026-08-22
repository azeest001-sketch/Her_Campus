import 'package:flutter/foundation.dart';
import 'package:team_map/map_kit/map_kit.dart';

import '../models/campus_place_model.dart';
import '../services/college_service.dart';

/// In-memory campus map customizations (border + places) for the mockup.
///
/// TODO(backend): persist per campus in Supabase.
class CampusMapEditorService extends ChangeNotifier {
  CampusMapEditorService._();
  static final CampusMapEditorService instance = CampusMapEditorService._();

  final List<LatLng> _borderPoints = [];
  final List<CampusPlaceModel> _places = [];
  var _borderClosed = false;
  var _studentMapConfirmed = false;
  var _studentSetupFinished = false;

  List<LatLng> get borderPoints => List.unmodifiable(_borderPoints);
  List<CampusPlaceModel> get places => List.unmodifiable(_places);
  bool get borderClosed => _borderClosed;
  bool get hasCustomBorder => _borderPoints.length >= 2;
  bool get hasClosedCustomBorder =>
      _borderClosed && _borderPoints.length >= 3;
  bool get studentMapConfirmed => _studentMapConfirmed;
  /// True after student taps Finish on the map screen.
  bool get studentSetupFinished => _studentSetupFinished;

  /// Auto-close a drawn border (≥3 points) and mark student map ready.
  void confirmStudentMap() {
    if (_borderPoints.length >= 3 && !_borderClosed) {
      _borderClosed = true;
    }
    _studentSetupFinished = true;
    _studentMapConfirmed = true;
    notifyListeners();
  }

  void finishStudentSetupWithoutBorder() {
    _studentSetupFinished = true;
    _studentMapConfirmed = true;
    notifyListeners();
  }

  void clearStudentMapConfirmation() {
    _studentMapConfirmed = false;
    _studentSetupFinished = false;
    notifyListeners();
  }

  /// Closed outline for drawing (custom border, else college OSM boundary).
  List<LatLng>? get activeBoundary {
    if (_borderPoints.length >= 3) {
      final ring = List<LatLng>.from(_borderPoints);
      if (_borderClosed) {
        final first = ring.first;
        final last = ring.last;
        if (first.latitude != last.latitude ||
            first.longitude != last.longitude) {
          ring.add(first);
        }
      }
      return ring;
    }
    final college = CollegeService.instance.selectedCollege;
    if (college != null && college.hasBoundary) return college.boundary;
    return null;
  }

  void clearBorder() {
    _borderPoints.clear();
    _borderClosed = false;
    notifyListeners();
  }

  void addBorderVertex(LatLng point) {
    if (_borderClosed) return;
    _borderPoints.add(point);
    notifyListeners();
  }

  void undoBorderVertex() {
    if (_borderPoints.isEmpty) return;
    _borderPoints.removeLast();
    _borderClosed = false;
    notifyListeners();
  }

  void closeBorder() {
    if (_borderPoints.length < 3) return;
    _borderClosed = true;
    notifyListeners();
  }

  void addPlace(CampusPlaceModel place) {
    _places.removeWhere((item) => item.id == place.id);
    _places.insert(0, place);
    notifyListeners();
  }

  void renamePlace(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final index = _places.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _places[index] = _places[index].copyWith(name: trimmed);
    notifyListeners();
  }

  /// Next default label for a category, e.g. "Canteen 2".
  String nextDefaultName(String category) {
    final count = _places.where((item) => item.category == category).length;
    return count == 0 ? category : '$category ${count + 1}';
  }

  void removePlace(String id) {
    _places.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
