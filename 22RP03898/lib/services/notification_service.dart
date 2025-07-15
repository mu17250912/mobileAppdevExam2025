import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final Logger _logger = Logger();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Only initialize FCM on supported platforms
    if (kIsWeb) {
      try {
        // Try to register service worker for web push
        await _messaging.requestPermission();
        // You may want to check if service worker is available
        // Optionally, add more web-specific logic here
      } catch (e) {
        _logger.w(
            'Web push notifications not available (service worker missing or not supported). Skipping web push setup.');
        return;
      }
    }
    try {
      // Initialize local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permission for push notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveFCMToken(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveFCMToken);

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      }
    } catch (e) {
      _logger.e('Error initializing notification service', error: e);
      // Optionally, show a user-friendly message or ignore if notifications are not critical
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      _logger.e('Error saving FCM token', error: e);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      // Show local notification
      await _showLocalNotification(
        title: message.notification?.title ?? 'SafeRide',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    } catch (e) {
      _logger.e('Error handling foreground message', error: e);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Handle notification tap - navigate to appropriate screen
    final data = message.data;
    if (data['type'] == 'new_booking') {
      // Navigate to booking details
      _logger.i('Navigate to booking: ${data['bookingId']}');
    } else if (data['type'] == 'booking_confirmed') {
      // Navigate to booking details
      _logger.i('Navigate to confirmed booking: ${data['bookingId']}');
    } else if (data['type'] == 'ride_completed') {
      // Navigate to rating screen
      _logger.i('Navigate to rating screen: ${data['bookingId']}');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle local notification tap
    _logger.i('Local notification tapped: ${response.payload}');
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'saferide_channel',
      'SafeRide Notifications',
      channelDescription: 'Notifications for SafeRide app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: data,
    );
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return;
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];

      if (fcmToken == null) {
        return;
      }

      // Save notification to Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });

      // Send push notification (in a real app, you'd use a server)
      // For now, we'll just show a local notification
      await _showLocalNotification(
        title: title,
        body: body,
        payload: data?.toString(),
      );
    } catch (e) {
      _logger.e('Error sending notification', error: e);
    }
  }

  Future<void> sendRideNotification({
    required String rideId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get ride details
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return;

      final rideData = rideDoc.data();
      final driverId = rideData?['driverId'];

      if (driverId != null) {
        await sendNotification(
          userId: driverId,
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      _logger.e('Error sending ride notification', error: e);
    }
  }

  Future<void> sendBookingNotification({
    required String bookingId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get booking details
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) return;

      final bookingData = bookingDoc.data();
      final passengerId = bookingData?['passengerId'];
      final driverId = bookingData?['driverId'];

      // Send to both passenger and driver
      if (passengerId != null) {
        await sendNotification(
          userId: passengerId,
          title: title,
          body: body,
          data: data,
        );
      }

      if (driverId != null) {
        await sendNotification(
          userId: driverId,
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      _logger.e('Error sending booking notification', error: e);
    }
  }

  // Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
      if (error is FirebaseException &&
          error.code == 'failed-precondition' &&
          error.message != null &&
          error.message!.contains('index')) {
        _logger.w('Firestore index missing for notifications query: $error');
        return const Stream.empty();
      }
      throw error;
    }).map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      _logger.e('Error marking notification as read', error: e);
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      _logger.e('Error marking all notifications as read', error: e);
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      _logger.e('Error deleting notification', error: e);
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      _logger.e('Error clearing all notifications', error: e);
    }
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _logger.i('Handling background message: ${message.messageId}');
}
