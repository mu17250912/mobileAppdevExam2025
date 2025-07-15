import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/cart_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

FirebaseAnalytics analytics = FirebaseAnalytics.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDxxButpcSsxVN_1YWDTy0gPQj_0_BQLvg",
        authDomain: "grocelydeliveryapp.firebaseapp.com",
        projectId: "grocelydeliveryapp",
        storageBucket: "grocelydeliveryapp.firebasestorage.app",
        messagingSenderId: "665849054437",
        appId: "1:665849054437:web:630354ba60738eb22e000c",
        measurementId: "G-9QLBND6N46",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  await analytics.logAppOpen();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        Provider(create: (_) => ProductService()),
      ],
      child: MaterialApp(
        title: 'Grocery Delivery App',
        theme: ThemeData(primarySwatch: Colors.green),
        home: const RootScreen(),
        debugShowCheckedModeBanner: false,
        navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  User? _lastUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context);
    final cartService = Provider.of<CartService>(context, listen: false);
    authService.authStateChanges.listen((user) {
      if (user != null && user != _lastUser) {
        cartService.loadUnpaidCart();
      } else if (user == null && _lastUser != null) {
        cartService.clear();
      }
      _lastUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        } else if (snapshot.hasData) {
          if (authService.isAdmin) {
            return const AdminHomeScreen();
          } else {
            return const HomeScreen();
          }
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
