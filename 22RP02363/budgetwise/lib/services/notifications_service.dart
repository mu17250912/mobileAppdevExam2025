import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsService {
  static Future<void> sendNotification({
    required String title,
    required String body,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': user.uid,
      'title': title,
      'body': body,
      'date': FieldValue.serverTimestamp(),
    });
  }
} 