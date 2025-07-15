class Profile {
  final String name;
  final int age;
  final String gender;
  final String? photoPath;
  final bool isPaidUser;

  Profile({required this.name, required this.age, required this.gender, this.photoPath, this.isPaidUser = false});

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'photoPath': photoPath,
        'isPaidUser': isPaidUser,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        name: json['name'],
        age: json['age'],
        gender: json['gender'],
        photoPath: json['photoPath'],
        isPaidUser: json['isPaidUser'] ?? false,
      );
} 