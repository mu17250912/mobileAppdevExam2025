import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  // CREATE
  Future<void> addMedication(Map<String, dynamic> medData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .add(medData);
  }

  // CREATE and return DocumentReference
  Future<DocumentReference> addMedicationWithRef(Map<String, dynamic> medData) async {
    return await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .add(medData);
  }

  // READ (stream for real-time updates)
  Stream<QuerySnapshot> getMedications() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .snapshots();
  }

  // UPDATE
  Future<void> updateMedication(String medId, Map<String, dynamic> medData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .update(medData);
  }

  // DELETE
  Future<void> deleteMedication(String medId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .delete();
  }
} 