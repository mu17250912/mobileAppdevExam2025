import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, user }

class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String password;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final String? profileImage;
  final Map<String, dynamic>? preferences;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.password,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
    this.profileImage,
    this.preferences,
  });

  // Factory constructor for admin user
  factory User.admin({
    required String id,
    required String name,
    required String email,
    required String username,
    required String password,
    required String phone,
  }) {
    return User(
      id: id,
      name: name,
      email: email,
      username: username,
      password: password,
      phone: phone,
      role: UserRole.admin,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  // Factory constructor for standard user
  factory User.standard({
    required String id,
    required String name,
    required String email,
    required String username,
    required String password,
    required String phone,
  }) {
    return User(
      id: id,
      name: name,
      email: email,
      username: username,
      password: password,
      phone: phone,
      role: UserRole.user,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'password': password,
      'phone': phone,
      'role': role.toString(),
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive,
      'profileImage': profileImage,
      'preferences': preferences,
    };
  }

  // Create from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      password: (map['password'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: map['role'] == 'UserRole.admin' ? UserRole.admin : UserRole.user,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastLogin: map['lastLogin'] is Timestamp
          ? (map['lastLogin'] as Timestamp).toDate()
          : (map['lastLogin'] != null ? DateTime.tryParse(map['lastLogin'].toString()) : null),
      isActive: map['isActive'] ?? true,
      profileImage: map['profileImage']?.toString(),
      preferences: map['preferences'] is Map<String, dynamic> ? map['preferences'] : <String, dynamic>{},
    );
  }

  // Copy with method for updating user data
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? password,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    String? profileImage,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      profileImage: profileImage ?? this.profileImage,
      preferences: preferences ?? this.preferences,
    );
  }

  // Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  // Get role display name
  String get roleDisplayName => role == UserRole.admin ? 'Administrator' : 'Standard User';

  // Get formatted creation date
  String get formattedCreatedAt => '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  // Get formatted last login
  String get formattedLastLogin {
    if (lastLogin == null) return 'Never';
    return '${lastLogin!.day}/${lastLogin!.month}/${lastLogin!.year} ${lastLogin!.hour}:${lastLogin!.minute}';
  }
}