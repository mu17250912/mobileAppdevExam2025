import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_core/firebase_core.dart';

// Import screens
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/info_hub_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/profile_screen.dart';

// Import services
import 'services/notification_service.dart';
import 'services/local_storage_service.dart';
import 'services/ad_service.dart';
import 'services/firebase_service.dart';
import 'services/security_service.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCZlfT-nIag64UUwYDdzrI1pl47oeab3HA",
        authDomain: "safegirl.firebaseapp.com",
        projectId: "safegirl-28a9a",
        storageBucket: "safegirl.appspot.com",
        messagingSenderId: "357204460452",
        appId: "1:357204460452:android:035656e8e9d00d09aa3731",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // Initialize services
  await NotificationService.initialize();
  await AdService().initializeAds();
  await FirebaseService().initialize();
  await SecurityService().initialize();

  // Only initialize in-app purchase on mobile
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    await PurchaseService().initialize();
  }

  runApp(const IremeGirlSafeApp());
}

class IremeGirlSafeApp extends StatelessWidget {
  const IremeGirlSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ireme Girl Safe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        primaryColor: const Color(0xFFE91E63),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE91E63),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/info-hub': (context) => const InfoHubScreen(),
        '/chat': (context) => const ChatScreen(),
        '/reminders': (context) => const RemindersScreen(),
        '/emergency': (context) => const EmergencyScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await LocalStorageService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const HomeScreen() : const SplashScreen();
  }
}

