import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status; // 'confirmed', 'pending', 'declined', 'checked-in', 'checked-out'

  Attendance({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.checkInTime,
    this.checkOutTime,
    this.status = 'pending',
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      checkInTime: (map['checkInTime'] as Timestamp).toDate(),
      checkOutTime: map['checkOutTime'] != null 
          ? (map['checkOutTime'] as Timestamp).toDate() 
          : null,
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'status': status,
    };
  }

  Attendance copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
  }) {
    return Attendance(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
    );
  }
} 