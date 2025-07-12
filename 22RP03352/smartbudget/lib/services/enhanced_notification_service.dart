import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class EnhancedNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification channels
  static const AndroidNotificationChannel budgetChannel = AndroidNotificationChannel(
    'budget_alerts',
    'Budget Alerts',
    description: 'Notifications for budget limits and financial insights',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
    'daily_reminders',
    'Daily Reminders',
    description: 'Daily reminders to track expenses',
    importance: Importance.medium,
  );

  static const AndroidNotificationChannel achievementChannel = AndroidNotificationChannel(
    'achievements',
    'Achievements',
    description: 'Achievement notifications and rewards',
    importance: Importance.high,
  );

  // Initialize notification service
  static Future<void> initialize() async {
    // Request permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(budgetChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(achievementChannel);

    // Handle Firebase messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);
  }

  // Save FCM token to Firestore
  static Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      _showLocalNotification(
        title: message.notification!.title ?? 'BudgetWise',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    // Handle background message logic here
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap logic here
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'budget_alerts',
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifications for budget limits',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Schedule daily reminder
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Daily reminders to track expenses',
      importance: Importance.medium,
      priority: Priority.medium,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.periodicallyShow(
      0,
      'Daily Expense Reminder',
      'Don\'t forget to track your expenses today! 📊',
      RepeatInterval.daily,
      platformChannelSpecifics,
    );

    // Save reminder settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
  }

  // Check budget limits and send alerts
  static Future<void> checkBudgetLimits() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Get budgets and expenses
    final budgetsQuery = await _firestore
        .collection('budgets')
        .doc(user.uid)
        .collection('user_budgets')
        .where('month', isEqualTo: currentMonth)
        .where('year', isEqualTo: currentYear)
        .get();

    final expensesQuery = await _firestore
        .collection('expenses')
        .doc(user.uid)
        .collection('user_expenses')
        .where('month', isEqualTo: currentMonth)
        .where('year', isEqualTo: currentYear)
        .get();

    final Map<String, double> categoryBudgets = {};
    final Map<String, double> categorySpending = {};

    // Process budgets
    for (var doc in budgetsQuery.docs) {
      final category = doc['category'] as String;
      final amount = (doc['amount'] as num).toDouble();
      categoryBudgets[category] = amount;
    }

    // Process expenses
    for (var doc in expensesQuery.docs) {
      final category = doc['category'] as String;
      final amount = (doc['amount'] as num).toDouble();
      categorySpending[category] = (categorySpending[category] ?? 0) + amount;
    }

    // Check for budget overruns
    for (final entry in categoryBudgets.entries) {
      final category = entry.key;
      final budget = entry.value;
      final spent = categorySpending[category] ?? 0;
      final percentage = (spent / budget) * 100;

      if (percentage >= 80 && percentage < 100) {
        await _showLocalNotification(
          title: 'Budget Warning ⚠️',
          body: 'You\'ve used ${percentage.toStringAsFixed(1)}% of your $category budget',
          channelId: 'budget_alerts',
        );
      } else if (percentage >= 100) {
        await _showLocalNotification(
          title: 'Budget Exceeded ❌',
          body: 'You\'ve exceeded your $category budget by ${(spent - budget).toStringAsFixed(0)} RWF',
          channelId: 'budget_alerts',
        );
      }
    }
  }

  // Send smart spending insights
  static Future<void> sendSpendingInsights() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Get this month's expenses
    final expensesQuery = await _firestore
        .collection('expenses')
        .doc(user.uid)
        .collection('user_expenses')
        .where('month', isEqualTo: currentMonth)
        .where('year', isEqualTo: currentYear)
        .get();

    if (expensesQuery.docs.isEmpty) return;

    // Calculate insights
    final Map<String, double> categoryTotals = {};
    double totalSpent = 0;

    for (var doc in expensesQuery.docs) {
      final category = doc['category'] as String;
      final amount = (doc['amount'] as num).toDouble();
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      totalSpent += amount;
    }

    // Find top spending category
    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final percentage = (topCategory.value / totalSpent) * 100;

      if (percentage > 40) {
        await _showLocalNotification(
          title: 'Spending Insight 💡',
          body: '${topCategory.key} accounts for ${percentage.toStringAsFixed(1)}% of your spending this month',
          channelId: 'budget_alerts',
        );
      }
    }

    // Check for unusual spending patterns
    final today = now.day;
    final todayExpenses = expensesQuery.docs
        .where((doc) => doc['day'] == today)
        .map((doc) => (doc['amount'] as num).toDouble())
        .reduce((a, b) => a + b);

    final avgDailySpending = totalSpent / now.day;
    if (todayExpenses > avgDailySpending * 2) {
      await _showLocalNotification(
        title: 'Unusual Spending Alert 🚨',
        body: 'Today\'s spending is significantly higher than your daily average',
        channelId: 'budget_alerts',
      );
    }
  }

  // Send achievement notifications
  static Future<void> sendAchievementNotification({
    required String title,
    required String description,
  }) async {
    await _showLocalNotification(
      title: title,
      body: description,
      channelId: 'achievements',
    );
  }

  // Send weekly summary
  static Future<void> sendWeeklySummary() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final expensesQuery = await _firestore
        .collection('expenses')
        .doc(user.uid)
        .collection('user_expenses')
        .where('date', isGreaterThanOrEqualTo: weekStart)
        .where('date', isLessThanOrEqualTo: weekEnd)
        .get();

    if (expensesQuery.docs.isEmpty) return;

    double weeklyTotal = 0;
    for (var doc in expensesQuery.docs) {
      weeklyTotal += (doc['amount'] as num).toDouble();
    }

    await _showLocalNotification(
      title: 'Weekly Summary 📊',
      body: 'You spent ${weeklyTotal.toStringAsFixed(0)} RWF this week',
      channelId: 'budget_alerts',
    );
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get notification settings
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'dailyReminder': prefs.getBool('daily_reminder') ?? false,
      'budgetAlerts': prefs.getBool('budget_alerts') ?? true,
      'achievementNotifications': prefs.getBool('achievement_notifications') ?? true,
      'weeklySummary': prefs.getBool('weekly_summary') ?? true,
      'reminderHour': prefs.getInt('reminder_hour') ?? 20,
      'reminderMinute': prefs.getInt('reminder_minute') ?? 0,
    };
  }

  // Update notification settings
  static Future<void> updateNotificationSettings({
    bool? dailyReminder,
    bool? budgetAlerts,
    bool? achievementNotifications,
    bool? weeklySummary,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (dailyReminder != null) {
      await prefs.setBool('daily_reminder', dailyReminder);
      if (dailyReminder && reminderHour != null && reminderMinute != null) {
        await scheduleDailyReminder(hour: reminderHour, minute: reminderMinute);
      } else if (!dailyReminder) {
        await _localNotifications.cancel(0); // Cancel daily reminder
      }
    }

    if (budgetAlerts != null) await prefs.setBool('budget_alerts', budgetAlerts);
    if (achievementNotifications != null) await prefs.setBool('achievement_notifications', achievementNotifications);
    if (weeklySummary != null) await prefs.setBool('weekly_summary', weeklySummary);
    if (reminderHour != null) await prefs.setInt('reminder_hour', reminderHour);
    if (reminderMinute != null) await prefs.setInt('reminder_minute', reminderMinute);
  }
} 