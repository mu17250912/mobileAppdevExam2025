import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // --- Workout Plan ---
  static Future<void> saveWorkoutPlan(String userId, String day, List<Map<String, dynamic>> workouts) async {
    await _db.collection('users').doc(userId).collection('workout_plans').doc(day).set({
      'workouts': workouts,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getWorkoutPlan(String userId, String day) async {
    final doc = await _db.collection('users').doc(userId).collection('workout_plans').doc(day).get();
    if (doc.exists && doc.data() != null) {
      return List<Map<String, dynamic>>.from(doc['workouts'] ?? []);
    }
    return [];
  }

  // --- Progress Tracker ---
  static Future<void> addProgressEntry(String userId, Map<String, dynamic> entry) async {
    await _db.collection('users').doc(userId).collection('progress').add(entry);
  }

  static Stream<List<Map<String, dynamic>>> progressEntriesStream(String userId) {
    return _db.collection('users').doc(userId).collection('progress')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // --- Water Intake ---
  static Future<void> addWaterEntry(String userId, Map<String, dynamic> entry) async {
    await _db.collection('users').doc(userId).collection('water').add(entry);
  }

  static Stream<List<Map<String, dynamic>>> waterEntriesStream(String userId) {
    return _db.collection('users').doc(userId).collection('water')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  static Future<void> setWaterReminder(String userId, bool enabled, String time) async {
    await _db.collection('users').doc(userId).set({'water_reminder': {'enabled': enabled, 'time': time}}, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getWaterReminder(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data()?['water_reminder'];
  }

  // --- Calorie & Nutrition ---
  static Future<void> addFoodEntry(String userId, String date, Map<String, dynamic> food) async {
    await _db.collection('users').doc(userId).collection('calories').doc(date).collection('foods').add(food);
  }

  static Stream<List<Map<String, dynamic>>> foodEntriesStream(String userId, String date) {
    return _db.collection('users').doc(userId).collection('calories').doc(date).collection('foods')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  static Future<void> setCalorieGoal(String userId, int goal) async {
    await _db.collection('users').doc(userId).set({'calorie_goal': goal}, SetOptions(merge: true));
  }

  static Future<int?> getCalorieGoal(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data()?['calorie_goal'];
  }

  // --- Profile ---
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> profile) async {
    await _db.collection('users').doc(userId).set(profile, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }
} 