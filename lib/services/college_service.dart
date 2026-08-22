import '../models/college_model.dart';
import 'profile_service.dart';

/// Temporary in-memory college selection for the frontend mockup.
///
/// Also syncs [campus_name] onto the logged-in Supabase profile when set.
class CollegeService {
  CollegeService._();
  static final CollegeService instance = CollegeService._();

  CollegeModel? _selectedCollege;

  CollegeModel? get selectedCollege => _selectedCollege;

  Future<void> saveCollege(CollegeModel college) async {
    _selectedCollege = college;
    await ProfileService.instance.setCampusName(college.name);
  }

  Future<CollegeModel?> loadCollege() async {
    return _selectedCollege;
  }
}
