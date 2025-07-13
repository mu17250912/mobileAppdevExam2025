import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/profile_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/add_skill_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/requested_skills_screen.dart';
import 'screens/session_requests_screen.dart';
import 'services/app_service.dart';
import 'services/navigation_service.dart';
import 'models/notification_model.dart';
import 'widgets/screen_wrapper.dart';

Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions (especially for iOS)
  await messaging.requestPermission();

  // Get the token
  String? token = await messaging.getToken();
  debugPrint('FCM Token: $token');

  // Save the token to Firestore under the user's document
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && token != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': newToken,
      });
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatefulWidget {
  const SkillSwapApp({super.key});

  @override
  State<SkillSwapApp> createState() => _SkillSwapAppState();
}

class _SkillSwapAppState extends State<SkillSwapApp> {
  @override
  void initState() {
    super.initState();
    // Setup FCM after user login
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        setupFCM();
      }
    });
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // You can show a dialog, snackbar, or local notification here
        debugPrint(
            'Received a message in foreground: ${message.notification?.title}');
      }
    });
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final chatId = message.data['chatId'];
      if (chatId != null) {
        // TODO: Implement navigation to ChatScreen with chatId
        debugPrint('Open chat: $chatId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[800],
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        // Responsive text scaling
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12),
        ),
        // Responsive color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        // Responsive input decoration
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        // Responsive elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScaffold(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/requested-skills': (context) => const RequestedSkillsScreen(),
        '/session-requests': (context) => const SessionRequestsScreen(),
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Remove NavigationService for tab index
  // final NavigationService _navigationService = NavigationService();
  late final List<Widget> _screens;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // _navigationService.initialize();
    _screens = [
      const HomeScreen(),
      const SearchScreen(),
      const AlertsScreen(),
      const ChatListScreen(),
      const AddSkillScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    // _navigationService.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(_currentIndex)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messenger'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Add Skills'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Search';
      case 2:
        return 'Alerts';
      case 3:
        return 'Messenger';
      case 4:
        return 'Add Skills';
      case 5:
        return 'Profile';
      default:
        return 'SkillSwap';
    }
  }
}
