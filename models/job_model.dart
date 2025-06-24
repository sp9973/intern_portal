import 'package:intern_link/models/application_model.dart';

// import 'application_model.dart';

class Job {
  final String jobId;
  final String postedBy;
  final String title;
  final String description;
  final String salary;
  final String location;
  final String eligibility;
  final String lastDate;
  final List<Application> applicationsReceived;
  final String status;
  final String companyLogo;

  Job({
    required this.jobId,
    required this.postedBy,
    required this.title,
    required this.description,
    required this.salary,
    required this.location,
    required this.eligibility,
    required this.lastDate,
    required this.applicationsReceived,
    required this.status,
    required this.companyLogo,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: json['jobId'],
      postedBy: json['postedBy'],
      title: json['title'],
      description: json['description'],
      salary: json['salary'],
      location: json['location'],
      eligibility: json['eligibility'],
      lastDate: json['lastDate'],
      applicationsReceived: (json['applicationsReceived'] as List)
          .map((app) => Application.fromJson(app))
          .toList(),
      status: json['status'],
      companyLogo: json['companyLogo'] ?? 'assets/images/default_company.png',
    );
  }
}