class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? country;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool isPremium;
  final String? subscriptionPlan; // "monthly", "annual", etc.
  final DateTime? subscriptionExpiry;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final Map<String, dynamic>? preferences;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.country,
    this.createdAt,
    this.lastLoginAt,
    this.isPremium = false,
    this.subscriptionPlan,
    this.subscriptionExpiry,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.preferences,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'city': city,
      'country': country,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isPremium': isPremium,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'preferences': preferences,
    };
  }

  // Create from Map (from Firestore)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.parse(map['dateOfBirth']) : null,
      gender: map['gender'],
      address: map['address'],
      city: map['city'],
      country: map['country'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.parse(map['lastLoginAt']) : null,
      isPremium: map['isPremium'] ?? false,
      subscriptionPlan: map['subscriptionPlan'],
      subscriptionExpiry: map['subscriptionExpiry'] != null ? DateTime.parse(map['subscriptionExpiry']) : null,
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      preferences: map['preferences'],
    );
  }

  // Create a copy with updated fields
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? country,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isPremium,
    String? subscriptionPlan,
    DateTime? subscriptionExpiry,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isPremium: isPremium ?? this.isPremium,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      preferences: preferences ?? this.preferences,
    );
  }
} 