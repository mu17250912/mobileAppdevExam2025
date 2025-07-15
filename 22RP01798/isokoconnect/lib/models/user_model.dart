class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String district;
  final String sector;
  final String role;
  final String email;
  final bool isPremium;
  final String? momoAccountNumber;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.district,
    required this.sector,
    required this.role,
    required this.email,
    required this.isPremium,
    this.momoAccountNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      district: map['district'] ?? '',
      sector: map['sector'] ?? '',
      role: map['role'] ?? '',
      email: map['email'] ?? '',
      isPremium: map['isPremium'] ?? false,
      momoAccountNumber: map['momoAccountNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'district': district,
      'sector': sector,
      'role': role,
      'email': email,
      'isPremium': isPremium,
      'momoAccountNumber': momoAccountNumber,
    };
  }
} 