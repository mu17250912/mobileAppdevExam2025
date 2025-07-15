class AppUser {
  final String uid;
  final String email;
  final String? name;
  final String? role; // 'user' or 'admin'
  final int? age;
  final double? weight;
  final double? height;
  final String? fitnessLevel;
  final List<String>? favorites; // List of favorite workout IDs
  final List<String>? completed; // List of completed workout IDs
  final Map<String, List<String>>? progress; // workoutId -> list of ISO date strings
  final bool? isPremium; // true if user has paid for premium

  AppUser({
    required this.uid,
    required this.email,
    this.name,
    this.role,
    this.age,
    this.weight,
    this.height,
    this.fitnessLevel,
    this.favorites,
    this.completed,
    this.progress,
    this.isPremium,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'],
      role: data['role'],
      age: data['age'],
      weight: (data['weight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      fitnessLevel: data['fitnessLevel'],
      favorites: (data['favorites'] as List?)?.map((e) => e.toString()).toList(),
      completed: (data['completed'] as List?)?.map((e) => e.toString()).toList(),
      progress: (data['progress'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList())),
      isPremium: data['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'age': age,
      'weight': weight,
      'height': height,
      'fitnessLevel': fitnessLevel,
      'favorites': favorites,
      'completed': completed,
      'progress': progress,
      'isPremium': isPremium,
    };
  }
} 