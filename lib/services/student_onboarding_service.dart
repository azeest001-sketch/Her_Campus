import 'package:flutter/foundation.dart';

import '../models/student_invite_model.dart';

/// Frontend mock for invite-only student onboarding.
///
/// Organizes invites by year → department so colleges can keep lists tidy.
///
/// Backend teammate: replace these methods with Supabase/API calls that:
/// 1) store the allowlist with year + department
/// 2) generate temporary passwords / invite links
/// 3) email credentials
/// 4) mark invite status as Sent / Joined / Failed
class StudentOnboardingService extends ChangeNotifier {
  StudentOnboardingService._();
  static final StudentOnboardingService instance = StudentOnboardingService._();

  final List<StudentInviteModel> _invites = [];

  /// Departments the admin typed in for each year.
  final Map<StudentYear, List<String>> _departmentsByYear = {
    for (final year in StudentYear.values) year: <String>[],
  };

  List<StudentInviteModel> get invites => List.unmodifiable(_invites);

  int countBy(InviteStatus status) =>
      _invites.where((invite) => invite.status == status).length;

  /// Departments the admin created for a year (plus any already used in invites).
  List<String> departmentsFor(StudentYear year) {
    final used = _invites
        .where((invite) => invite.year == year)
        .map((invite) => invite.department)
        .toSet();
    final custom = _departmentsByYear[year] ?? const <String>[];
    final all = <String>{...custom, ...used}.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return all;
  }

  void addDepartment(StudentYear year, String department) {
    final name = department.trim();
    if (name.isEmpty) return;
    final list = _departmentsByYear.putIfAbsent(year, () => <String>[]);
    final exists =
        list.any((item) => item.toLowerCase() == name.toLowerCase());
    if (exists) return;
    list.add(name);
    notifyListeners();
  }

  /// Invites for one year + department, newest first.
  List<StudentInviteModel> invitesFor({
    required StudentYear year,
    required String department,
  }) {
    return _invites
        .where(
          (invite) =>
              invite.year == year &&
              invite.department.toLowerCase() == department.toLowerCase(),
        )
        .toList(growable: false);
  }

  int countForYear(StudentYear year) =>
      _invites.where((invite) => invite.year == year).length;

  int countForDepartment(StudentYear year, String department) => invitesFor(
        year: year,
        department: department,
      ).length;

  /// Turns `joy.smith@college.edu` into `Joy Smith`.
  static String displayNameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return email;

    final cleaned = local
        .replaceAll(RegExp(r'[._+\-]+'), ' ')
        .replaceAll(RegExp(r'\d+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return local;

    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  /// Parses pasted text or CSV-ish content into unique emails.
  static List<String> parseEmails(String raw) {
    final matches = RegExp(
      r'[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}',
      caseSensitive: false,
    ).allMatches(raw);

    final seen = <String>{};
    final emails = <String>[];
    for (final match in matches) {
      final email = match.group(0)!.toLowerCase();
      if (seen.add(email)) emails.add(email);
    }
    return emails;
  }

  /// MOCK: queue invites into a year + department section.
  Future<List<StudentInviteModel>> inviteStudents(
    List<String> emails, {
    required StudentYear year,
    required String department,
  }) async {
    // TODO(backend):
    // - create allowlisted student accounts tagged with year + department
    // - generate secure temporary passwords OR magic invite links
    // - send email with login instructions
    // - never store plaintext passwords in the frontend

    final dept = department.trim();
    if (dept.isEmpty) {
      throw ArgumentError('Department is required');
    }

    for (final email in emails) {
      final existingIndex = _invites.indexWhere((item) => item.email == email);
      if (existingIndex >= 0) continue;

      _invites.insert(
        0,
        StudentInviteModel(
          email: email,
          displayName: displayNameFromEmail(email),
          status: InviteStatus.invited,
          year: year,
          department: dept,
          invitedAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();

    // Pretend the backend finished emailing temporary passwords.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    for (var i = 0; i < _invites.length; i++) {
      final invite = _invites[i];
      if (invite.status != InviteStatus.invited) continue;
      if (!emails.contains(invite.email)) continue;

      final failed =
          invite.email.endsWith('.invalid') || invite.email.contains('fail');
      _invites[i] = invite.copyWith(
        status: failed ? InviteStatus.failed : InviteStatus.sent,
        errorMessage: failed ? 'Mock email delivery failed' : null,
      );
    }
    notifyListeners();

    return _invites
        .where((invite) => emails.contains(invite.email))
        .toList(growable: false);
  }

  /// MOCK: CSV upload will be wired later; parsing text works for both paste and CSV content.
  Future<List<String>> parseCsvEmails(String csvText) async {
    // TODO(backend / frontend): accept file pickers and validated CSV columns.
    return parseEmails(csvText);
  }

  /// MOCK: true only if this email was invited and delivery didn't fail.
  /// Demo allowlist — students not on the list cannot sign in.
  bool isAllowlistedStudent(String email) {
    // TODO(backend): check invite / allowlist table server-side.
    final normalized = email.trim().toLowerCase();
    for (final invite in _invites) {
      if (invite.email != normalized) continue;
      return invite.status == InviteStatus.sent ||
          invite.status == InviteStatus.joined ||
          invite.status == InviteStatus.invited;
    }
    return false;
  }

  /// MOCK: after first student login, force password change until completed.
  Future<bool> studentMustChangePassword(String email) async {
    // TODO(backend): return true when the account still uses a temporary password.
    for (final invite in _invites) {
      if (invite.email == email.toLowerCase()) {
        return invite.status == InviteStatus.sent;
      }
    }
    return false;
  }

  Future<void> markJoined(String email) async {
    // TODO(backend): update invite row when the student completes first login.
    final index =
        _invites.indexWhere((item) => item.email == email.toLowerCase());
    if (index < 0) return;
    _invites[index] = _invites[index].copyWith(status: InviteStatus.joined);
    notifyListeners();
  }

  Future<void> completePasswordChange(String email) async {
    // TODO(backend): clear must_change_password flag after a successful update.
    await markJoined(email.toLowerCase());
  }
}
