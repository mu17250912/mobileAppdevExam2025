import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _userBox = 'user_box';
  static const String _settingsBox = 'settings_box';
  static const String _cacheBox = 'cache_box';

  static Future<void> initialize() async {
    // Initialize Hive boxes
    await Hive.openBox(_userBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_cacheBox);
  }

  // User data storage
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final box = Hive.box(_userBox);
    await box.put('current_user', userData);
  }

  static Map<String, dynamic>? getUserData() {
    final box = Hive.box(_userBox);
    return box.get('current_user');
  }

  static Future<void> clearUserData() async {
    final box = Hive.box(_userBox);
    await box.clear();
  }

  // Settings storage
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  static Future<void> removeSetting(String key) async {
    final box = Hive.box(_settingsBox);
    await box.delete(key);
  }

  // Cache storage
  static Future<void> saveToCache(String key, dynamic data) async {
    final box = Hive.box(_cacheBox);
    await box.put(key, data);
  }

  static T? getFromCache<T>(String key) {
    final box = Hive.box(_cacheBox);
    return box.get(key);
  }

  static Future<void> removeFromCache(String key) async {
    final box = Hive.box(_cacheBox);
    await box.delete(key);
  }

  static Future<void> clearCache() async {
    final box = Hive.box(_cacheBox);
    await box.clear();
  }

  // SharedPreferences for simple key-value storage
  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static Future<void> saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  static Future<void> saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  static Future<double?> getDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  static Future<void> removeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // App-specific storage methods
  static Future<void> saveAuthToken(String token) async {
    await saveString('auth_token', token);
  }

  static Future<String?> getAuthToken() async {
    return await getString('auth_token');
  }

  static Future<void> saveUserId(String userId) async {
    await saveString('user_id', userId);
  }

  static Future<String?> getUserId() async {
    return await getString('user_id');
  }

  static Future<void> saveUserType(String userType) async {
    await saveString('user_type', userType);
  }

  static Future<String?> getUserType() async {
    return await getString('user_type');
  }

  static Future<void> saveThemeMode(String themeMode) async {
    await saveString('theme_mode', themeMode);
  }

  static Future<String?> getThemeMode() async {
    return await getString('theme_mode');
  }

  static Future<void> saveLanguage(String language) async {
    await saveString('language', language);
  }

  static Future<String?> getLanguage() async {
    return await getString('language');
  }

  static Future<void> saveNotificationSettings(bool enabled) async {
    await saveBool('notifications_enabled', enabled);
  }

  static Future<bool?> getNotificationSettings() async {
    return await getBool('notifications_enabled');
  }

  // Clear all app data
  static Future<void> clearAllData() async {
    await clearAll();
    await clearUserData();
    await clearCache();
    
    final settingsBox = Hive.box(_settingsBox);
    await settingsBox.clear();
  }
} 