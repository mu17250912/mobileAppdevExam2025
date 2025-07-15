class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal();

  // User data: {email: password}
  final Map<String, String> _users = {};
  // Medication data: {email: List<Medication>}
  final Map<String, List<Medication>> _medications = {};

  // Register user
  bool registerUser(String email, String password) {
    if (_users.containsKey(email)) return false;
    _users[email] = password;
    _medications[email] = [];
    return true;
  }

  // Authenticate user
  bool authenticateUser(String email, String password) {
    return _users[email] == password;
  }

  // Add medication
  void addMedication(String email, Medication med) {
    _medications[email]?.add(med);
  }

  // Update medication at index
  void updateMedication(String email, int index, Medication updatedMed) {
    if (_medications[email] != null && index < _medications[email]!.length) {
      _medications[email]![index] = updatedMed;
    }
  }

  // Delete medication at index
  void deleteMedication(String email, int index) {
    if (_medications[email] != null && index < _medications[email]!.length) {
      _medications[email]!.removeAt(index);
    }
  }

  // Get medications for user
  List<Medication> getMedications(String email) {
    return _medications[email] ?? [];
  }

  // Mark medication as taken
  void markMedicationAsTaken(String email, int index) {
    if (_medications[email] != null && index < _medications[email]!.length) {
      _medications[email]![index].status = 'taken';
    }
  }

  // Mark medication as missed
  void markMedicationAsMissed(String email, int index) {
    if (_medications[email] != null && index < _medications[email]!.length) {
      _medications[email]![index].status = 'missed';
    }
  }
}

class Medication {
  String name;
  String dosage;
  String frequency;
  String time;
  String status; // 'pending', 'taken', 'missed'

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    this.status = 'pending',
  });
}