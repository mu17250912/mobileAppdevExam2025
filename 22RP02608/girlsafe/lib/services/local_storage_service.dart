import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _premiumKey = 'is_premium';
  static const String _remindersKey = 'reminders';

  // User Authentication
  static Future<void> saveUserData(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'username': username,
      'password': password,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_userKey, jsonEncode(userData));
    await prefs.setBool(_isLoggedInKey, true);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }

  static Future<bool> validateCredentials(String username, String password) async {
    final userData = await getUserData();
    if (userData != null) {
      return userData['username'] == username && userData['password'] == password;
    }
    return false;
  }

  // Premium Status
  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  static Future<void> setPremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, isPremium);
  }

  // Reminders
  static Future<List<Map<String, dynamic>>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersString = prefs.getString(_remindersKey);
    if (remindersString != null) {
      final List<dynamic> remindersList = jsonDecode(remindersString);
      return remindersList.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<void> saveReminders(List<Map<String, dynamic>> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remindersKey, jsonEncode(reminders));
  }

  static Future<void> addReminder(Map<String, dynamic> reminder) async {
    final reminders = await getReminders();
    reminders.add(reminder);
    await saveReminders(reminders);
  }

  static Future<void> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((reminder) => reminder['id'] == id);
    await saveReminders(reminders);
  }
} 