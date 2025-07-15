class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<int> insertUser(Map<String, dynamic> user) async {
    throw UnsupportedError('SQLite is not supported on the web.');
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    throw UnsupportedError('SQLite is not supported on the web.');
  }

  Future close() async {}
} 