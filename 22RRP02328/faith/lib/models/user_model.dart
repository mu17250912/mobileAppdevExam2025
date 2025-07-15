class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String userType; // admin, user, service_provider
  final String? profileImage;
  final String? location;
  final String? bio;
  final List<String>? services; // For service providers
  final double? rating;
  final int? reviewCount;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    this.profileImage,
    this.location,
    this.bio,
    this.services,
    this.rating,
    this.reviewCount,
    this.isPremium = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['userType'] ?? 'user',
      profileImage: json['profileImage'],
      location: json['location'],
      bio: json['bio'],
      services: json['services'] != null 
          ? List<String>.from(json['services']) 
          : null,
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      isPremium: json['isPremium'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType,
      'profileImage': profileImage,
      'location': location,
      'bio': bio,
      'services': services,
      'rating': rating,
      'reviewCount': reviewCount,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? userType,
    String? profileImage,
    String? location,
    String? bio,
    List<String>? services,
    double? rating,
    int? reviewCount,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      profileImage: profileImage ?? this.profileImage,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      services: services ?? this.services,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAdmin => userType == 'admin';
  bool get isServiceProvider => userType == 'service_provider';
  bool get isRegularUser => userType == 'user';
} 