class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  String? userId;
  String? userName;
  String? userRole;
  String premiumStatus = 'none';

  void setUser({required String id, required String name, required String role, String premiumStatus = 'none'}) {
    userId = id;
    userName = name;
    userRole = role;
    this.premiumStatus = premiumStatus;
  }

  void clear() {
    userId = null;
    userName = null;
    userRole = null;
    premiumStatus = 'none';
  }

  bool get isLoggedIn => userId != null;
  bool get isPremium => premiumStatus == 'approved';
} 