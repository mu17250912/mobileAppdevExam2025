import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/home_screen.dart';
import 'screens/report_alert_screen.dart';
import 'screens/alert_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This is generated by FlutterFire CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NeighborhoodAlertApp());
}

class NeighborhoodAlertApp extends StatelessWidget {
  const NeighborhoodAlertApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeighborhoodAlert',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: SplashScreen(),
      routes: {
        '/sign-in': (context) => const SignInScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/password-reset': (context) => const PasswordResetScreen(),
        '/home': (context) => const HomeScreen(),
        '/report-alert': (context) => const ReportAlertScreen(),
        '/alert-detail': (context) => const AlertDetailScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-user-management': (context) => const AdminUserManagementScreen(),
        '/emergency-contacts': (context) => const EmergencyContactsScreen(),
      },
    );
  }
}
