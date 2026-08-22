/// Lifecycle of a student invite in the admin onboarding list.
enum InviteStatus {
  invited,
  sent,
  joined,
  failed,
}

/// Academic year bucket used to organize invite sections.
enum StudentYear {
  first,
  second,
  third,
}

extension StudentYearX on StudentYear {
  String get label {
    switch (this) {
      case StudentYear.first:
        return '1st Year';
      case StudentYear.second:
        return '2nd Year';
      case StudentYear.third:
        return '3rd Year';
    }
  }

  int get sortOrder {
    switch (this) {
      case StudentYear.first:
        return 1;
      case StudentYear.second:
        return 2;
      case StudentYear.third:
        return 3;
    }
  }
}

/// One student email the campus admin has invited.
class StudentInviteModel {
  const StudentInviteModel({
    required this.email,
    required this.displayName,
    required this.status,
    required this.year,
    required this.department,
    this.invitedAt,
    this.errorMessage,
  });

  final String email;
  final String displayName;
  final InviteStatus status;
  final StudentYear year;
  final String department;
  final DateTime? invitedAt;
  final String? errorMessage;

  StudentInviteModel copyWith({
    InviteStatus? status,
    StudentYear? year,
    String? department,
    DateTime? invitedAt,
    String? errorMessage,
  }) {
    return StudentInviteModel(
      email: email,
      displayName: displayName,
      status: status ?? this.status,
      year: year ?? this.year,
      department: department ?? this.department,
      invitedAt: invitedAt ?? this.invitedAt,
      errorMessage: errorMessage,
    );
  }
}
