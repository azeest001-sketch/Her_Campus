import 'package:flutter/foundation.dart';

import '../models/report_model.dart';

/// Mock report inbox shared by students (submit) and admins (read).
///
/// TODO(backend): store reports in Supabase; notify admins.
class ReportService extends ChangeNotifier {
  ReportService._();
  static final ReportService instance = ReportService._();

  final List<ReportModel> _reports = [];

  List<ReportModel> get reports => List.unmodifiable(_reports);

  int get newCount =>
      _reports.where((r) => r.status == ReportStatus.newReport).length;

  Future<void> submitReport({
    required String title,
    required String description,
    required String reporterEmail,
    String? locationLabel,
  }) async {
    // TODO(backend): insert row + push/email admin.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _reports.insert(
      0,
      ReportModel(
        id: 'r-${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
        description: description.trim(),
        reporterEmail: reporterEmail.trim().toLowerCase(),
        locationLabel: locationLabel?.trim(),
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> setStatus(String id, ReportStatus status) async {
    // TODO(backend): update report status.
    final index = _reports.indexWhere((r) => r.id == id);
    if (index < 0) return;
    _reports[index] = _reports[index].copyWith(status: status);
    notifyListeners();
  }
}
