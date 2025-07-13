import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'patient' or 'caregiver'
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? medicalInfo;
  final String? profileImageUrl;
  final String? referralCode;
  final String? referredBy;
  final DateTime? referralAppliedAt;
  final int referralCount;
  final String subscriptionStatus; // 'free', 'premium', 'family'
  final DateTime? subscriptionExpiresAt;
  final DateTime? trialExpiresAt;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    required this.createdAt,
    this.lastLoginAt,
    this.medicalInfo,
    this.profileImageUrl,
    this.referralCode,
    this.referredBy,
    this.referralAppliedAt,
    this.referralCount = 0,
    this.subscriptionStatus = 'free',
    this.subscriptionExpiresAt,
    this.trialExpiresAt,
    this.settings,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'medicalInfo': medicalInfo,
      'profileImageUrl': profileImageUrl,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralAppliedAt': referralAppliedAt != null ? Timestamp.fromDate(referralAppliedAt!) : null,
      'referralCount': referralCount,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionExpiresAt': subscriptionExpiresAt != null ? Timestamp.fromDate(subscriptionExpiresAt!) : null,
      'trialExpiresAt': trialExpiresAt != null ? Timestamp.fromDate(trialExpiresAt!) : null,
      'settings': settings,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'patient',
      phoneNumber: map['phoneNumber'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: map['lastLoginAt'] != null ? (map['lastLoginAt'] as Timestamp).toDate() : null,
      medicalInfo: map['medicalInfo'],
      profileImageUrl: map['profileImageUrl'],
      referralCode: map['referralCode'],
      referredBy: map['referredBy'],
      referralAppliedAt: map['referralAppliedAt'] != null ? (map['referralAppliedAt'] as Timestamp).toDate() : null,
      referralCount: map['referralCount'] ?? 0,
      subscriptionStatus: map['subscriptionStatus'] ?? 'free',
      subscriptionExpiresAt: map['subscriptionExpiresAt'] != null ? (map['subscriptionExpiresAt'] as Timestamp).toDate() : null,
      trialExpiresAt: map['trialExpiresAt'] != null ? (map['trialExpiresAt'] as Timestamp).toDate() : null,
      settings: map['settings'],
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? medicalInfo,
    String? profileImageUrl,
    String? referralCode,
    String? referredBy,
    DateTime? referralAppliedAt,
    int? referralCount,
    String? subscriptionStatus,
    DateTime? subscriptionExpiresAt,
    DateTime? trialExpiresAt,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      referralAppliedAt: referralAppliedAt ?? this.referralAppliedAt,
      referralCount: referralCount ?? this.referralCount,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      trialExpiresAt: trialExpiresAt ?? this.trialExpiresAt,
      settings: settings ?? this.settings,
    );
  }
} 