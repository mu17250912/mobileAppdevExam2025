import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a notification when a new purchase request is submitted
  static Future<void> createPurchaseRequestNotification({
    required String requestId,
    required String buyerName,
    required String propertyTitle,
    required String offer,
  }) async {
    await _firestore.collection('notifications').add({
      'type': 'new_purchase_request',
      'requestId': requestId,
      'buyerName': buyerName,
      'propertyTitle': propertyTitle,
      'offer': offer,
      'message': '$buyerName submitted a purchase request for $propertyTitle with offer \$$offer',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Create a notification when payment is made
  static Future<void> createPaymentNotification({
    required String requestId,
    required String buyerName,
    required String propertyTitle,
  }) async {
    await _firestore.collection('notifications').add({
      'type': 'payment_received',
      'requestId': requestId,
      'buyerName': buyerName,
      'propertyTitle': propertyTitle,
      'message': '$buyerName paid the connection fee for $propertyTitle',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Create a notification when buyer is connected
  static Future<void> createConnectionNotification({
    required String requestId,
    required String buyerName,
    required String propertyTitle,
  }) async {
    await _firestore.collection('notifications').add({
      'type': 'buyer_connected',
      'requestId': requestId,
      'buyerName': buyerName,
      'propertyTitle': propertyTitle,
      'message': '$buyerName has been connected with the owner of $propertyTitle',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Get unread notifications count
  static Stream<int> getUnreadCount() {
    return _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get all notifications
  static Stream<QuerySnapshot> getAllNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
} 