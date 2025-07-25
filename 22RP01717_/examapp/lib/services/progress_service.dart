import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressService {
  static const _progressKey = 'user_progress';
  static const _mockTestKey = 'mock_test_scores';

  // Save question progress (attempted/correct per category) to Firestore and local
  Future<void> saveProgress(Map<String, dynamic> progress) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_progressKey, jsonEncode(progress));
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'progress': progress,
      }, SetOptions(merge: true));
    }
  }

  // Load question progress from Firestore, fallback to local
  Future<Map<String, dynamic>> loadProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('progress')) {
        final data = doc['progress'];
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
      }
    }
    // fallback to local
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_progressKey);
    if (data == null) return {};
    return jsonDecode(data);
  }

  // Save mock test score to Firestore and local
  Future<void> saveMockTestScore(String category, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_mockTestKey);
    Map<String, List<int>> scores = {};
    if (data != null) {
      final decoded = jsonDecode(data);
      decoded.forEach((k, v) => scores[k] = List<int>.from(v));
    }
    scores.putIfAbsent(category, () => []);
    scores[category]!.add(score);
    prefs.setString(_mockTestKey, jsonEncode(scores));
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Store as a map of category to list of scores
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'mockTestScores': scores,
      }, SetOptions(merge: true));
    }
  }

  // Load mock test scores from Firestore, fallback to local
  Future<Map<String, List<int>>> loadMockTestScores() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('mockTestScores')) {
        final data = doc['mockTestScores'];
        if (data is Map<String, dynamic>) {
          return data.map((k, v) => MapEntry(k, List<int>.from(v)));
        }
        if (data is Map) {
          return Map<String, List<int>>.from(data.map((k, v) => MapEntry(k, List<int>.from(v))));
        }
      }
    }
    // fallback to local
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_mockTestKey);
    if (data == null) return {};
    final decoded = jsonDecode(data);
    return decoded.map<String, List<int>>((k, v) => MapEntry(k, List<int>.from(v)));
  }
} 