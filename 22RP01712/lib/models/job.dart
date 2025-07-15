import '../models/user.dart';
import 'dart:convert';

class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final List<String> requirements;
  final String salary;
  final String jobType; // e.g., Full-time, Part-time, Contract
  final String experienceLevel; // e.g., Entry, Mid, Senior
  final String deadline; // Application deadline (ISO string)
  List<AppUser> applicants;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.requirements,
    required this.salary,
    required this.jobType,
    required this.experienceLevel,
    required this.deadline,
    List<AppUser>? applicants,
  }) : applicants = applicants ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'description': description,
      'requirements': jsonEncode(requirements),
      'salary': salary,
      'jobType': jobType,
      'experienceLevel': experienceLevel,
      'deadline': deadline,
      'applicants': jsonEncode(applicants.map((u) => u.id).toList()),
    };
  }

  factory Job.fromMap(Map<String, dynamic> map, List<AppUser> allUsers) {
    List<String> applicantIds = List<String>.from(jsonDecode(map['applicants'] ?? '[]'));
    List<AppUser> applicants = allUsers.where((u) => applicantIds.contains(u.id)).toList();
    return Job(
      id: map['id'],
      title: map['title'],
      company: map['company'],
      location: map['location'],
      description: map['description'],
      requirements: List<String>.from(jsonDecode(map['requirements'] ?? '[]')),
      salary: map['salary'],
      jobType: map['jobType'],
      experienceLevel: map['experienceLevel'],
      deadline: map['deadline'] ?? '',
      applicants: applicants,
    );
  }
} 