import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? imageUrl;
  final bool read;
  final DateTime? timestamp;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.imageUrl,
    required this.read,
    this.timestamp,
  });

  factory NotificationItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationItem(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'info',
      imageUrl: data['imageUrl'],
      read: data['read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

class NotificationsManager {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> add({
    required String title,
    required String message,
    String type = 'info',
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Cannot add notification: user not logged in');
      return;
    }
    await _firestore.collection('notifications').add({
      'userId': user.uid,
      'title': title,
      'message': message,
      'type': type,
      'imageUrl': imageUrl,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<NotificationItem>> stream({String? filterType, bool? unreadOnly}) {
    final user = _auth.currentUser;
    if (user == null) {
      print('NotificationsManager.stream: user is null, returning empty stream');
      return const Stream.empty();
    }
    Query query = _firestore
        .collection('notifications');
    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType);
    }
    if (unreadOnly == true) {
      query = query.where('read', isEqualTo: false);
    }
    query = query.orderBy('timestamp', descending: true);
    return query.snapshots().map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        try {
          return NotificationItem.fromDoc(doc);
        } catch (e) {
          print('Error parsing notification doc ${doc.id}: $e');
          return null;
        }
      }).whereType<NotificationItem>().toList();
      print('NotificationsManager.stream: fetched ${notifications.length} notifications');
      return notifications;
    });
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({'read': true});
    } catch (e) {
      print('Failed to mark notification $notificationId as read: $e');
    }
  }

  static Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final batch = _firestore.batch();
    final query = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
