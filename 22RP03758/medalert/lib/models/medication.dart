import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationModel {
  final String? id;
  final String userId;
  final String name;
  final String dosage;
  final String frequency; // 'once_daily', 'twice_daily', 'three_times_daily', 'custom'
  final List<TimeOfDay> times;
  final String? instructions;
  final String? notes;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? customSchedule; // For custom frequency schedules

  MedicationModel({
    this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    this.instructions,
    this.notes,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.color,
    this.icon,
    required this.createdAt,
    this.updatedAt,
    this.customSchedule,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times.map((time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}').toList(),
      'instructions': instructions,
      'notes': notes,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'color': color,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'customSchedule': customSchedule,
    };
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MedicationModel(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? 'once_daily',
      times: (map['times'] as List<dynamic>? ?? []).map((timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList(),
      instructions: map['instructions'],
      notes: map['notes'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      isActive: map['isActive'] ?? true,
      color: map['color'],
      icon: map['icon'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      customSchedule: map['customSchedule'],
    );
  }

  MedicationModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    String? frequency,
    List<TimeOfDay>? times,
    String? instructions,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customSchedule,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customSchedule: customSchedule ?? this.customSchedule,
    );
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
} 