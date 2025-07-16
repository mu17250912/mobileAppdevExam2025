class UserModel {
  final String uid;
  final String email;
  final String userType; // 'normal' or 'premium'
  final List<String> flaggedQuestions;
  final bool hasShared;
  final String displayName;
  final String avatarUrl;
  final Map<String, bool> sharedPlatforms;

  UserModel({
    required this.uid,
    required this.email,
    required this.userType,
    required this.flaggedQuestions,
    required this.hasShared,
    required this.displayName,
    required this.avatarUrl,
    required this.sharedPlatforms,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      userType: data['userType'] ?? 'normal',
      flaggedQuestions: List<String>.from(data['flaggedQuestions'] ?? []),
      hasShared: data['hasShared'] ?? false,
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      sharedPlatforms: Map<String, bool>.from(data['sharedPlatforms'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'userType': userType,
      'flaggedQuestions': flaggedQuestions,
      'hasShared': hasShared,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'sharedPlatforms': sharedPlatforms,
    };
  }
} 