import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'app_service.dart';

class NavigationService extends ChangeNotifier {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentIndex = 0;
  int _notificationBadgeCount = 0;
  int _chatBadgeCount = 0;
  int _sessionBadgeCount = 0;
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  StreamSubscription<QuerySnapshot>? _sessionSubscription;

  // Getters
  int get currentIndex => _currentIndex;
  int get notificationBadgeCount => _notificationBadgeCount;
  int get chatBadgeCount => _chatBadgeCount;
  int get sessionBadgeCount => _sessionBadgeCount;
  int get totalBadgeCount =>
      _notificationBadgeCount + _chatBadgeCount + _sessionBadgeCount;

  // Initialize the service
  void initialize() {
    _setupNotificationListener();
    _setupChatListener();
    _setupSessionListener();
  }

  // Dispose resources
  void dispose() {
    _notificationSubscription?.cancel();
    _chatSubscription?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }

  // Set current navigation index
  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // Setup notification listener for badge count
  void _setupNotificationListener() {
    final user = _auth.currentUser;
    if (user != null) {
      _notificationSubscription =
          AppService.listenToNotifications(user.uid).listen((notifications) {
        final unreadCount = notifications.where((n) => !n.isRead).length;
        if (_notificationBadgeCount != unreadCount) {
          _notificationBadgeCount = unreadCount;
          notifyListeners();
        }
      });
    }
  }

  // Setup chat listener for badge count
  void _setupChatListener() {
    final user = _auth.currentUser;
    if (user != null) {
      _chatSubscription = _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        final unreadMessages = snapshot.docs.length;
        if (_chatBadgeCount != unreadMessages) {
          _chatBadgeCount = unreadMessages;
          notifyListeners();
        }
      });
    }
  }

  // Setup session listener for badge count
  void _setupSessionListener() {
    final user = _auth.currentUser;
    if (user != null) {
      _sessionSubscription = _firestore
          .collection('sessions')
          .where('participants', arrayContains: user.uid)
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('scheduledAt',
              isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .snapshots()
          .listen((snapshot) {
            final upcomingSessions = snapshot.docs.length;
            if (_sessionBadgeCount != upcomingSessions) {
              _sessionBadgeCount = upcomingSessions;
              notifyListeners();
            }
          });
    }
  }

  // Reset badge counts
  void resetNotificationBadge() {
    _notificationBadgeCount = 0;
    notifyListeners();
  }

  void resetChatBadge() {
    _chatBadgeCount = 0;
    notifyListeners();
  }

  void resetSessionBadge() {
    _sessionBadgeCount = 0;
    notifyListeners();
  }

  // Get badge count for specific tab
  int getBadgeCountForTab(int tabIndex) {
    switch (tabIndex) {
      case 0: // Home
        return _sessionBadgeCount;
      case 1: // Search
        return 0;
      case 2: // Alerts
        return _notificationBadgeCount;
      case 3: // Messenger
        return _chatBadgeCount;
      case 4: // Add Skills
        return 0;
      case 5: // Profile
        return 0;
      default:
        return 0;
    }
  }

  // Check if any tab has badges
  bool get hasAnyBadges => totalBadgeCount > 0;

  // Get badge text for display
  String getBadgeText(int count) {
    if (count <= 0) return '';
    if (count > 99) return '99+';
    return count.toString();
  }

  // Update badge counts manually (for testing or manual updates)
  void updateNotificationBadge(int count) {
    _notificationBadgeCount = count;
    notifyListeners();
  }

  void updateChatBadge(int count) {
    _chatBadgeCount = count;
    notifyListeners();
  }

  void updateSessionBadge(int count) {
    _sessionBadgeCount = count;
    notifyListeners();
  }
}
