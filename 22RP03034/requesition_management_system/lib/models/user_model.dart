// 🔄 FILE 2: user_model.dart (keep only Firestore-based data model)
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String password; // Can be blank; don't store real password
  final String role;
  final String? postName;
  final String? profileImagePath;
  final DateTime registrationDate;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.password,
    required this.role,
    this.postName,
    this.profileImagePath,
    required this.registrationDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'postName': postName,
        'profileImagePath': profileImagePath,
        'registrationDate': registrationDate.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        password: '',
        role: json['role'],
        postName: json['postName'],
        profileImagePath: json['profileImagePath'],
        registrationDate: DateTime.parse(json['registrationDate']),
      );
}
