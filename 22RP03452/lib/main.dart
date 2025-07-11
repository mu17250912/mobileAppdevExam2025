import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/order_confirmation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web requires FirebaseOptions
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyB046j_t15F1XQ7ICqq5eMJlpOLsbJ7gAk",
        authDomain:
            "karibufruit.firebaseapp.com", // Firebase Console sets this automatically
        projectId: "karibufruit",
        storageBucket: "karibufruit.appspot.com", // corrected domain
        messagingSenderId: "100031582761",
        appId: "1:100031582761:android:57a8dee012c50bc3d64238",
      ),
    );
  } else {
    // Android/iOS use config files (google-services.json, etc.)
    await Firebase.initializeApp();
  }

  runApp(const KaribuFruitsApp());
}

class KaribuFruitsApp extends StatelessWidget {
  const KaribuFruitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karibu Fruits',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFFF1F8E9),
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/product-detail': (context) => const ProductDetailScreen(),
        '/order-confirmation': (context) => const OrderConfirmationScreen(),
      },
    );
  }
}
