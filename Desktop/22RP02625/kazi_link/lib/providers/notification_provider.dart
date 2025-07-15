import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class NotificationItem {
  final String id;
  final IconData icon;
  final String title;
  final String message;
  final String time;
  bool read;

  NotificationItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });
}

class NotificationProvider extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  late final String? _userId;
  late final CollectionReference _notifRef;
  StreamSubscription? _notifSub;

  NotificationProvider() {
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
    if (_userId == null) return;
    _notifRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('notifications');
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notifSub?.cancel();
    _notifSub = _notifRef.orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      _notifications.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _notifications.add(NotificationItem(
          id: doc.id,
          icon: IconData(data['icon'], fontFamily: 'MaterialIcons'),
          title: data['title'],
          message: data['message'],
          time: data['time'],
          read: data['read'] ?? false,
        ));
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  Future<void> removeNotification(String id) async {
    await _notifRef.doc(id).delete();
  }

  Future<void> markAllAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    for (var n in _notifications) {
      if (!n.read) {
        batch.update(_notifRef.doc(n.id), {'read': true});
      }
    }
    await batch.commit();
  }

  Future<void> addNotification(NotificationItem notification) async {
    await _notifRef.add({
      'icon': notification.icon.codePoint,
      'title': notification.title,
      'message': notification.message,
      'time': notification.time,
      'read': notification.read,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsUnread(String id) async {
    await _notifRef.doc(id).update({'read': false});
  }

  Future<void> markAsRead(String id) async {
    await _notifRef.doc(id).update({'read': true});
  }

  Future<void> addJobUpdateNotification(String jobTitle) async {
    await addNotification(NotificationItem(
      id: '',
      icon: Icons.bookmark,
      title: 'Job Update',
      message: 'There is a new update for your saved job: $jobTitle',
      time: 'Just now',
    ));
  }

  static Future<void> notifyAllWorkers(NotificationItem notification) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final workersQuery = await usersRef.where('role', isEqualTo: 'worker').get();
    for (var doc in workersQuery.docs) {
      final notifRef = usersRef.doc(doc.id).collection('notifications');
      await notifRef.add({
        'icon': notification.icon.codePoint,
        'title': notification.title,
        'message': notification.message,
        'time': notification.time,
        'read': notification.read,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> notifyApplicants(String jobId, NotificationItem notification) async {
    final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
    final applicants = List<String>.from(jobDoc['applicants'] ?? []);
    final usersRef = FirebaseFirestore.instance.collection('users');
    for (var userId in applicants) {
      final notifRef = usersRef.doc(userId).collection('notifications');
      await notifRef.add({
        'icon': notification.icon.codePoint,
        'title': notification.title,
        'message': notification.message,
        'time': notification.time,
        'read': notification.read,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> notifyJobPoster(String posterId, NotificationItem notification) async {
    final notifRef = FirebaseFirestore.instance.collection('users').doc(posterId).collection('notifications');
    await notifRef.add({
      'icon': notification.icon.codePoint,
      'title': notification.title,
      'message': notification.message,
      'time': notification.time,
      'read': notification.read,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
} 