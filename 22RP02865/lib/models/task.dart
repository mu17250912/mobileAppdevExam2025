import 'package:hive/hive.dart';
import 'package:flutter/material.dart'; // Added for Color

part 'task.g.dart';

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  Color get priorityColor {
    switch (this) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  String get priorityText {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String subject;

  @HiveField(1)
  String notes;

  @HiveField(2)
  DateTime dateTime;

  @HiveField(3)
  int duration;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  TaskPriority priority;

  @HiveField(6)
  bool hasReminder;

  @HiveField(7)
  int reminderMinutes;

  String? id; // Firestore document ID

  Task({
    this.id,
    required this.subject,
    required this.notes,
    required this.dateTime,
    required this.duration,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.hasReminder = true,
    this.reminderMinutes = 15,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'notes': notes,
      'dateTime': dateTime.toIso8601String(),
      'duration': duration,
      'isCompleted': isCompleted,
      'priority': priority.index,
      'hasReminder': hasReminder,
      'reminderMinutes': reminderMinutes,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      subject: map['subject'] ?? '',
      notes: map['notes'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      duration: map['duration'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      priority: TaskPriority.values[map['priority'] ?? 1],
      hasReminder: map['hasReminder'] ?? true,
      reminderMinutes: map['reminderMinutes'] ?? 15,
    );
  }

  // Helper methods
  bool get isOverdue => !isCompleted && dateTime.isBefore(DateTime.now());
  bool get isDueToday => dateTime.day == DateTime.now().day && 
                        dateTime.month == DateTime.now().month && 
                        dateTime.year == DateTime.now().year;
  bool get isDueThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return dateTime.isAfter(weekStart) && dateTime.isBefore(weekEnd);
  }


}
