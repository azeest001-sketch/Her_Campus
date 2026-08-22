import 'package:flutter/foundation.dart';

import '../models/escort_model.dart';
import 'student_onboarding_service.dart';

/// Mock peer-escort volunteers + student requests.
///
/// TODO(backend): persist volunteers, fan-out push/email to first receivers.
class EscortService extends ChangeNotifier {
  EscortService._();
  static final EscortService instance = EscortService._();

  final List<EscortVolunteerModel> _volunteers = [];
  final List<EscortRequestModel> _requests = [];

  List<EscortVolunteerModel> get volunteers => List.unmodifiable(_volunteers);
  List<EscortRequestModel> get requests => List.unmodifiable(_requests);

  int get pendingCount =>
      _requests.where((r) => r.status == EscortRequestStatus.pending).length;

  Future<void> addVolunteerEmail(String email) async {
    // TODO(backend): save volunteer allowlist for campus.
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) return;
    if (_volunteers.any((v) => v.email == normalized)) return;

    _volunteers.add(
      EscortVolunteerModel(
        email: normalized,
        displayName: StudentOnboardingService.displayNameFromEmail(normalized),
      ),
    );
    notifyListeners();
  }

  Future<void> removeVolunteer(String email) async {
    _volunteers.removeWhere((v) => v.email == email.toLowerCase());
    notifyListeners();
  }

  Future<EscortRequestModel> requestEscort({
    required String studentEmail,
    required String destination,
    String note = '',
  }) async {
    // TODO(backend): create request and notify volunteer emails first.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final request = EscortRequestModel(
      id: 'e-${DateTime.now().millisecondsSinceEpoch}',
      studentEmail: studentEmail.trim().toLowerCase(),
      destination: destination.trim(),
      note: note.trim(),
      createdAt: DateTime.now(),
      assignedVolunteerEmail:
          _volunteers.isNotEmpty ? _volunteers.first.email : null,
    );
    _requests.insert(0, request);
    notifyListeners();
    return request;
  }

  Future<void> setRequestStatus(
    String id,
    EscortRequestStatus status,
  ) async {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index < 0) return;
    _requests[index] = _requests[index].copyWith(status: status);
    notifyListeners();
  }
}
