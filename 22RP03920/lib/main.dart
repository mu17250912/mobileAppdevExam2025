import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/doctors/doctors_list_screen.dart';
import 'screens/doctors/doctor_details_screen.dart';
import 'screens/booking/book_appointment_screen.dart';
import 'screens/booking/booking_confirmation_screen.dart';
import 'screens/my_bookings/my_bookings_screen.dart';
import 'screens/home/notifications_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/error_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/payment/payment_screen.dart';
import 'screens/payment/payment_success_screen.dart';
import 'screens/home/profile_screen.dart';
import 'package:flutter/foundation.dart' show FlutterError, PlatformDispatcher;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    } catch (e) {
      print('Navigation error in splash screen: $e');
      if (mounted) {
        // Fallback navigation
        Navigator.pushReplacementNamed(context, '/signin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom vector logo: blue shield with white cross, inside a circular blue background with shadow
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 32,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.shield, size: 64, color: Colors.blue[700]),
                    Positioned(
                      child: Icon(Icons.add, size: 36, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: 'SmartCare\n',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
                  ),
                  const TextSpan(
                    text: 'Medical Link Rwanda',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your health, our priority',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 18,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 3),
              builder: (context, value, child) {
                return Container(
                  width: 220,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 220 * value,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // Set up error handling for async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Platform error: $error');
    print('Stack trace: $stack');
    return true;
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase with error handling
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      // Continue without Firebase for now
    }
    
    // Initialize Mobile Ads with error handling
    if (!kIsWeb) {
      try {
        await MobileAds.instance.initialize();
        print('Mobile Ads initialized successfully');
      } catch (e) {
        print('Mobile Ads initialization failed: $e');
        // Continue without Mobile Ads
      }
    }
    
    // Initialize Notification Service with error handling
    try {
      await NotificationService().initialize();
      print('Notification service initialized successfully');
    } catch (e) {
      print('Notification service initialization failed: $e');
      // Continue without notifications
    }
    
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const SmartCareApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('Critical error during app initialization: $e');
    print('Stack trace: $stackTrace');
    
    // Run a minimal app that shows an error screen
    runApp(
      MaterialApp(
        title: 'Medical Link Rwanda',
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'App Initialization Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The app encountered an error during startup: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Restart the app
                      main();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SmartCareApp extends StatelessWidget {
  const SmartCareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      return MaterialApp(
        title: 'Medical Link Rwanda',
        theme: Provider.of<ThemeProvider>(context).theme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/home': (context) => const HomeScreen(),
          '/doctors': (context) => const DoctorsListScreen(),
          '/doctor_details': (context) => const DoctorDetailsScreen(),
          '/book_appointment': (context) => const BookAppointmentScreen(),
          '/booking_confirmation': (context) => const BookingConfirmationScreen(),
          '/my_bookings': (context) => const MyBookingsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/admin_dashboard': (context) => const AdminDashboardScreen(),
          '/payment_success': (context) => const PaymentSuccessScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
        onGenerateRoute: (settings) {
          try {
            if (settings.name == '/payment') {
              final args = settings.arguments as Map<String, dynamic>?;
              final amount = args?['amount'] ?? 5000.0;
              final bookingDetails = args?['bookingDetails'] ?? {};
              return MaterialPageRoute(
                builder: (context) => PaymentScreen(amount: amount, bookingDetails: bookingDetails),
              );
            }
            return null;
          } catch (e) {
            print('Route generation error: $e');
            return MaterialPageRoute(
              builder: (context) => const ErrorScreen(error: 'Navigation error occurred'),
            );
          }
        },
        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            print('Widget error: ${details.exception}');
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Widget Error',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'An error occurred: ${details.exception}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signin');
                        },
                        child: const Text('Go to Sign In'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          };
          return child ?? const SizedBox.shrink();
        },
      );
    } catch (e) {
      print('SmartCareApp build error: $e');
      return MaterialApp(
        title: 'Medical Link Rwanda',
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'App Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The app encountered an error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint('AuthWrapper error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Text('An error occurred: ${snapshot.error}'),
            ),
          );
        }
        if (snapshot.hasData) {
          // User is logged in, but we need to check the role
          return const RoleBasedRedirect();
        }
        return const SignInScreen();
      },
    );
  }
}

class RoleBasedRedirect extends StatelessWidget {
  const RoleBasedRedirect({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return FutureBuilder<String?>(
      future: authService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint('RoleBasedRedirect error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Text('An error occurred: ${snapshot.error}'),
            ),
          );
        }
        // Check for specific roles
        switch (snapshot.data) {
          case 'admin':
            return const AdminDashboardScreen();
          case 'doctor':
            return const HomeScreen(); // Redirect doctor to home
          case 'patient':
            return const HomeScreen();
          default:
            const errorMessage = 'Your user account is not configured correctly. Please contact support.';
            debugPrint('Unknown or null role for user. UID: ${authService.getCurrentUser()?.uid}');
            return const ErrorScreen(error: errorMessage);
        }
      },
    );
  }
}
