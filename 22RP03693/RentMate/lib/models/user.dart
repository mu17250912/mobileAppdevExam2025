class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserType userType;
  final String? profileImage;
  final String? university;
  final String? studentId;
  final bool isVerified;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime lastActive;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    this.profileImage,
    this.university,
    this.studentId,
    this.isVerified = false,
    this.isPremium = false,
    required this.createdAt,
    required this.lastActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      userType: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${json['userType']}',
      ),
      profileImage: json['profileImage'],
      university: json['university'],
      studentId: json['studentId'],
      isVerified: json['isVerified'] ?? false,
      isPremium: json['isPremium'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastActive: DateTime.parse(json['lastActive']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType.toString().split('.').last,
      'profileImage': profileImage,
      'university': university,
      'studentId': studentId,
      'isVerified': isVerified,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserType? userType,
    String? profileImage,
    String? university,
    String? studentId,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      profileImage: profileImage ?? this.profileImage,
      university: university ?? this.university,
      studentId: studentId ?? this.studentId,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

enum UserType {
  student,
  landlord,
} 