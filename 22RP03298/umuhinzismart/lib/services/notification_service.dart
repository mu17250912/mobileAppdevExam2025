import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize notification service
  static Future<void> initialize() async {
    // Request permission for notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Show local notification
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'umuhinzi_channel',
      'UMUHINZI Smart',
      channelDescription: 'Notifications for UMUHINZI Smart app',
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

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Show order status notification
  static Future<void> showOrderNotification({
    required String orderId,
    required String status,
    required String productName,
  }) async {
    String title = 'Order Update';
    String body = '';

    switch (status.toLowerCase()) {
      case 'confirmed':
        title = 'Order Confirmed!';
        body = 'Your order for $productName has been confirmed.';
        break;
      case 'shipped':
        title = 'Order Shipped!';
        body = 'Your order for $productName is on its way.';
        break;
      case 'delivered':
        title = 'Order Delivered!';
        body = 'Your order for $productName has been delivered.';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        body = 'Your order for $productName has been cancelled.';
        break;
      default:
        body = 'Your order for $productName status: $status';
    }

    await showNotification(
      title: title,
      body: body,
      payload: 'order:$orderId',
    );
  }

  /// Show payment notification
  static Future<void> showPaymentNotification({
    required String orderId,
    required bool success,
    required double amount,
  }) async {
    final title = success ? 'Payment Successful!' : 'Payment Failed';
    final body = success 
        ? 'Payment of RWF ${amount.toStringAsFixed(0)} for order $orderId was successful.'
        : 'Payment of RWF ${amount.toStringAsFixed(0)} for order $orderId failed. Please try again.';

    await showNotification(
      title: title,
      body: body,
      payload: 'payment:$orderId',
    );
  }

  /// Show fertilizer reminder
  static Future<void> showFertilizerReminder({
    required String crop,
    required String week,
    required String recommendation,
  }) async {
    await showNotification(
      title: 'Fertilizer Reminder',
      body: 'Week $week: $recommendation for your $crop',
      payload: 'fertilizer:$crop:$week',
    );
  }

  /// Show premium subscription notification
  static Future<void> showPremiumNotification({
    required String plan,
    required bool success,
  }) async {
    final title = success ? 'Premium Activated!' : 'Premium Subscription Failed';
    final body = success 
        ? 'Your $plan subscription has been activated successfully!'
        : 'Failed to activate $plan subscription. Please try again.';

    await showNotification(
      title: title,
      body: body,
      payload: 'premium:$plan',
    );
  }

  /// Schedule fertilizer reminders
  static Future<void> scheduleFertilizerReminders({
    required String crop,
    required Map<String, String> weeklyRecommendations,
  }) async {
    final now = DateTime.now();
    
    for (int i = 0; i < weeklyRecommendations.length; i++) {
      final week = (i + 1).toString();
      final recommendation = weeklyRecommendations[week] ?? '';
      
      if (recommendation.isNotEmpty) {
        final scheduledDate = tz.TZDateTime.from(now.add(Duration(days: i * 7)), tz.local);
        
        await _localNotifications.zonedSchedule(
          i + 100, // Unique ID for each reminder
          'Fertilizer Reminder - Week $week',
          'Week $week: $recommendation for your $crop',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fertilizer_channel',
              'Fertilizer Reminders',
              channelDescription: 'Weekly fertilizer application reminders',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'fertilizer:$crop:$week',
        );
      }
    }
  }

  /// Get FCM token
  static Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  /// Handle foreground message
  static void _handleForegroundMessage(RemoteMessage message) {
    showNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation based on notification type
    final data = message.data;
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'order':
          // Navigate to order details
          break;
        case 'payment':
          // Navigate to payment history
          break;
        case 'fertilizer':
          // Navigate to fertilizer recommendations
          break;
        case 'premium':
          // Navigate to premium features
          break;
      }
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here
  print('Handling background message: ${message.messageId}');
} 