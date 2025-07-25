import 'package:flutter/material.dart';
import 'services/mock_database.dart';

class AppState extends ChangeNotifier {
  String? _currentUserEmail;
  List<Medication> _medications = [];
  final MockDatabase _db = MockDatabase();

  // Premium flag for simulated in-app purchase
  bool _isPremium = false;
  bool get isPremium => _isPremium;
  void setPremium(bool value) {
    _isPremium = value;
    notifyListeners();
  }

  String? get currentUserEmail => _currentUserEmail;
  List<Medication> get medications => _medications;

  void login(String email) {
    _currentUserEmail = email;
    _medications = _db.getMedications(email);
    notifyListeners();
  }

  void logout() {
    _currentUserEmail = null;
    _medications = [];
    _isPremium = false;
    notifyListeners();
  }

  void addMedication(Medication med) {
    if (_currentUserEmail != null) {
      _db.addMedication(_currentUserEmail!, med);
      _medications = _db.getMedications(_currentUserEmail!);
      notifyListeners();
    }
  }

  void updateMedication(int index, Medication med) {
    if (_currentUserEmail != null) {
      _db.updateMedication(_currentUserEmail!, index, med);
      _medications = _db.getMedications(_currentUserEmail!);
      notifyListeners();
    }
  }

  void deleteMedication(int index) {
    if (_currentUserEmail != null) {
      _db.deleteMedication(_currentUserEmail!, index);
      _medications = _db.getMedications(_currentUserEmail!);
      notifyListeners();
    }
  }

  void refreshMedications() {
    if (_currentUserEmail != null) {
      _medications = _db.getMedications(_currentUserEmail!);
      notifyListeners();
    }
  }
}
