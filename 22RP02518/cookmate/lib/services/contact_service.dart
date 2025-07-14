import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  final _firestore = FirebaseFirestore.instance;
  final String collection = 'contact_requests';

  Future<void> sendContactRequest(String userId, String chefId) async {
    await _firestore.collection(collection).add({
      'userId': userId,
      'chefId': chefId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ContactRequest>> getContactRequestsForChef(String chefId) {
    return _firestore
        .collection(collection)
        .where('chefId', isEqualTo: chefId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ContactRequest(
              userId: doc['userId'],
              chefId: doc['chefId'],
              status: _statusFromString(doc['status']),
              timestamp: (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              docId: doc.id,
            )).toList());
  }

  Stream<List<ContactRequest>> getContactRequestsForUser(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ContactRequest(
              userId: doc['userId'],
              chefId: doc['chefId'],
              status: _statusFromString(doc['status']),
              timestamp: (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              docId: doc.id,
            )).toList());
  }

  Future<void> updateContactRequestStatus(String requestId, ContactRequestStatus status) async {
    await _firestore.collection(collection).doc(requestId).update({
      'status': status.name,
    });
  }

  ContactRequestStatus _statusFromString(String status) {
    switch (status) {
      case 'approved':
        return ContactRequestStatus.approved;
      case 'rejected':
        return ContactRequestStatus.rejected;
      default:
        return ContactRequestStatus.pending;
    }
  }
} 