import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesManager {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> addFavorite({
    required String title,
    required String fileUrl,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('favorites').add({
      'userId': user.uid,
      'title': title,
      'fileUrl': fileUrl,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> streamFavorites() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
