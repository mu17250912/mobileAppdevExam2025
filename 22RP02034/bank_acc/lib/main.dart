import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/dashboard.dart';
import 'screens/home.dart';
import 'screens/splash.dart';
import 'screens/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _handleThemeChanged(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank Account Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      themeMode: ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => HomeScreen(),
        '/settings': (context) => SettingsScreen(onThemeChanged: _handleThemeChanged),
      },
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
