import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.isPremium = false,
    required this.createdAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'isPremium': isPremium ? 'true' : 'false',
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      isPremium: map['isPremium'] == 'true',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null 
          ? (map['lastLoginAt'] as Timestamp).toDate()
          : null,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
} 