class Application {
  final String applicationId;
  final String type;
  final String jobOrInternshipId;
  final String applicantId;
  final String appliedOn;
  late final String status;
  final String remarks;

  Application({
    required this.applicationId,
    required this.type,
    required this.jobOrInternshipId,
    required this.applicantId,
    required this.appliedOn,
    required this.status,
    required this.remarks,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      applicationId: json['applicationId'],
      type: json['type'],
      jobOrInternshipId: json['jobOrInternshipId'],
      applicantId: json['applicantId'],
      appliedOn: json['appliedOn'],
      status: json['status'],
      remarks: json['remarks'] ?? '',
    );
  }
}