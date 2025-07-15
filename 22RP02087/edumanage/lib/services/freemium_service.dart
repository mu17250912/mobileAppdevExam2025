import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FreemiumService {
  static const String _premiumStatusKey = 'premium_status';
  static const String _premiumUntilKey = 'premium_until';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Freemium limits for free users
  static const int freeStudentLimit = 10;
  static const int freeCourseLimit = 5;
  static const int freeAttendanceLimit = 50;
  static const int freeGradeLimit = 100;

  // Check if user has premium access
  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(_premiumStatusKey) ?? false;
    
    if (isPremium) {
      // Check if premium has expired
      final premiumUntil = prefs.getString(_premiumUntilKey);
      if (premiumUntil != null) {
        final expiryDate = DateTime.parse(premiumUntil);
        if (DateTime.now().isAfter(expiryDate)) {
          // Premium expired
          await setPremiumStatus(false);
          return false;
        }
      }
    }
    
    return isPremium;
  }

  // Set premium status (for testing or manual upgrades)
  Future<void> setPremiumStatus(bool isPremium, {DateTime? expiryDate}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumStatusKey, isPremium);
    
    if (expiryDate != null) {
      await prefs.setString(_premiumUntilKey, expiryDate.toIso8601String());
    }

    // Update Firestore
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'isPremium': isPremium,
        'premiumUntil': expiryDate?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Check if user can add more students
  Future<bool> canAddStudent() async {
    final isPremium = await this.isPremium();
    if (isPremium) return true;

    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _firestore
        .collection('students')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    return snapshot.docs.length < freeStudentLimit;
  }

  // Check if user can add more courses
  Future<bool> canAddCourse() async {
    final isPremium = await this.isPremium();
    if (isPremium) return true;

    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _firestore
        .collection('courses')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    return snapshot.docs.length < freeCourseLimit;
  }

  // Check if user can take more attendance
  Future<bool> canTakeAttendance() async {
    final isPremium = await this.isPremium();
    if (isPremium) return true;

    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _firestore
        .collection('attendance')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    return snapshot.docs.length < freeAttendanceLimit;
  }

  // Check if user can add more grades
  Future<bool> canAddGrade() async {
    final isPremium = await this.isPremium();
    if (isPremium) return true;

    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _firestore
        .collection('grades')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    return snapshot.docs.length < freeGradeLimit;
  }

  // Get current usage statistics
  Future<Map<String, dynamic>> getUsageStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final studentsSnapshot = await _firestore
        .collection('students')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    final coursesSnapshot = await _firestore
        .collection('courses')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    final attendanceSnapshot = await _firestore
        .collection('attendance')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    final gradesSnapshot = await _firestore
        .collection('grades')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    return {
      'students': {
        'used': studentsSnapshot.docs.length,
        'limit': freeStudentLimit,
        'remaining': freeStudentLimit - studentsSnapshot.docs.length,
      },
      'courses': {
        'used': coursesSnapshot.docs.length,
        'limit': freeCourseLimit,
        'remaining': freeCourseLimit - coursesSnapshot.docs.length,
      },
      'attendance': {
        'used': attendanceSnapshot.docs.length,
        'limit': freeAttendanceLimit,
        'remaining': freeAttendanceLimit - attendanceSnapshot.docs.length,
      },
      'grades': {
        'used': gradesSnapshot.docs.length,
        'limit': freeGradeLimit,
        'remaining': freeGradeLimit - gradesSnapshot.docs.length,
      },
    };
  }

  // Get feature limits for display
  Map<String, int> getFeatureLimits() {
    return {
      'students': freeStudentLimit,
      'courses': freeCourseLimit,
      'attendance': freeAttendanceLimit,
      'grades': freeGradeLimit,
    };
  }

  // Upgrade to premium (for testing or manual upgrades)
  Future<void> upgradeToPremium({int days = 30}) async {
    final expiryDate = DateTime.now().add(Duration(days: days));
    await setPremiumStatus(true, expiryDate: expiryDate);
  }

  // Downgrade to free
  Future<void> downgradeToFree() async {
    await setPremiumStatus(false);
  }
} 