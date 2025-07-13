class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? profileImage;
  final String? address;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isVerified;
  final Map<String, dynamic> preferences;
  final List<String> favoriteProviders;
  final int totalBookings;
  final double averageRating;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.profileImage,
    this.address,
    required this.createdAt,
    this.lastLogin,
    this.isVerified = false,
    this.preferences = const {},
    this.favoriteProviders = const [],
    this.totalBookings = 0,
    this.averageRating = 0.0,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      profileImage: map['profileImage'],
      address: map['address'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      lastLogin: map['lastLogin'] != null 
          ? DateTime.parse(map['lastLogin']) 
          : null,
      isVerified: map['isVerified'] ?? false,
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      favoriteProviders: List<String>.from(map['favoriteProviders'] ?? []),
      totalBookings: map['totalBookings'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isVerified': isVerified,
      'preferences': preferences,
      'favoriteProviders': favoriteProviders,
      'totalBookings': totalBookings,
      'averageRating': averageRating,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    String? address,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isVerified,
    Map<String, dynamic>? preferences,
    List<String>? favoriteProviders,
    int? totalBookings,
    double? averageRating,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isVerified: isVerified ?? this.isVerified,
      preferences: preferences ?? this.preferences,
      favoriteProviders: favoriteProviders ?? this.favoriteProviders,
      totalBookings: totalBookings ?? this.totalBookings,
      averageRating: averageRating ?? this.averageRating,
    );
  }
} 