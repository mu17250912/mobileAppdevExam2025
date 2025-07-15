class SessionManager {
  static String? _role; // 'passenger' or 'driver'

  static String? get role => _role;

  static void setRole(String role) {
    _role = role;
  }

  static void clear() {
    _role = null;
  }
} 