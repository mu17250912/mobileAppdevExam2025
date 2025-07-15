import 'package:cloud_firestore/cloud_firestore.dart';

class Homework {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final String teacherId;
  final String teacherName;
  final DateTime dueDate;
  final DateTime createdAt;
  final List<String> attachments;
  final bool isActive;

  Homework({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.dueDate,
    required this.createdAt,
    this.attachments = const [],
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'attachments': attachments,
      'isActive': isActive,
    };
  }

  factory Homework.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      throw Exception('Invalid date format');
    }

    return Homework(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      teacherId: map['teacherId']?.toString() ?? '',
      teacherName: map['teacherName']?.toString() ?? '',
      dueDate: parseDate(map['dueDate']),
      createdAt: parseDate(map['createdAt']),
      attachments: (map['attachments'] is List)
          ? List<String>.from(map['attachments'])
          : <String>[],
      isActive: map['isActive'] ?? true,
    );
  }
} 