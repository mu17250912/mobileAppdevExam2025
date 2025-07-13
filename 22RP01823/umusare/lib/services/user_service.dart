import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static User? _currentUser;
  static bool _isSessionDestroyed = false;

  // Get current user
  static User? get currentUser => _isSessionDestroyed ? null : _currentUser;

  // Set current user
  static void setCurrentUser(User user) {
    _currentUser = user;
    _isSessionDestroyed = false;
    _saveUserToStorage(user);
  }

  // Clear current user (logout)
  static void clearCurrentUser() {
    _currentUser = null;
    _isSessionDestroyed = false;
    _clearUserFromStorage();
  }

  // Destroy session completely (prevents back navigation)
  static void destroySession() {
    _currentUser = null;
    _isSessionDestroyed = true;
    _clearUserFromStorage();
  }

  // Check if user is logged in
  static bool get isLoggedIn => !_isSessionDestroyed && _currentUser != null;

  // Check if session was destroyed
  static bool get isSessionDestroyed => _isSessionDestroyed;

  // Get user ID
  static String? get userId => _isSessionDestroyed ? null : _currentUser?.id;

  // Get user name
  static String? get userName => _isSessionDestroyed ? null : _currentUser?.name;

  // Get user email
  static String? get userEmail => _isSessionDestroyed ? null : _currentUser?.email;

  // Save user to local storage
  static Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_created_at', user.createdAt.toIso8601String());
      if (user.lastLoginAt != null) {
        await prefs.setString('user_last_login', user.lastLoginAt!.toIso8601String());
      }
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('session_destroyed', false);
    } catch (e) {
      print('Error saving user to storage: $e');
    }
  }

  // Clear user from local storage
  static Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_created_at');
      await prefs.remove('user_last_login');
      await prefs.setBool('is_logged_in', false);
      await prefs.setBool('session_destroyed', true);
    } catch (e) {
      print('Error clearing user from storage: $e');
    }
  }

  // Load user from local storage
  static Future<User?> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final sessionDestroyed = prefs.getBool('session_destroyed') ?? false;

      if (!isLoggedIn || sessionDestroyed) {
        return null;
      }

      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userCreatedAt = prefs.getString('user_created_at');
      final userLastLogin = prefs.getString('user_last_login');

      if (userId != null && userName != null && userEmail != null && userCreatedAt != null) {
        final user = User(
          id: userId,
          name: userName,
          email: userEmail,
          password: '', // Don't store password in local storage
          createdAt: DateTime.parse(userCreatedAt),
          lastLoginAt: userLastLogin != null ? DateTime.parse(userLastLogin) : null,
        );
        _currentUser = user;
        _isSessionDestroyed = false;
        return user;
      }
    } catch (e) {
      print('Error loading user from storage: $e');
    }
    return null;
  }

  // Check if user should be redirected to login
  static bool shouldRedirectToLogin() {
    return _isSessionDestroyed || _currentUser == null;
  }

  // Reset session state (for testing or manual reset)
  static void resetSessionState() {
    _isSessionDestroyed = false;
  }
} 