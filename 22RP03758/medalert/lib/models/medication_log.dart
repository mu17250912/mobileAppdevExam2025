import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationLogModel {
  final String? id;
  final String userId;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final bool taken;
  final String? notes;
  final DateTime timestamp;
  final String? reminderId;
  final int reminderCount; // Number of reminders sent
  final DateTime? lastReminderSent;
  final String status; // 'scheduled', 'taken', 'missed', 'skipped'

  MedicationLogModel({
    this.id,
    required this.userId,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    this.takenTime,
    required this.taken,
    this.notes,
    required this.timestamp,
    this.reminderId,
    this.reminderCount = 0,
    this.lastReminderSent,
    this.status = 'scheduled',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'takenTime': takenTime != null ? Timestamp.fromDate(takenTime!) : null,
      'taken': taken,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
      'reminderId': reminderId,
      'reminderCount': reminderCount,
      'lastReminderSent': lastReminderSent != null ? Timestamp.fromDate(lastReminderSent!) : null,
      'status': status,
    };
  }

  factory MedicationLogModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MedicationLogModel(
      id: documentId,
      userId: map['userId'] ?? '',
      medicationId: map['medicationId'] ?? '',
      medicationName: map['medicationName'] ?? '',
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      takenTime: map['takenTime'] != null ? (map['takenTime'] as Timestamp).toDate() : null,
      taken: map['taken'] ?? false,
      notes: map['notes'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      reminderId: map['reminderId'],
      reminderCount: map['reminderCount'] ?? 0,
      lastReminderSent: map['lastReminderSent'] != null ? (map['lastReminderSent'] as Timestamp).toDate() : null,
      status: map['status'] ?? 'scheduled',
    );
  }

  MedicationLogModel copyWith({
    String? id,
    String? userId,
    String? medicationId,
    String? medicationName,
    DateTime? scheduledTime,
    DateTime? takenTime,
    bool? taken,
    String? notes,
    DateTime? timestamp,
    String? reminderId,
    int? reminderCount,
    DateTime? lastReminderSent,
    String? status,
  }) {
    return MedicationLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      taken: taken ?? this.taken,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      reminderId: reminderId ?? this.reminderId,
      reminderCount: reminderCount ?? this.reminderCount,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
      status: status ?? this.status,
    );
  }

  // Helper methods
  bool get isOverdue {
    return !taken && DateTime.now().isAfter(scheduledTime);
  }

  bool get isToday {
    final now = DateTime.now();
    final scheduled = scheduledTime;
    return now.year == scheduled.year &&
           now.month == scheduled.month &&
           now.day == scheduled.day;
  }

  Duration? get delayDuration {
    if (taken && takenTime != null) {
      return takenTime!.difference(scheduledTime);
    }
    return null;
  }

  bool get isOnTime {
    if (!taken) return false;
    final delay = delayDuration;
    return delay != null && delay.inMinutes <= 30; // Consider on time if within 30 minutes
  }
} 