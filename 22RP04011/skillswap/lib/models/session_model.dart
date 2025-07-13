import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum SessionStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

enum SessionType {
  oneOnOne,
  group,
  workshop,
  consultation,
}

class SessionModel {
  final String id;
  final String title;
  final String description;
  final String skillId;
  final String skillName;
  final String hostId;
  final String hostName;
  final String? hostPhotoUrl;
  final List<String> participants;
  final List<Map<String, dynamic>> participantDetails;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int duration; // in minutes
  final SessionStatus status;
  final SessionType type;
  final String? meetingUrl;
  final String? meetingId;
  final String? meetingPassword;
  final String location;
  final double? price;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRecurring;
  final String? recurringPattern;
  final List<DateTime>? recurringDates;

  SessionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.skillId,
    required this.skillName,
    required this.hostId,
    required this.hostName,
    this.hostPhotoUrl,
    required this.participants,
    required this.participantDetails,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.duration,
    this.status = SessionStatus.pending,
    this.type = SessionType.oneOnOne,
    this.meetingUrl,
    this.meetingId,
    this.meetingPassword,
    this.location = 'Online',
    this.price,
    this.notes,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isRecurring = false,
    this.recurringPattern,
    this.recurringDates,
  });

  // Create from Firestore document
  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      skillId: data['skillId'] ?? '',
      skillName: data['skillName'] ?? '',
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      hostPhotoUrl: data['hostPhotoUrl'],
      participants: List<String>.from(data['participants'] ?? []),
      participantDetails:
          List<Map<String, dynamic>>.from(data['participantDetails'] ?? []),
      scheduledAt:
          (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      duration: data['duration'] ?? 60,
      status: SessionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'pending'),
        orElse: () => SessionStatus.pending,
      ),
      type: SessionType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'oneOnOne'),
        orElse: () => SessionType.oneOnOne,
      ),
      meetingUrl: data['meetingUrl'],
      meetingId: data['meetingId'],
      meetingPassword: data['meetingPassword'],
      location: data['location'] ?? 'Online',
      price: data['price']?.toDouble(),
      notes: data['notes'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRecurring: data['isRecurring'] ?? false,
      recurringPattern: data['recurringPattern'],
      recurringDates: data['recurringDates'] != null
          ? (data['recurringDates'] as List<dynamic>)
              .map((date) => (date as Timestamp).toDate())
              .toList()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'skillId': skillId,
      'skillName': skillName,
      'hostId': hostId,
      'hostName': hostName,
      'hostPhotoUrl': hostPhotoUrl,
      'participants': participants,
      'participantDetails': participantDetails,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'duration': duration,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'meetingUrl': meetingUrl,
      'meetingId': meetingId,
      'meetingPassword': meetingPassword,
      'location': location,
      'price': price,
      'notes': notes,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'recurringDates':
          recurringDates?.map((date) => Timestamp.fromDate(date)).toList(),
    };
  }

  // Create a copy with updated fields
  SessionModel copyWith({
    String? id,
    String? title,
    String? description,
    String? skillId,
    String? skillName,
    String? hostId,
    String? hostName,
    String? hostPhotoUrl,
    List<String>? participants,
    List<Map<String, dynamic>>? participantDetails,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? duration,
    SessionStatus? status,
    SessionType? type,
    String? meetingUrl,
    String? meetingId,
    String? meetingPassword,
    String? location,
    double? price,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRecurring,
    String? recurringPattern,
    List<DateTime>? recurringDates,
  }) {
    return SessionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      skillId: skillId ?? this.skillId,
      skillName: skillName ?? this.skillName,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostPhotoUrl: hostPhotoUrl ?? this.hostPhotoUrl,
      participants: participants ?? this.participants,
      participantDetails: participantDetails ?? this.participantDetails,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      type: type ?? this.type,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      meetingId: meetingId ?? this.meetingId,
      meetingPassword: meetingPassword ?? this.meetingPassword,
      location: location ?? this.location,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      recurringDates: recurringDates ?? this.recurringDates,
    );
  }

  // Start session
  SessionModel startSession() {
    return copyWith(
      status: SessionStatus.inProgress,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // End session
  SessionModel endSession() {
    return copyWith(
      status: SessionStatus.completed,
      endedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Cancel session
  SessionModel cancelSession() {
    return copyWith(
      status: SessionStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }

  // Confirm session
  SessionModel confirmSession() {
    return copyWith(
      status: SessionStatus.confirmed,
      updatedAt: DateTime.now(),
    );
  }

  // Add participant
  SessionModel addParticipant(
      String participantId, Map<String, dynamic> details) {
    final newParticipants = List<String>.from(participants)..add(participantId);
    final newParticipantDetails =
        List<Map<String, dynamic>>.from(participantDetails)..add(details);
    return copyWith(
      participants: newParticipants,
      participantDetails: newParticipantDetails,
      updatedAt: DateTime.now(),
    );
  }

  // Remove participant
  SessionModel removeParticipant(String participantId) {
    final newParticipants = List<String>.from(participants)
      ..remove(participantId);
    final newParticipantDetails =
        List<Map<String, dynamic>>.from(participantDetails)
          ..removeWhere((detail) => detail['userId'] == participantId);
    return copyWith(
      participants: newParticipants,
      participantDetails: newParticipantDetails,
      updatedAt: DateTime.now(),
    );
  }

  // Get status color
  Color get statusColor {
    switch (status) {
      case SessionStatus.pending:
        return Colors.orange;
      case SessionStatus.confirmed:
        return Colors.blue;
      case SessionStatus.inProgress:
        return Colors.green;
      case SessionStatus.completed:
        return Colors.grey;
      case SessionStatus.cancelled:
        return Colors.red;
      case SessionStatus.noShow:
        return Colors.red;
    }
  }

  // Get status icon
  IconData get statusIcon {
    switch (status) {
      case SessionStatus.pending:
        return Icons.schedule;
      case SessionStatus.confirmed:
        return Icons.check_circle_outline;
      case SessionStatus.inProgress:
        return Icons.play_circle_outline;
      case SessionStatus.completed:
        return Icons.done_all;
      case SessionStatus.cancelled:
        return Icons.cancel;
      case SessionStatus.noShow:
        return Icons.person_off;
    }
  }

  // Get type icon
  IconData get typeIcon {
    switch (type) {
      case SessionType.oneOnOne:
        return Icons.person;
      case SessionType.group:
        return Icons.group;
      case SessionType.workshop:
        return Icons.workspace_premium;
      case SessionType.consultation:
        return Icons.psychology;
    }
  }

  // Get formatted duration
  String get formattedDuration {
    if (duration < 60) {
      return '${duration}m';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  // Get formatted scheduled time
  String get formattedScheduledTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate =
        DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);

    if (sessionDate == today) {
      return 'Today at ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    } else if (sessionDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow at ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} at ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    }
  }

  // Check if session is upcoming (within next 24 hours)
  bool get isUpcoming {
    final now = DateTime.now();
    final difference = scheduledAt.difference(now);
    return difference.inHours > 0 && difference.inHours <= 24;
  }

  // Check if session is today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate =
        DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    return sessionDate == today;
  }

  // Check if session is overdue
  bool get isOverdue {
    return scheduledAt.isBefore(DateTime.now()) &&
        status == SessionStatus.pending;
  }

  // Get formatted price
  String get formattedPrice {
    if (price == null || price == 0) return 'Free';
    return '\$${price!.toStringAsFixed(2)}';
  }

  // Get participant count
  int get participantCount => participants.length;

  // Check if user is participant
  bool isParticipant(String userId) => participants.contains(userId);

  // Check if user is host
  bool isHost(String userId) => hostId == userId;

  @override
  String toString() {
    return 'SessionModel(id: $id, title: $title, status: $status, scheduledAt: $scheduledAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Session templates
class SessionTemplates {
  static SessionModel createOneOnOne({
    required String title,
    required String description,
    required String skillId,
    required String skillName,
    required String hostId,
    required String hostName,
    required String participantId,
    required String participantName,
    required DateTime scheduledAt,
    int duration = 60,
    String? hostPhotoUrl,
    String? participantPhotoUrl,
    double? price,
  }) {
    return SessionModel(
      id: '', // Will be set by Firestore
      title: title,
      description: description,
      skillId: skillId,
      skillName: skillName,
      hostId: hostId,
      hostName: hostName,
      hostPhotoUrl: hostPhotoUrl,
      participants: [participantId],
      participantDetails: [
        {
          'userId': participantId,
          'userName': participantName,
          'userPhotoUrl': participantPhotoUrl,
          'joinedAt': null,
          'leftAt': null,
        }
      ],
      scheduledAt: scheduledAt,
      duration: duration,
      type: SessionType.oneOnOne,
      price: price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static SessionModel createGroup({
    required String title,
    required String description,
    required String skillId,
    required String skillName,
    required String hostId,
    required String hostName,
    required List<String> participantIds,
    required List<String> participantNames,
    required DateTime scheduledAt,
    int duration = 90,
    String? hostPhotoUrl,
    List<String>? participantPhotoUrls,
    double? price,
  }) {
    final participantDetails = participantIds.asMap().entries.map((entry) {
      final index = entry.key;
      final participantId = entry.value;
      return {
        'userId': participantId,
        'userName': participantNames[index],
        'userPhotoUrl': participantPhotoUrls?[index],
        'joinedAt': null,
        'leftAt': null,
      };
    }).toList();

    return SessionModel(
      id: '', // Will be set by Firestore
      title: title,
      description: description,
      skillId: skillId,
      skillName: skillName,
      hostId: hostId,
      hostName: hostName,
      hostPhotoUrl: hostPhotoUrl,
      participants: participantIds,
      participantDetails: participantDetails,
      scheduledAt: scheduledAt,
      duration: duration,
      type: SessionType.group,
      price: price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
