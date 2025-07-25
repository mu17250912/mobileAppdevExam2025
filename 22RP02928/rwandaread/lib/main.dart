import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/library_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/subscription_management_screen.dart';
import 'services/subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize subscription service
  await SubscriptionService().initialize();
  
  runApp(const RwandareadApp());
}

class RwandareadApp extends StatelessWidget {
  const RwandareadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RwandaRead',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1E3A8A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const LibraryScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/subscription-management': (context) => const SubscriptionManagementScreen(),
      },
    );
  }
}
