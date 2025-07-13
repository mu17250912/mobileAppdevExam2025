import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'features/provider/provider_dashboard.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/logger_service.dart';
import 'services/cache_service.dart';
import 'services/network_service.dart';
import 'services/performance_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    logger.info('SplashScreen initialized');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        logger.info('Navigating from SplashScreen to AuthGate');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 90,
                  height: 90,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Local Link',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Connect. Book. Enjoy.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local Link',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        logger.debug('AuthGate: Auth state changed - ${snapshot.connectionState}', 'AuthGate');
        if (snapshot.hasData) {
          logger.info('AuthGate: User logged in - ${snapshot.data!.email}', 'AuthGate');
        } else {
          logger.debug('AuthGate: No user logged in', 'AuthGate');
        }
        
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
            future: authService.getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              logger.debug('AuthGate: Role check - ${roleSnapshot.data}', 'AuthGate');
              if (!roleSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              // Navigate based on role
              if (roleSnapshot.data == 'provider') {
                logger.info('AuthGate: Navigating to ProviderDashboard', 'AuthGate');
                return const ProviderDashboard();
              } else {
                logger.info('AuthGate: Navigating to HomeScreen', 'AuthGate');
                return const HomeScreen();
              }
            },
          );
        }
        
        // No user logged in, show auth screen
        logger.info('AuthGate: Showing AuthScreen', 'AuthGate');
        return const AuthScreen();
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize all services in order of dependency
  await logger.initialize();
  logger.info('Application starting...', 'Main');
  
  // Initialize performance monitoring
  await performanceService.initialize();
  logger.info('Performance monitoring initialized', 'Main');
  
  // Initialize network service (includes cache service)
  await networkService.initialize();
  logger.info('Network and cache services initialized', 'Main');
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.info('Firebase initialized successfully', 'Main');
    
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await FlutterLocalNotificationsPlugin().initialize(initializationSettings);
    logger.info('Local notifications initialized successfully', 'Main');
    
  } catch (e) {
    logger.error('Firebase initialization error', 'Main', e);
  }
  
  logger.info('Starting MyApp', 'Main');
  runApp(const MyApp());
}
