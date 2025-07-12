import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:flutter_paypal/flutter_paypal.dart';

// Your screens
import 'auths/login_page.dart';
import 'auths/register_page.dart';
import 'clients/client_home.dart';
import 'sellers/seller_home.dart';
import 'auths/auth_service.dart';
import 'splash_screen.dart';
import 'services/notification_service.dart';
import 'clients/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase initialization failed
  }

  runApp(const MyApp());
}

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final FirebaseAnalyticsObserver analyticsObserver = FirebaseAnalyticsObserver(analytics: analytics);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize notification service
    NotificationService.initialize();
    
    return MaterialApp(
      title: 'PhoneStore',
      navigatorObservers: [analyticsObserver],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.deepPurple,
        iconTheme: const IconThemeData(
          color: Colors.deepPurple,
          size: 24,
        ),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      home: const SplashToAuthWrapper(),
      themeMode: ThemeMode.light,
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/client': (context) => const ClientHomePage(),
        '/seller': (context) => const SellerHomePage(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}

class SplashToAuthWrapper extends StatefulWidget {
  const SplashToAuthWrapper({super.key});

  @override
  State<SplashToAuthWrapper> createState() => _SplashToAuthWrapperState();
}

class _SplashToAuthWrapperState extends State<SplashToAuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for 3 seconds then navigate to auth
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    } else {
      return const AuthWrapper();
    }
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<String?>(
            future: AuthService().getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading user role...'),
                      ],
                    ),
                  ),
                );
              }
              
              if (roleSnapshot.hasData) {
                if (roleSnapshot.data == 'seller') {
                  return const SellerHomePage();
                } else if (roleSnapshot.data == 'buyer') {
                  return const ClientHomePage();
                } else {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('User role not found.'),
                          SizedBox(height: 8),
                          Text('Please contact support.'),
                        ],
                      ),
                    ),
                  );
                }
              }
              
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error loading user role.'),
                      SizedBox(height: 8),
                      Text('Please try again.'),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // User is not logged in, show login page
        return const LoginPage();
      },
    );
  }
}
