import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 2)
class User {
  @HiveField(0)
  final String username;
  @HiveField(1)
  final String passwordHash;
  @HiveField(2)
  final bool isAdmin;

  User({
    required this.username,
    required this.passwordHash,
    required this.isAdmin,
  });
} 