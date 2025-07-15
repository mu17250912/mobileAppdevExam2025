import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/application.dart';
import '../models/internship.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit a new application
  Future<void> submitApplication(Application application) async {
    try {
      // Add application to applications collection
      await _firestore.collection('applications').add(application.toMap());
      
      // Update internship application count
      await _firestore.collection('internships').doc(application.internshipId).update({
        'currentApplications': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  // Get applications for a specific student
  Stream<List<Application>> getStudentApplications(String studentId) {
    return _firestore
        .collection('applications')
        .where('studentId', isEqualTo: studentId)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Application.fromMap(data);
      }).toList();
    });
  }

  // Get applications for a specific internship
  Stream<List<Application>> getInternshipApplications(String internshipId) {
    return _firestore
        .collection('applications')
        .where('internshipId', isEqualTo: internshipId)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Application.fromMap(data);
      }).toList();
    });
  }

  // Get applications for internships posted by a company
  Stream<List<Application>> getCompanyApplications(String companyId) {
    return _firestore
        .collection('applications')
        .where('companyId', isEqualTo: companyId)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Application.fromMap(data);
      }).toList();
    });
  }

  // Get a specific application by ID
  Future<Application?> getApplicationById(String applicationId) async {
    try {
      final doc = await _firestore.collection('applications').doc(applicationId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Application.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get application: $e');
    }
  }

  // Update application status
  Future<void> updateApplicationStatus(String applicationId, String status, {String? feedback}) async {
    try {
      final updateData = {
        'status': status,
        'reviewedDate': DateTime.now().toIso8601String(),
        'reviewedBy': _auth.currentUser?.uid,
      };
      
      if (feedback != null) {
        updateData['feedback'] = feedback;
      }
      
      await _firestore.collection('applications').doc(applicationId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  // Withdraw an application
  Future<void> withdrawApplication(String applicationId) async {
    try {
      await _firestore.collection('applications').doc(applicationId).update({
        'status': 'withdrawn',
        'reviewedDate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to withdraw application: $e');
    }
  }

  // Check if student has already applied to an internship
  Future<bool> hasStudentApplied(String studentId, String internshipId) async {
    try {
      final query = await _firestore
          .collection('applications')
          .where('studentId', isEqualTo: studentId)
          .where('internshipId', isEqualTo: internshipId)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check application status: $e');
    }
  }

  // Get application statistics for a company
  Future<Map<String, int>> getApplicationStats(String companyId) async {
    try {
      final applications = await _firestore
          .collection('applications')
          .where('companyId', isEqualTo: companyId)
          .get();
      
      int pending = 0;
      int approved = 0;
      int rejected = 0;
      
      for (var doc in applications.docs) {
        final status = doc.data()['status'] as String;
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }
      
      return {
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'total': applications.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get application statistics: $e');
    }
  }

  // Permanently delete an application
  Future<void> deleteApplication(String applicationId) async {
    try {
      await _firestore.collection('applications').doc(applicationId).delete();
    } catch (e) {
      throw Exception('Failed to delete application: $e');
    }
  }
} 