import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize FCM with proper permission handling
  static Future<bool> initializeFCM() async {
    try {
      // Check current permission status first
      NotificationSettings currentSettings =
          await _messaging.getNotificationSettings();
      debugPrint(
          'Current permission status: ${currentSettings.authorizationStatus}');

      // Only request permission if not already determined
      if (currentSettings.authorizationStatus ==
          AuthorizationStatus.notDetermined) {
        NotificationSettings settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        debugPrint(
            'Permission request result: ${settings.authorizationStatus}');

        // If permission was denied, don't proceed
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint('Notification permission denied by user');
          return false;
        }
      } else if (currentSettings.authorizationStatus ==
          AuthorizationStatus.denied) {
        debugPrint(
            'Notification permission already denied, skipping FCM setup');
        return false;
      }

      // Get the token only if permission is granted
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // Save the token to Firestore
      if (token != null) {
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        await _saveFCMToken(newToken);
      });

      return true;
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
      return false;
    }
  }

  /// Save FCM token to Firestore
  static Future<void> _saveFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved successfully');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Get current notification settings
  static Future<NotificationSettings> getNotificationSettings() async {
    try {
      return await _messaging.getNotificationSettings();
    } catch (e) {
      debugPrint('Error getting notification settings: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  static Future<NotificationSettings> requestPermissions() async {
    try {
      return await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      rethrow;
    }
  }

  /// Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Delete FCM token
  static Future<void> deleteFCMToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('FCM token deleted successfully');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Check and request notification permission, and guide user if denied
  static Future<void> checkAndRequestPermission() async {
    try {
      NotificationSettings settings =
          await _messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
            'Notification permission denied. Please enable it in your device settings.');
        // Optionally, you could trigger a UI dialog/snackbar here if called from UI
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.notDetermined) {
        NotificationSettings newSettings = await _messaging.requestPermission();
        if (newSettings.authorizationStatus == AuthorizationStatus.authorized) {
          debugPrint('Notification permission granted after request.');
          // Optionally, you could proceed with FCM setup here if needed
        }
      }
    } catch (e) {
      debugPrint('Error checking/requesting notification permission: $e');
    }
  }
}
