import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverAssignmentModel {
  final String? id;
  final String patientId;
  final String caregiverId;
  final String patientName;
  final String caregiverName;
  final DateTime assignedAt;
  final DateTime? lastContactAt;
  final String status; // 'active', 'pending', 'inactive'
  final Map<String, dynamic>? permissions; // What the caregiver can see/do
  final String? notes;
  final bool notificationsEnabled;
  final List<String> notificationTypes; // 'missed_medication', 'emergency', 'adherence_report'

  CaregiverAssignmentModel({
    this.id,
    required this.patientId,
    required this.caregiverId,
    required this.patientName,
    required this.caregiverName,
    required this.assignedAt,
    this.lastContactAt,
    this.status = 'active',
    this.permissions,
    this.notes,
    this.notificationsEnabled = true,
    this.notificationTypes = const ['missed_medication', 'emergency'],
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'caregiverId': caregiverId,
      'patientName': patientName,
      'caregiverName': caregiverName,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'lastContactAt': lastContactAt != null ? Timestamp.fromDate(lastContactAt!) : null,
      'status': status,
      'permissions': permissions,
      'notes': notes,
      'notificationsEnabled': notificationsEnabled,
      'notificationTypes': notificationTypes,
    };
  }

  factory CaregiverAssignmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CaregiverAssignmentModel(
      id: documentId,
      patientId: map['patientId'] ?? '',
      caregiverId: map['caregiverId'] ?? '',
      patientName: map['patientName'] ?? '',
      caregiverName: map['caregiverName'] ?? '',
      assignedAt: (map['assignedAt'] as Timestamp).toDate(),
      lastContactAt: map['lastContactAt'] != null ? (map['lastContactAt'] as Timestamp).toDate() : null,
      status: map['status'] ?? 'active',
      permissions: map['permissions'],
      notes: map['notes'],
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      notificationTypes: List<String>.from(map['notificationTypes'] ?? ['missed_medication', 'emergency']),
    );
  }

  CaregiverAssignmentModel copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    String? patientName,
    String? caregiverName,
    DateTime? assignedAt,
    DateTime? lastContactAt,
    String? status,
    Map<String, dynamic>? permissions,
    String? notes,
    bool? notificationsEnabled,
    List<String>? notificationTypes,
  }) {
    return CaregiverAssignmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      patientName: patientName ?? this.patientName,
      caregiverName: caregiverName ?? this.caregiverName,
      assignedAt: assignedAt ?? this.assignedAt,
      lastContactAt: lastContactAt ?? this.lastContactAt,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      notes: notes ?? this.notes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTypes: notificationTypes ?? this.notificationTypes,
    );
  }

  // Helper methods
  bool get isActive {
    return status == 'active';
  }

  bool get canViewMedications {
    return permissions?['view_medications'] ?? true;
  }

  bool get canViewAdherence {
    return permissions?['view_adherence'] ?? true;
  }

  bool get canReceiveNotifications {
    return notificationsEnabled && isActive;
  }

  bool get canReceiveMissedMedicationAlerts {
    return canReceiveNotifications && notificationTypes.contains('missed_medication');
  }

  bool get canReceiveEmergencyAlerts {
    return canReceiveNotifications && notificationTypes.contains('emergency');
  }

  bool get canReceiveAdherenceReports {
    return canReceiveNotifications && notificationTypes.contains('adherence_report');
  }
} 