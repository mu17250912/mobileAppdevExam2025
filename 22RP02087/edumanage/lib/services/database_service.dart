import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new student
  Future<void> addStudent(Map<String, dynamic> studentData) async {
    await _db.collection('students').add(studentData);
  }

  // Add a new course
  Future<void> addCourse(Map<String, dynamic> courseData) async {
    await _db.collection('courses').add(courseData);
  }

  // Add a new grade
  Future<void> addGrade(Map<String, dynamic> gradeData) async {
    await _db.collection('grades').add(gradeData);
  }

  // Add attendance
  Future<void> addAttendance(Map<String, dynamic> attendanceData) async {
    await _db.collection('attendance').add(attendanceData);
  }
}
