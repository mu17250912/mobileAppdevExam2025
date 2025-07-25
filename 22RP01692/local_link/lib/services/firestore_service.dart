import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User Management
  Future<void> saveUserEmail(String email) async {
    try {
      await _db.collection('users').doc(email).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      print('Failed to save user email: ${e.message}');
    }
  }

  // Booking Management
  Future<void> saveBooking(Map<String, dynamic> booking) async {
    try {
      await _db.collection('bookings').add(booking);
    } on FirebaseException catch (e) {
      print('Failed to save booking: ${e.message}');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      print('Failed to update booking status: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          // .orderBy('createdAt', descending: true) // Removed to avoid index
          .get();
      var docs = snapshot.docs;
      // Sort in Dart if needed
      docs.sort((a, b) => (b.data()['createdAt'] ?? '').toString().compareTo((a.data()['createdAt'] ?? '').toString()));
      return docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      print('Failed to get user bookings: ${e.message}');
      return [];
    }
  }

  // Provider Management
  Future<void> updateProviderAvailability(String providerId, DateTime dateTime, bool isAvailable) async {
    try {
      await _db.collection('providers').doc(providerId).collection('availability').doc(dateTime.toIso8601String()).set({
        'dateTime': dateTime.toIso8601String(),
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      print('Failed to update provider availability: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyProviders(double lat, double lng, double radius) async {
    try {
      final snapshot = await _db.collection('providers').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      print('Failed to get nearby providers: ${e.message}');
      return [];
    }
  }

  // Reviews and Ratings
  Future<void> saveReview(String bookingId, Map<String, dynamic> review) async {
    try {
      await _db.collection('bookings').doc(bookingId).collection('reviews').add({
        ...review,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      print('Failed to save review: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getProviderReviews(String providerId) async {
    try {
      final snapshot = await _db
          .collection('providers')
          .doc(providerId)
          .collection('reviews')
          // .orderBy('createdAt', descending: true) // Removed to avoid index
          .get();
      var docs = snapshot.docs;
      // Sort in Dart if needed
      docs.sort((a, b) => (b.data()['createdAt'] ?? '').toString().compareTo((a.data()['createdAt'] ?? '').toString()));
      return docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      print('Failed to get provider reviews: ${e.message}');
      return [];
    }
  }

  // Notifications
  Future<void> saveNotification(String userId, Map<String, dynamic> notification) async {
    try {
      await _db.collection('users').doc(userId).collection('notifications').add({
        ...notification,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } on FirebaseException catch (e) {
      print('Failed to save notification: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          // .orderBy('createdAt', descending: true) // Removed to avoid index
          .limit(50)
          .get();
      var docs = snapshot.docs;
      // Sort in Dart if needed
      docs.sort((a, b) => (b.data()['createdAt'] ?? '').toString().compareTo((a.data()['createdAt'] ?? '').toString()));
      return docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      print('Failed to get user notifications: ${e.message}');
      return [];
    }
  }

  // Booking Statistics
  Future<Map<String, dynamic>> getBookingStats(String userId) async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();
      final bookings = snapshot.docs;
      final total = bookings.length;
      final completed = bookings.where((doc) => doc.data()['status'] == 'completed').length;
      final pending = bookings.where((doc) => doc.data()['status'] == 'pending').length;
      return {
        'total': total,
        'completed': completed,
        'pending': pending,
      };
    } on FirebaseException catch (e) {
      print('Failed to get booking stats: ${e.message}');
      return {'total': 0, 'completed': 0, 'pending': 0};
    }
  }

  // Real-time booking updates
  Stream<QuerySnapshot> getBookingUpdates(String userId) {
    // Streams can't be wrapped in try-catch, but handle errors in the UI
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        // .orderBy('createdAt', descending: true) // Removed to avoid index
        .snapshots();
  }
} 