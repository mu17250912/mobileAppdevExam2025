import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? studentId;
  final String? department;
  final DateTime createdAt;
  final List<String> eventIds; // IDs of events user is part of
  final bool isPremium;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.studentId,
    this.department,
    required this.createdAt,
    this.eventIds = const [],
    this.isPremium = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      studentId: map['studentId'],
      department: map['department'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      eventIds: List<String>.from(map['eventIds'] ?? []),
      isPremium: map['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'studentId': studentId,
      'department': department,
      'createdAt': createdAt,
      'eventIds': eventIds,
      'isPremium': isPremium,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? studentId,
    String? department,
    DateTime? createdAt,
    List<String>? eventIds,
    bool? isPremium,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      eventIds: eventIds ?? this.eventIds,
      isPremium: isPremium ?? this.isPremium,
    );
  }
} 