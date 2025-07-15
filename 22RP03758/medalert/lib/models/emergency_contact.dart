import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactModel {
  final String? id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String? email;
  final String relationship; // 'family', 'friend', 'doctor', 'caregiver', 'other'
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime? lastContactedAt;
  final String? notes;
  final bool notificationsEnabled;
  final List<String> notificationTypes; // 'missed_medication', 'emergency', 'adherence_alert'

  EmergencyContactModel({
    this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.relationship,
    this.isPrimary = false,
    required this.createdAt,
    this.lastContactedAt,
    this.notes,
    this.notificationsEnabled = true,
    this.notificationTypes = const ['emergency'],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastContactedAt': lastContactedAt != null ? Timestamp.fromDate(lastContactedAt!) : null,
      'notes': notes,
      'notificationsEnabled': notificationsEnabled,
      'notificationTypes': notificationTypes,
    };
  }

  factory EmergencyContactModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EmergencyContactModel(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      relationship: map['relationship'] ?? 'other',
      isPrimary: map['isPrimary'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastContactedAt: map['lastContactedAt'] != null ? (map['lastContactedAt'] as Timestamp).toDate() : null,
      notes: map['notes'],
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      notificationTypes: List<String>.from(map['notificationTypes'] ?? ['emergency']),
    );
  }

  EmergencyContactModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? lastContactedAt,
    String? notes,
    bool? notificationsEnabled,
    List<String>? notificationTypes,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
      notes: notes ?? this.notes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTypes: notificationTypes ?? this.notificationTypes,
    );
  }

  // Helper methods
  String get displayName {
    return isPrimary ? '$name (Primary)' : name;
  }

  String get formattedPhoneNumber {
    // Basic phone number formatting
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phoneNumber;
  }

  bool get canReceiveEmergencyAlerts {
    return notificationsEnabled && notificationTypes.contains('emergency');
  }

  bool get canReceiveMissedMedicationAlerts {
    return notificationsEnabled && notificationTypes.contains('missed_medication');
  }

  bool get canReceiveAdherenceAlerts {
    return notificationsEnabled && notificationTypes.contains('adherence_alert');
  }

  String get relationshipDisplay {
    switch (relationship.toLowerCase()) {
      case 'family':
        return 'Family Member';
      case 'friend':
        return 'Friend';
      case 'doctor':
        return 'Doctor';
      case 'caregiver':
        return 'Caregiver';
      case 'other':
        return 'Other';
      default:
        return relationship;
    }
  }
} 