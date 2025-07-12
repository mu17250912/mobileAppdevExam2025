import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotificationCount = 0;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotificationCount => _unreadNotificationCount;

  NotificationProvider() {
    _listenNotifications();
  }

  void _listenNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _subscription = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        final notifs = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
          };
        }).toList();
        _notifications = notifs;
        _unreadNotificationCount = notifs.where((n) => n['read'] == false).length;
        notifyListeners();
      });
    }
  }

  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final unread = _notifications.where((n) => n['read'] == false).toList();
    for (final notif in unread) {
      await FirebaseFirestore.instance.collection('notifications').doc(notif['id']).update({'read': true});
    }
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
} 