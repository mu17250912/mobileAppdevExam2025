import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String userType; // buyer, seller, agent, admin
  final String role; // 'user' or 'admin'
  final String? profileImage;
  final String? bio;
  final String? company;
  final String? licenseNumber; // for agents
  final List<String> favorites;
  final List<String> savedSearches;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.userType,
    this.role = 'user', // Default to regular user
    this.profileImage,
    this.bio,
    this.company,
    this.licenseNumber,
    this.favorites = const [],
    this.savedSearches = const [],
    this.preferences = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.isActive = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      userType: data['userType'] ?? 'buyer',
      role: data['role'] ?? 'user',
      profileImage: data['profileImage'],
      bio: data['bio'],
      company: data['company'],
      licenseNumber: data['licenseNumber'],
      favorites: List<String>.from(data['favorites'] ?? []),
      savedSearches: List<String>.from(data['savedSearches'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'userType': userType,
      'role': role,
      'profileImage': profileImage,
      'bio': bio,
      'company': company,
      'licenseNumber': licenseNumber,
      'favorites': favorites,
      'savedSearches': savedSearches,
      'preferences': preferences,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? userType,
    String? role,
    String? profileImage,
    String? bio,
    String? company,
    String? licenseNumber,
    List<String>? favorites,
    List<String>? savedSearches,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      company: company ?? this.company,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      favorites: favorites ?? this.favorites,
      savedSearches: savedSearches ?? this.savedSearches,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  String get userTypeDisplay {
    switch (userType.toLowerCase()) {
      case 'buyer':
        return 'Buyer';
      case 'seller':
        return 'Seller';
      case 'agent':
        return 'Real Estate Agent';
      case 'admin':
        return 'Administrator';
      default:
        return userType;
    }
  }

  bool get isAgent => userType.toLowerCase() == 'agent';
  bool get isSeller => userType.toLowerCase() == 'seller';
  bool get isBuyer => userType.toLowerCase() == 'buyer';
  bool get isAdmin => userType.toLowerCase() == 'admin';
  bool get isCommissioner => role == 'admin' || userType == 'commissioner';
} 