import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/support_screen.dart';
import 'screens/settings_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const Color kGoldenBrown = Color(0xFFB6862C);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FirebaseAnalytics analytics;
  final List<Map<String, String>> _notifications = [];

  @override
  void initState() {
    super.initState();
    analytics = FirebaseAnalytics.instance;
    _initFirebaseMessaging();
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _notifications.add({
          'title': message.notification?.title ?? 'No Title',
          'body': message.notification?.body ?? 'No Body',
        });
      });
      // Optionally show a dialog or badge
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(message.notification?.title ?? 'Notification'),
            content: Text(message.notification?.body ?? ''),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      setState(() {
        _notifications.add({
          'title': message.notification?.title ?? 'No Title',
          'body': message.notification?.body ?? 'No Body',
        });
      });
      // Navigate to notifications screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => NotificationsScreen(notifications: _notifications),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = kGoldenBrown;
    final Color background = const Color(0xFFF6F7FB);
    return MaterialApp(
      title: 'TINDERJOB',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: primary,
          onPrimary: Colors.white,
          secondary: Colors.deepPurpleAccent,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: background,
          onBackground: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kGoldenBrown,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kGoldenBrown,
          foregroundColor: Colors.white,
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/notifications': (ctx) => NotificationsScreen(notifications: _notifications),
        '/feedback': (ctx) => const FeedbackScreen(),
        '/support': (ctx) => const SupportScreen(),
        '/settings': (ctx) => const SettingsScreen(),
      },
    );
  }
}

class AuthSwitcher extends StatefulWidget {
  const AuthSwitcher({super.key});

  @override
  State<AuthSwitcher> createState() => _AuthSwitcherState();
}

class _AuthSwitcherState extends State<AuthSwitcher> {
  bool showLogin = true;

  void toggle() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return showLogin
        ? LoginScreen(onRegisterTap: toggle)
        : RegisterScreen(onLoginTap: toggle);
  }
}
