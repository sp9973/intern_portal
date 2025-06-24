import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/internship_model.dart';
import '../models/application_model.dart';

class JsonDataService {
  static Future<List<User>> loadUsers() async {
    final String response = await rootBundle.loadString('assets/database/users.json');
    final data = await json.decode(response) as List;
    return data.map((user) => User.fromJson(user)).toList();
  }

  static Future<List<Job>> loadJobs() async {
    final String response = await rootBundle.loadString('assets/database/jobs.json');
    final data = await json.decode(response) as List;
    return data.map((job) => Job.fromJson(job)).toList();
  }

  static Future<List<Internship>> loadInternships() async {
    final String response = await rootBundle.loadString('assets/database/internships.json');
    final data = await json.decode(response) as List;
    return data.map((internship) => Internship.fromJson(internship)).toList();
  }

  static Future<List<Application>> loadApplications() async {
    final String response = await rootBundle.loadString('assets/database/applications.json');
    final data = await json.decode(response) as List;
    return data.map((app) => Application.fromJson(app)).toList();
  }
}