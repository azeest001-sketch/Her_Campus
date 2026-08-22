/// Safety incident / event report from a student to campus admin.
enum ReportStatus { newReport, reviewing, resolved }

class ReportModel {
  const ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.reporterEmail,
    required this.createdAt,
    this.locationLabel,
    this.status = ReportStatus.newReport,
  });

  final String id;
  final String title;
  final String description;
  final String reporterEmail;
  final String? locationLabel;
  final DateTime createdAt;
  final ReportStatus status;

  ReportModel copyWith({ReportStatus? status}) {
    return ReportModel(
      id: id,
      title: title,
      description: description,
      reporterEmail: reporterEmail,
      createdAt: createdAt,
      locationLabel: locationLabel,
      status: status ?? this.status,
    );
  }
}
