import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

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
  print('Before Firebase');
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
  print('After Firebase');

  // Initialize services
  print('Before NotificationService');
  await NotificationService.initialize();
  print('After NotificationService');

  print('Before AdService');
  await AdService().initializeAds();
  print('After AdService');

  print('Before FirebaseService');
  await FirebaseService().initialize();
  print('After FirebaseService');

  print('Before SecurityService');
  await SecurityService().initialize();
  print('After SecurityService');

  // Only initialize in-app purchase on mobile
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    print('Before PurchaseService');
    await PurchaseService().initialize();
    print('After PurchaseService');
  }

  print('Before runApp');
  runApp(const IremeGirlSafeApp());
  print('After runApp');
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
        textTheme: GoogleFonts.robotoTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE91E63),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE91E63)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    print('Checking login status...');
    final isLoggedIn = await LocalStorageService.isLoggedIn();
    print('Login status: ' + isLoggedIn.toString());
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('AuthWrapper build: isLoading=' + _isLoading.toString() + ', isLoggedIn=' + _isLoggedIn.toString());
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

