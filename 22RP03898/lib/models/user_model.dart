import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { passenger, driver, admin }

enum UserStatus { active, inactive, suspended }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final UserType userType;
  final bool isVerified;
  final double? rating;
  final int totalRides;
  final int completedRides;
  final bool isPremium;
  final bool isBanned;
  final UserStatus status;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActive;
  final Map<String, dynamic> preferences;
  final String? bio;
  final String? vehicleType; // For drivers
  final String? vehicleNumber; // For drivers
  final String? licenseNumber; // For drivers
  final List<String> documents; // For driver verification

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.isVerified,
    required this.rating,
    required this.totalRides,
    required this.completedRides,
    required this.isPremium,
    this.isBanned = false,
    this.status = UserStatus.active,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActive,
    required this.preferences,
    this.profileImage,
    this.bio,
    this.vehicleType,
    this.vehicleNumber,
    this.licenseNumber,
    this.documents = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    // Improved userType parsing
    final userTypeStr = (map['userType'] ?? '').toString().toLowerCase().trim();
    UserType userType;

    switch (userTypeStr) {
      case 'passenger':
        userType = UserType.passenger;
        break;
      case 'driver':
        userType = UserType.driver;
        break;
      case 'admin':
        userType = UserType.admin;
        break;
      default:
        // Default to passenger if invalid type
        userType = UserType.passenger;
    }

    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      userType: userType,
      isVerified: map['isVerified'] ?? false,
      rating: map['rating']?.toDouble(),
      totalRides: map['totalRides'] ?? 0,
      completedRides: map['completedRides'] ?? 0,
      isPremium: map['isPremium'] ?? false,
      isBanned: map['isBanned'] ?? false,
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.active,
      ),
      fcmToken: map['fcmToken'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      lastActive: _parseDateTime(map['lastActive']),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      profileImage: map['profileImage'],
      bio: map['bio'],
      vehicleType: map['vehicleType'],
      vehicleNumber: map['vehicleNumber'],
      licenseNumber: map['licenseNumber'],
      documents: List<String>.from(map['documents'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType.name.toLowerCase(),
      'isVerified': isVerified,
      'rating': rating,
      'totalRides': totalRides,
      'completedRides': completedRides,
      'isPremium': isPremium,
      'isBanned': isBanned,
      'status': status.name,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'preferences': preferences,
      'profileImage': profileImage,
      'bio': bio,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'licenseNumber': licenseNumber,
      'documents': documents,
    };
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Ensure updatedAt exists, use createdAt if not present
    if (!data.containsKey('updatedAt')) {
      data['updatedAt'] = data['createdAt'];
    }
    return UserModel.fromMap(data, doc.id);
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // If parsing fails, return current time
        return DateTime.now();
      }
    }

    // Default fallback
    return DateTime.now();
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    UserType? userType,
    UserStatus? status,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseNumber,
    double? rating,
    int? totalRides,
    int? completedRides,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastActive,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    bool? isPremium,
    String? bio,
    List<String>? documents,
    bool? isVerified,
    bool? isBanned,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      completedRides: completedRides ?? this.completedRides,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      isPremium: isPremium ?? this.isPremium,
      bio: bio ?? this.bio,
      documents: documents ?? this.documents,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
    );
  }

  bool get isDriver => userType == UserType.driver;
  bool get isPassenger => userType == UserType.passenger;
  bool get isAdmin => userType == UserType.admin;
  bool get isActive => status == UserStatus.active;

  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  String get userTypeDisplay {
    switch (userType) {
      case UserType.driver:
        return 'Driver';
      case UserType.passenger:
        return 'Passenger';
      case UserType.admin:
        return 'Admin';
    }
  }
}
