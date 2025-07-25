import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getQuestions(String categoryName) {
    return _db.collection('questions')
      .where('categoryId', isEqualTo: categoryName.toLowerCase())
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Fetch all questions for a category (one-time fetch)
  Future<List<Map<String, dynamic>>> fetchQuestionsByCategory(String category) async {
    final snapshot = await _db
        .collection('questions')
        .where('category', isEqualTo: category)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Fetch 10 random questions for a mock test (one-time fetch)
  Future<List<Map<String, dynamic>>> fetchMockTestQuestions(String category, {int limit = 10}) async {
    final snapshot = await _db
        .collection('questions')
        .where('category', isEqualTo: category)
        .get();
    final allQuestions = snapshot.docs.map((doc) => doc.data()).toList();
    allQuestions.shuffle();
    return allQuestions.take(limit).toList();
  }

  Future<void> updateUserProfile(String uid, {String? displayName, String? avatarUrl}) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
    }
  }

  // Update flagged questions for a user
  Future<void> updateFlaggedQuestions(String uid, List<String> flaggedQuestions) async {
    await _db.collection('users').doc(uid).update({'flaggedQuestions': flaggedQuestions});
  }

  // Get flagged questions for a user
  Future<List<String>> getFlaggedQuestions(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('flaggedQuestions')) {
      return List<String>.from(doc['flaggedQuestions']);
    }
    return [];
  }
} 