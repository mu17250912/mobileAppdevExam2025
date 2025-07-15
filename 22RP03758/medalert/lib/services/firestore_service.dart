import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medalert/models/user.dart';
import 'package:medalert/models/medication.dart';
import 'package:medalert/models/medication_log.dart';
import 'package:medalert/models/caregiver_assignment.dart';
import 'package:medalert/models/emergency_contact.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Management
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()! as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Medication Management
  Future<String> addMedication(MedicationModel medication) async {
    try {
      final docRef = await _firestore.collection('medications').add(medication.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding medication: $e');
      rethrow;
    }
  }

  Future<List<MedicationModel>> getMedications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('medications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MedicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting medications: $e');
      return [];
    }
  }

  Future<void> updateMedication(String medicationId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('medications').doc(medicationId).update(data);
    } catch (e) {
      print('Error updating medication: $e');
      rethrow;
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await _firestore.collection('medications').doc(medicationId).delete();
    } catch (e) {
      print('Error deleting medication: $e');
      rethrow;
    }
  }

  // Medication Log Management
  Future<void> addMedicationLog(MedicationLogModel log) async {
    try {
      await _firestore.collection('medication_logs').add(log.toMap());
    } catch (e) {
      print('Error adding medication log: $e');
      rethrow;
    }
  }

  Future<List<MedicationLogModel>> getMedicationLogs(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore
          .collection('medication_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => MedicationLogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting medication logs: $e');
      return [];
    }
  }

  // Caregiver Assignment Management
  Future<void> createCaregiverAssignment(CaregiverAssignmentModel assignment) async {
    try {
      await _firestore.collection('caregiver_assignments').add(assignment.toMap());
    } catch (e) {
      print('Error creating caregiver assignment: $e');
      rethrow;
    }
  }

  Future<List<CaregiverAssignmentModel>> getCaregiverAssignments(String caregiverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('caregiver_assignments')
          .where('caregiverId', isEqualTo: caregiverId)
          .get();

      return querySnapshot.docs
          .map((doc) => CaregiverAssignmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting caregiver assignments: $e');
      return [];
    }
  }

  Future<CaregiverAssignmentModel?> getPatientAssignment(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('caregiver_assignments')
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return CaregiverAssignmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting patient assignment: $e');
      return null;
    }
  }

  // Emergency Contacts Management
  Future<void> addEmergencyContact(EmergencyContactModel contact) async {
    try {
      await _firestore.collection('emergency_contacts').add(contact.toMap());
    } catch (e) {
      print('Error adding emergency contact: $e');
      rethrow;
    }
  }

  Future<List<EmergencyContactModel>> getEmergencyContacts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('emergency_contacts')
          .where('userId', isEqualTo: userId)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => EmergencyContactModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting emergency contacts: $e');
      return [];
    }
  }

  Future<void> updateEmergencyContact(String contactId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('emergency_contacts').doc(contactId).update(data);
    } catch (e) {
      print('Error updating emergency contact: $e');
      rethrow;
    }
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      await _firestore.collection('emergency_contacts').doc(contactId).delete();
    } catch (e) {
      print('Error deleting emergency contact: $e');
      rethrow;
    }
  }

  // Analytics Data
  Future<void> saveAnalyticsData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('analytics').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        ...data,
      });
    } catch (e) {
      print('Error saving analytics data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAnalyticsData(String userId, {int limit = 30}) async {
    try {
      final querySnapshot = await _firestore
          .collection('analytics')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting analytics data: $e');
      return [];
    }
  }

  // App Usage Tracking
  Future<void> trackAppUsage(String userId, Map<String, dynamic> usageData) async {
    try {
      await _firestore.collection('app_usage').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        ...usageData,
      });
    } catch (e) {
      print('Error tracking app usage: $e');
    }
  }

  // Real-time Updates
  Stream<QuerySnapshot> getMedicationLogsStream(String userId) {
    return _firestore
        .collection('medication_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  Stream<QuerySnapshot> getCaregiverAssignmentsStream(String caregiverId) {
    return _firestore
        .collection('caregiver_assignments')
        .where('caregiverId', isEqualTo: caregiverId)
        .snapshots();
  }

  // Batch Operations
  Future<void> batchUpdateMedicationLogs(List<MedicationLogModel> logs) async {
    try {
      final batch = _firestore.batch();
      
      for (final log in logs) {
        final docRef = _firestore.collection('medication_logs').doc();
        batch.set(docRef, log.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error batch updating medication logs: $e');
      rethrow;
    }
  }

  // Data Export
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final user = await getUser(userId);
      final medications = await getMedications(userId);
      final logs = await getMedicationLogs(userId);
      final contacts = await getEmergencyContacts(userId);
      final assignment = await getPatientAssignment(userId);

      return {
        'user': user?.toMap(),
        'medications': medications.map((m) => m.toMap()).toList(),
        'medication_logs': logs.map((l) => l.toMap()).toList(),
        'emergency_contacts': contacts.map((c) => c.toMap()).toList(),
        'caregiver_assignment': assignment?.toMap(),
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error exporting user data: $e');
      rethrow;
    }
  }
} 