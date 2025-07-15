/// SafeRide - Full-featured Transportation Booking App
///
/// This app helps people in rural or semi-urban areas find and book transportation
/// (buses, mini-buses, moto taxis). It connects passengers with drivers, making it
/// easier and safer to book local trips.
///
/// Key Features:
/// - User authentication (passengers, drivers, admins)
/// - View and book available rides
/// - Post rides (for drivers)
/// - Real-time chat with drivers
/// - Location-based ride filtering
/// - Premium subscription plans
/// - Ad integration for monetization (ads and premium features)
/// - Admin dashboard, analytics, payments, content, notifications, user management
/// - Support center
///
/// Tech Stack:
/// - Flutter for cross-platform mobile development
/// - Firebase for backend services (Auth, Firestore, Analytics)
/// - AdMob for monetization (ads and premium features)
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saferide/firebase_options.dart';
import 'package:saferide/services/auth_service.dart';
import 'package:saferide/screens/splash_screen.dart';
import 'package:saferide/screens/auth/login_screen.dart';
import 'package:saferide/screens/auth/register_screen.dart';
import 'package:saferide/screens/home_screen.dart';
import 'package:saferide/screens/admin_panel_screen.dart';
import 'package:saferide/screens/book_ride_screen.dart';
import 'package:saferide/screens/booking_history_screen.dart';
import 'package:saferide/screens/booking_screen.dart';
import 'package:saferide/screens/driver_profile_screen.dart';
import 'package:saferide/screens/auth/forgot_password_screen.dart';
import 'package:saferide/screens/post_ride_screen.dart';
import 'package:saferide/screens/profile_screen.dart';
import 'package:saferide/screens/ride_list_screen.dart';
import 'package:saferide/screens/support_center_screen.dart';
import 'package:saferide/screens/chat_screen.dart';
import 'package:saferide/screens/admin_users_screen.dart';
import 'package:saferide/screens/admin_analytics_screen.dart';
import 'package:saferide/screens/admin_content_screen.dart';
import 'package:saferide/screens/admin_payments_screen.dart';
import 'package:saferide/screens/admin_notifications_screen.dart';
import 'package:saferide/screens/passenger_dashboard_screen.dart';
import 'package:saferide/screens/driver_dashboard_screen.dart';
import 'package:saferide/screens/monetization_dashboard_screen.dart';
import 'package:saferide/screens/driver_earnings_screen.dart';
import 'package:saferide/l10n/app_localizations.dart';
import 'package:saferide/services/global_error_handler.dart';
import 'package:saferide/models/user_model.dart';
import 'package:saferide/theme/app_theme.dart';
import 'package:saferide/utils/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    GlobalErrorHandler().initialize();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    runApp(const SafeRideApp());
  } catch (e) {
    runApp(const SafeRideErrorApp());
  }
}

class SafeRideApp extends StatelessWidget {
  const SafeRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminPanelScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/book-ride': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final rideId = args?['rideId'] as String?;
          return BookRideScreen(rideId: rideId);
        },
        '/booking-history': (context) => const BookingHistoryScreen(),
        '/booking': (context) => const BookingScreen(),
        '/driver-profile': (context) => const DriverProfileScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/passenger-dashboard': (context) => const PassengerDashboardScreen(),
        '/driver-dashboard': (context) => const DriverDashboardScreen(),
        '/post-ride': (context) => const PostRideScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/ride-list': (context) => const RideListScreen(),
        '/support': (context) => const SupportCenterScreen(),
        '/rides': (context) => const RideListScreen(),
        '/premium': (context) => MonetizationDashboardScreen(),
        '/driver-earnings': (context) => const DriverEarningsScreen(),
        '/monetization-dashboard': (context) =>
            const MonetizationDashboardScreen(),
        '/admin-notifications': (context) => const AdminNotificationsScreen(),
        '/admin-analytics': (context) => const AdminAnalyticsScreen(),
        '/admin-users': (context) => const AdminUsersScreen(),
        '/admin-content': (context) => const AdminContentScreen(),
        '/admin-payments': (context) => const AdminPaymentsScreen(),
        '/chat': (context) =>
            const ChatScreen(otherUserId: '', otherUserName: ''),
      },
    );
  }
}

class SafeRideErrorApp extends StatelessWidget {
  const SafeRideErrorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRide',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.red[50],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SafeRide'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 100),
                const SizedBox(height: 20),
                const Text(
                  'Connection Error',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please check your internet connection and try again.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => main(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return const LoginScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: AuthService().getCurrentUserModel(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              if (userSnapshot.hasError || userSnapshot.data == null) {
                return const LoginScreen();
              }
              final userModel = userSnapshot.data!;
              switch (userModel.userType) {
                case UserType.admin:
                  return const AdminPanelScreen();
                case UserType.driver:
                  return const DriverDashboardScreen();
                case UserType.passenger:
                  return const PassengerDashboardScreen();
                default:
                  return const LoginScreen();
              }
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
