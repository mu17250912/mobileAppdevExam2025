class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String role;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
    };
  }
} 