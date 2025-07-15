import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // <-- Add this import
import 'screens/splash_screen.dart';
import 'utils/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/animal_provider.dart';
import 'providers/notification_provider.dart'; // <-- Add this import
import 'screens/buyer/buyer_main_screen.dart';
import 'screens/seller/seller_dashboard.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // <-- Use this for web/mobile
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnimalProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()), // <-- Add this line
      ],
      child: AniMarketApp(),
    ),
  );
}

class AniMarketApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniMarket',
      theme: ThemeData(
        primaryColor: kPrimaryGreen,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: kAccentYellow,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: kDarkText),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
      routes: {
        '/buyer-dashboard': (context) => BuyerMainScreen(),
        '/seller-dashboard': (context) => SellerDashboard(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initSplashAndOnboarding();
  }

  Future<void> _initSplashAndOnboarding() async {
    await Future.delayed(Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    setState(() {
      _showSplash = false;
      _showOnboarding = !hasSeenOnboarding;
    });
  }

  void completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (_showSplash) {
      return SplashScreen();
    }
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: completeOnboarding);
    }
    if (user == null) {
      return LoginScreen();
    } else if (user.role == UserRole.farmer) {
      return SellerDashboard();
    } else {
      return BuyerMainScreen();
    }
  }
}