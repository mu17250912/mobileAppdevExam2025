import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/customer/manager_dashboard.dart';
import 'screens/cleaner/cleaner_dashboard.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/subscribe_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Handle background message (optional: show local notification)
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const CleanConnectApp(),
    ),
  );
}

class CleanConnectApp extends StatefulWidget {
  const CleanConnectApp({Key? key}) : super(key: key);

  @override
  State<CleanConnectApp> createState() => _CleanConnectAppState();
}

class _CleanConnectAppState extends State<CleanConnectApp> {
  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    // Request notification permissions
    await FirebaseMessaging.instance.requestPermission();
    // Get FCM token and save to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': token});
      }
    }
    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': token});
      }
    });
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Optionally show a dialog or local notification
        print('Notification received: ${message.notification!.title} - ${message.notification!.body}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CleanConnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/manager_dashboard': (context) => const ManagerDashboard(),
        '/cleaner_dashboard': (context) => const CleanerDashboard(),
        '/subscribe': (context) => const SubscribePage(),
      },
    );
  }
}
