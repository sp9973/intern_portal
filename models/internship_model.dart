import 'package:intern_link/models/application_model.dart';


class Internship {
  final String internshipId;
  final String postedBy;
  final String title;
  final String description;
  final String stipend;
  final String location;
  final String eligibility;
  final String lastDate;
  final List<Application> applicationsReceived;
  final String status;
  final String companyLogo;

  Internship({
    required this.internshipId,
    required this.postedBy,
    required this.title,
    required this.description,
    required this.stipend,
    required this.location,
    required this.eligibility,
    required this.lastDate,
    required this.applicationsReceived,
    required this.status,
    required this.companyLogo,
  });

  factory Internship.fromJson(Map<String, dynamic> json) {
    return Internship(
      internshipId: json['internshipId'],
      postedBy: json['postedBy'],
      title: json['title'],
      description: json['description'],
      stipend: json['stipend'],
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