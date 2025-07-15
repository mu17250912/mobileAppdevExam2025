import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Screens
import 'screens/splash_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'screens/job_listings_screen.dart';
import 'screens/income_dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/simulated_payment_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/my_gigs_screen.dart';
import 'screens/help_faq_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/gig_detail_screen.dart';

import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  // print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const WindowsInitializationSettings initializationSettingsWindows = WindowsInitializationSettings(
    appName: 'Campus Gigs & Income Tracker',
    appUserModelId: 'com.example.campus_gigs_income_tracker',
    guid: '97eaece3-8c2a-4c87-b975-7a9dd3f1e209',
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    windows: initializationSettingsWindows,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // print('Firebase initialization failed: $e');
    // Continue without Firebase
  }

  try {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await MobileAds.instance.initialize();
      print('MobileAds initialized successfully');
      // Firebase Messaging setup
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission();
      // print('User granted permission: ${settings.authorizationStatus}');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Show notification if it's a chat message
        final notification = message.notification;
        final data = message.data;
        if (notification != null && (data['type'] == 'chat' || data['screen'] == 'chat')) {
          showChatNotification(
            notification.title ?? 'New Message',
            notification.body ?? 'You have a new chat message. Tap to check your chat.',
          );
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // print('Notification caused app to open: ${message.notification?.title}');
      });
    }
  } catch (e) {
    print('MobileAds or Messaging initialization failed: $e');
    // Continue without ads or messaging
  }

  runApp(
    const MyApp(),
  );
}

Future<void> scheduleGigReminderNotification(int id, String title, String body, DateTime scheduledTime) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduledTime, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails('gig_reminders', 'Gig Reminders', importance: Importance.max, priority: Priority.high),
      windows: WindowsNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
  );
}

// Show a local notification for new chat messages
void showChatNotification(String title, String body) async {
  await flutterLocalNotificationsPlugin.show(
    9999, // Unique ID for chat notifications
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      ),
      windows: WindowsNotificationDetails(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Gigs & Income Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Colors.deepPurple),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.deepPurple,
          textColor: Colors.black87,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.deepPurple,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.deepPurple,
          contentTextStyle:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      navigatorObservers: [observer],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/signin': (context) => const SignInScreen(),
        '/home': (context) => HomeScreenWithCalendarButton(),
        '/jobs': (context) => const JobListingsScreen(),
        '/income': (context) => const IncomeDashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/premium': (context) => const PremiumScreen(),
        '/pay': (context) => const SimulatedPaymentScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/mygigs': (context) => const MyGigsScreen(),
        '/help': (context) => const HelpFaqScreen(),
        '/chat': (context) => const ChatScreen(),
        '/gig_detail': (context) => const GigDetailScreen(),
      },
    );
  }
}

// Add a wrapper for HomeScreen to provide a FAB for calendar navigation
class HomeScreenWithCalendarButton extends StatelessWidget {
  const HomeScreenWithCalendarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeScreen(),
        Positioned(
          bottom: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'calendar',
                onPressed: () {
                  Navigator.pushNamed(context, '/calendar');
                },
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'mygigs',
                onPressed: () {
                  Navigator.pushNamed(context, '/mygigs');
                },
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.work),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
