class User {
  final String userId;
  final String role;
  final String name;
  final String email;
  final String password;
  final UserProfile profile;
  final String status;

  User({
    required this.userId,
    required this.role,
    required this.name,
    required this.email,
    required this.password,
    required this.profile,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      role: json['role'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      profile: UserProfile.fromJson(json['profile']),
      status: json['status'],
    );
  }
}

class UserProfile {
  final String? resumeLink;
  final List<String>? skills;
  final String? experience;
  final String? education;
  List<String>? savedJobs;
  final String? companyWebsite;
  final String? companyDescription;
  final List<String>? postedJobs;
  final List<String>? postedInternships;
  final String? profilePicture;

  UserProfile({
    this.resumeLink,
    this.skills,
    this.experience,
    this.education,
    this.savedJobs,
    this.companyWebsite,
    this.companyDescription,
    this.postedJobs,
    this.postedInternships,
    this.profilePicture, String? companyLogo,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      resumeLink: json['resumeLink'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      experience: json['experience'],
      education: json['education'],
      savedJobs: json['savedJobs'] != null ? List<String>.from(json['savedJobs']) : null,
      companyWebsite: json['companyWebsite'],
      companyDescription: json['companyDescription'],
      postedJobs: json['postedJobs'] != null ? List<String>.from(json['postedJobs']) : null,
      postedInternships: json['postedInternships'] != null ? List<String>.from(json['postedInternships']) : null,
      profilePicture: json['profilePicture'],
    );
  }
}