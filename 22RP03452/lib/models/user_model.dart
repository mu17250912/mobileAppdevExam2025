class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'teacher' or 'parent'
  final String? phone;
  final String? school;
  final String? department;
  final String? childName; // for parents
  final String? grade; // for teachers
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.school,
    this.department,
    this.childName,
    this.grade,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      phone: map['phone'],
      school: map['school'],
      department: map['department'],
      childName: map['childName'],
      grade: map['grade'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'school': school,
      'department': department,
      'childName': childName,
      'grade': grade,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? school,
    String? department,
    String? childName,
    String? grade,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      school: school ?? this.school,
      department: department ?? this.department,
      childName: childName ?? this.childName,
      grade: grade ?? this.grade,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 