import '../models/college_model.dart';

/// Temporary in-memory college selection for the frontend mockup.
///
/// Backend teammate: replace [saveCollege] and [loadCollege] with Supabase/API
/// persistence associated with the administrator's campus.
class CollegeService {
  CollegeService._();
  static final CollegeService instance = CollegeService._();

  CollegeModel? _selectedCollege;

  CollegeModel? get selectedCollege => _selectedCollege;

  Future<void> saveCollege(CollegeModel college) async {
    // TODO(backend): persist college name + latitude/longitude for the campus.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _selectedCollege = college;
  }

  Future<CollegeModel?> loadCollege() async {
    // TODO(backend): load the campus selected by an administrator.
    return _selectedCollege;
  }
}
