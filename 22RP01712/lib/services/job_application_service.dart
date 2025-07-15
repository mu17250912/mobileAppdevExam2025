import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class JobApplicationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a user has already applied to a specific job
  static Future<bool> hasUserApplied(String jobId, String userId) async {
    try {
      final applicationDoc = await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .doc(userId)
          .get();
      
      return applicationDoc.exists;
    } catch (e) {
      print('Error checking application status: $e');
      return false;
    }
  }

  /// Submit a job application
  static Future<bool> submitApplication({
    required String jobId,
    required AppUser user,
    required String coverLetter,
    required String jobTitle,
    required String company,
  }) async {
    try {
      // Final check to prevent race conditions
      final currentApplication = await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .doc(user.id)
          .get();
      
      if (currentApplication.exists) {
        return false; // User has already applied
      }

      // Create application document
      await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .doc(user.id)
          .set({
        'userId': user.id,
        'userName': user.fullName,
        'userEmail': user.email,
        'coverLetter': coverLetter,
        'appliedAt': FieldValue.serverTimestamp(),
        'jobId': jobId,
        'jobTitle': jobTitle,
        'company': company,
        'status': 'pending', // pending, reviewed, accepted, rejected
      });

      // Update job applicants list
      await _firestore
          .collection('jobs')
          .doc(jobId)
          .update({
        'applicants': FieldValue.arrayUnion([user.id])
      });

      return true;
    } catch (e) {
      print('Error submitting application: $e');
      return false;
    }
  }

  /// Get all applications for a specific job
  static Future<List<Map<String, dynamic>>> getJobApplications(String jobId) async {
    try {
      final applicationsSnapshot = await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .orderBy('appliedAt', descending: true)
          .get();
      
      return applicationsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting job applications: $e');
      return [];
    }
  }

  /// Get all applications by a specific user
  static Future<List<Map<String, dynamic>>> getUserApplications(String userId) async {
    try {
      final applicationsSnapshot = await _firestore
          .collectionGroup('applications')
          .where('userId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .get();
      
      return applicationsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting user applications: $e');
      return [];
    }
  }

  /// Update application status (for admin use)
  static Future<bool> updateApplicationStatus({
    required String jobId,
    required String userId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .doc(userId)
          .update({
        'status': status,
        'adminNotes': adminNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error updating application status: $e');
      return false;
    }
  }

  /// Delete an application (for admin use or user withdrawal)
  static Future<bool> deleteApplication(String jobId, String userId) async {
    try {
      await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .doc(userId)
          .delete();

      // Remove from job applicants list
      await _firestore
          .collection('jobs')
          .doc(jobId)
          .update({
        'applicants': FieldValue.arrayRemove([userId])
      });
      
      return true;
    } catch (e) {
      print('Error deleting application: $e');
      return false;
    }
  }
} 