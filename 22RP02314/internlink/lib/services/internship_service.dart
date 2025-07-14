import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/internship.dart';

class InternshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Post a new internship
  Future<void> postInternship(Internship internship) async {
    try {
      await _firestore.collection('internships').add(internship.toMap());
    } catch (e) {
      throw Exception('Failed to post internship: $e');
    }
  }

  // Get all active internships
  Stream<List<Internship>> getActiveInternships() {
    return _firestore
        .collection('internships')
        .where('status', isEqualTo: 'active')
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Internship.fromMap(data);
      }).toList();
    });
  }

  // Get internships posted by a specific company
  Stream<List<Internship>> getCompanyInternships(String companyId) {
    return _firestore
        .collection('internships')
        .where('companyId', isEqualTo: companyId)
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Internship.fromMap(data);
      }).toList();
    });
  }

  // Get a specific internship by ID
  Future<Internship?> getInternshipById(String internshipId) async {
    try {
      final doc = await _firestore.collection('internships').doc(internshipId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Internship.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get internship: $e');
    }
  }

  // Update internship status
  Future<void> updateInternshipStatus(String internshipId, String status) async {
    try {
      await _firestore.collection('internships').doc(internshipId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update internship status: $e');
    }
  }

  // Delete an internship
  Future<void> deleteInternship(String internshipId) async {
    try {
      await _firestore.collection('internships').doc(internshipId).delete();
    } catch (e) {
      throw Exception('Failed to delete internship: $e');
    }
  }

  // Search internships by partial, case-insensitive, multi-word match in title, filtering in Dart (no composite index needed)
  Stream<List<Internship>> searchInternships(String query) {
    final words = query.toLowerCase().split(' ').where((w) => w.isNotEmpty).toList();

    return _firestore
        .collection('internships')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Internship.fromMap(data);
      }).where((internship) {
        final title = internship.title.toLowerCase();
        return words.any((word) => title.contains(word));
      }).toList();
    });
  }

  // Filter internships by location, type, etc.
  Stream<List<Internship>> filterInternships({
    String? location,
    String? type,
    List<String>? skills,
  }) {
    Query query = _firestore
        .collection('internships')
        .where('status', isEqualTo: 'active');

    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }
    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }

    return query
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      List<Internship> internships = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Internship.fromMap(data);
      }).toList();

      // Filter by skills if provided
      if (skills != null && skills.isNotEmpty) {
        internships = internships.where((internship) {
          return skills.any((skill) => 
            internship.skills.any((internshipSkill) => 
              internshipSkill.toLowerCase().contains(skill.toLowerCase())
            )
          );
        }).toList();
      }

      return internships;
    });
  }
} 