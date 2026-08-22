import 'package:flutter/foundation.dart';

import '../models/escort_model.dart';
import 'college_service.dart';
import 'profile_service.dart';
import 'supabase_service.dart';

/// Peer-escort volunteers + student requests (Supabase).
class EscortService extends ChangeNotifier {
  EscortService._();
  static final EscortService instance = EscortService._();

  final _supabase = SupabaseService.instance;

  final List<EscortVolunteerModel> _volunteers = [];
  final List<EscortRequestModel> _requests = [];

  List<EscortVolunteerModel> get volunteers => List.unmodifiable(_volunteers);
  List<EscortRequestModel> get requests => List.unmodifiable(_requests);

  int get pendingCount =>
      _requests.where((r) => r.status == EscortRequestStatus.pending).length;

  Future<void> refreshVolunteers() async {
    if (!_supabase.isReady) return;
    final rows = await _supabase.client
        .from('escort_volunteers')
        .select()
        .eq('active', true)
        .order('created_at');
    _volunteers
      ..clear()
      ..addAll(
        (rows as List).map((r) {
          final m = Map<String, dynamic>.from(r as Map);
          return EscortVolunteerModel(
            email: m['email'] as String,
            displayName: m['display_name'] as String? ??
                (m['email'] as String).split('@').first,
          );
        }),
      );
    notifyListeners();
  }

  Future<void> addVolunteerEmail(String email) async {
    if (!_supabase.isReady) return;
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) return;

    final campus = CollegeService.instance.selectedCollege?.name;
    await _supabase.client.from('escort_volunteers').upsert({
      'email': normalized,
      'display_name': normalized.split('@').first,
      if (campus != null) 'campus_name': campus,
      'active': true,
    }, onConflict: 'email');
    await refreshVolunteers();
  }

  Future<void> removeVolunteer(String email) async {
    if (!_supabase.isReady) return;
    await _supabase.client
        .from('escort_volunteers')
        .update({'active': false}).eq('email', email.toLowerCase());
    await refreshVolunteers();
  }

  Future<EscortRequestModel> requestEscort({
    required String destination,
    String note = '',
  }) async {
    if (!_supabase.isReady) {
      throw StateError('Supabase is not connected.');
    }
    final uid = ProfileService.instance.currentUserId;
    if (uid == null) throw StateError('Please log in first.');

    await refreshVolunteers();
    final volunteer =
        _volunteers.isNotEmpty ? _volunteers.first.email : null;

    final row = await _supabase.client
        .from('escort_requests')
        .insert({
          'student_id': uid,
          'destination': destination.trim(),
          'note': note.trim(),
          'status': 'pending',
          if (volunteer != null) 'volunteer_email': volunteer,
        })
        .select()
        .single();

    final request = EscortRequestModel(
      id: row['id'] as String,
      studentEmail: _supabase.auth.currentUser?.email ?? '',
      destination: row['destination'] as String,
      note: row['note'] as String? ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      assignedVolunteerEmail: row['volunteer_email'] as String?,
      status: EscortRequestStatus.pending,
    );
    _requests.insert(0, request);
    notifyListeners();
    return request;
  }

  Future<void> setRequestStatus(
    String id,
    EscortRequestStatus status,
  ) async {
    if (!_supabase.isReady) return;
    await _supabase.client.from('escort_requests').update({
      'status': status.name,
    }).eq('id', id);

    final index = _requests.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _requests[index] = _requests[index].copyWith(status: status);
      notifyListeners();
    }
  }

  EscortVolunteerModel? volunteerFor(String? email) {
    if (email == null) return null;
    for (final v in _volunteers) {
      if (v.email == email.toLowerCase()) return v;
    }
    return null;
  }
}
