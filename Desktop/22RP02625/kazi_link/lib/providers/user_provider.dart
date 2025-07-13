import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String? _role;
  Set<String> _appliedJobIds = {};
  Set<String> _savedJobIds = {};
  bool _isPremium = false;
  String? _userId;

  UserProvider() {
    _init();
    _loadAppliedJobs();
    _loadSavedJobs();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
    if (_userId != null) {
      await _loadPremiumStatus();
    }
  }

  String? get role => _role;
  Set<String> get appliedJobIds => _appliedJobIds;
  Set<String> get savedJobIds => _savedJobIds;
  bool get isPremium => _isPremium;
  String? get userId => _userId;

  void setRole(String? newRole) {
    _role = newRole;
    notifyListeners();
  }

  Future<void> _loadAppliedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('applied_jobs') ?? [];
    _appliedJobIds = ids.toSet();
    notifyListeners();
  }

  Future<void> _saveAppliedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('applied_jobs', _appliedJobIds.toList());
  }

  bool hasApplied(String jobId) => _appliedJobIds.contains(jobId);

  static const int freeApplicationLimit = 3;

  Future<bool> applyForJob(String jobId) async {
    if (!_appliedJobIds.contains(jobId)) {
      if (!_isPremium && _appliedJobIds.length >= freeApplicationLimit) {
        // Limit reached for free users
        return false;
      }
      _appliedJobIds.add(jobId);
      await _saveAppliedJobs();
      notifyListeners();
      // Notify job poster
      final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
      final posterId = jobDoc['posterId'];
      await NotificationProvider.notifyJobPoster(
        posterId,
        NotificationItem(
          id: '',
          icon: Icons.person,
          title: 'New Application',
          message: 'Someone applied for your job!',
          time: 'Just now',
        ),
      );
      return true;
    }
    return true;
  }

  Future<void> withdrawApplication(String jobId) async {
    if (_appliedJobIds.contains(jobId)) {
      _appliedJobIds.remove(jobId);
      await _saveAppliedJobs();
      notifyListeners();
    }
  }

  void clearAppliedJobs() async {
    _appliedJobIds.clear();
    await _saveAppliedJobs();
    notifyListeners();
  }

  Future<void> _loadSavedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('saved_jobs') ?? [];
    _savedJobIds = ids.toSet();
    notifyListeners();
  }

  Future<void> _saveSavedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_jobs', _savedJobIds.toList());
  }

  bool isJobSaved(String jobId) => _savedJobIds.contains(jobId);

  Future<void> saveJob(String jobId) async {
    if (!_savedJobIds.contains(jobId)) {
      _savedJobIds.add(jobId);
      await _saveSavedJobs();
      notifyListeners();
    }
  }

  Future<void> unsaveJob(String jobId) async {
    if (_savedJobIds.contains(jobId)) {
      _savedJobIds.remove(jobId);
      await _saveSavedJobs();
      notifyListeners();
    }
  }

  void clearSavedJobs() async {
    _savedJobIds.clear();
    await _saveSavedJobs();
    notifyListeners();
  }

  Future<void> _loadPremiumStatus() async {
    if (_userId == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
    _isPremium = (doc.data()?['premium'] ?? false) as bool;
    notifyListeners();
  }

  Future<void> setPremiumStatus(bool value) async {
    if (_userId == null) return;
    await FirebaseFirestore.instance.collection('users').doc(_userId).update({'premium': value});
    _isPremium = value;
    notifyListeners();
  }
} 