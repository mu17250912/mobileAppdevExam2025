import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bmi_entry.dart';

class BMIFirebaseService {
  // Returns a reference to the user's entries subcollection
  CollectionReference<Map<String, dynamic>> _userEntriesCollection(String userId) {
    return FirebaseFirestore.instance.collection('bmi_records').doc(userId).collection('entries');
  }

  Future<void> addEntry(BMIEntry entry, String userId, double weight, double height) async {
    // Ensure parent document exists
    final parentDoc = FirebaseFirestore.instance.collection('bmi_records').doc(userId);
    await parentDoc.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    // Now add to subcollection
    await parentDoc.collection('entries').add({
      'bmi': entry.bmi,
      'category': entry.category,
      'date': entry.date.toIso8601String(),
      'weight': weight,
      'height': height,
    });
  }

  Future<List<BMIEntry>> getUserEntries(String userId) async {
    final querySnapshot = await _userEntriesCollection(userId)
        .orderBy('date', descending: true)
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return BMIEntry.fromJson(data, id: doc.id);
    }).toList();
  }

  /// Returns all BMI records for a user as a list of maps (raw Firestore data)
  Future<List<Map<String, dynamic>>> getUserBMIRecordsRaw(String userId) async {
    final querySnapshot = await _userEntriesCollection(userId)
        .orderBy('date', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  // Delete a single entry by document ID
  Future<void> deleteEntry(String userId, String entryId) async {
    await _userEntriesCollection(userId).doc(entryId).delete();
  }

  // Delete all entries for a user
  Future<void> deleteAllEntries(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final entriesSnapshot = await _userEntriesCollection(userId).get();
    for (final doc in entriesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
} 