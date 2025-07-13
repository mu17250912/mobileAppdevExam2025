enum UserRole { farmer, buyer }

class User {
  final String id;
  final String name;
  final String phone;
  final String location;
  final UserRole role;
  final bool isPremium; // <-- Add this

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.role,
    this.isPremium = false, // <-- Default to false
  });
}
