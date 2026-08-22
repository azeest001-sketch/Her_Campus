/// Peer escort request + volunteer roster (mock / demo).
enum EscortRequestStatus { pending, accepted, completed, cancelled }

class EscortVolunteerModel {
  const EscortVolunteerModel({
    required this.email,
    required this.displayName,
  });

  final String email;
  final String displayName;
}

class EscortRequestModel {
  const EscortRequestModel({
    required this.id,
    required this.studentEmail,
    required this.destination,
    required this.note,
    required this.createdAt,
    this.status = EscortRequestStatus.pending,
    this.assignedVolunteerEmail,
  });

  final String id;
  final String studentEmail;
  final String destination;
  final String note;
  final DateTime createdAt;
  final EscortRequestStatus status;
  final String? assignedVolunteerEmail;

  EscortRequestModel copyWith({
    EscortRequestStatus? status,
    String? assignedVolunteerEmail,
  }) {
    return EscortRequestModel(
      id: id,
      studentEmail: studentEmail,
      destination: destination,
      note: note,
      createdAt: createdAt,
      status: status ?? this.status,
      assignedVolunteerEmail:
          assignedVolunteerEmail ?? this.assignedVolunteerEmail,
    );
  }
}
