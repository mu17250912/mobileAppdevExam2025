import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static bool _initialized = false;

  Future<void> _initHive() async {
    if (!_initialized) {
      await Hive.initFlutter();
      final box = await Hive.openBox('users');
      // Add default user if not present
      final exists = box.values.any((u) =>
        u is Map &&
        u['email'] == 'clemenceuwi22@gmail.com' &&
        u['password'] == 'clemmy@123');
      if (!exists) {
        await box.add({
          'name': 'Clemence Uwi',
          'email': 'clemenceuwi22@gmail.com',
          'password': 'clemmy@123',
        });
      }
      _initialized = true;
    }
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    await _initHive();
    final box = Hive.box('users');
    int key = await box.add(user);
    return key;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    await _initHive();
    final box = Hive.box('users');
    return box.values.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    await _initHive();
    final box = Hive.box('users');
    final idx = box.values.toList().indexWhere((u) => u['email'] == user['email']);
    if (idx != -1) {
      await box.putAt(idx, user);
    }
  }

  Future close() async {
    await Hive.close();
  }
} 