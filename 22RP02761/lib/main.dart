import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/donor_dashboard.dart';
import 'screens/collector_dashboard.dart';
import 'services/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await RemoteConfigService().initialize(); // Initialize Remote Config
  runApp(BloodDonorApp());
}

class BloodDonorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Donor App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: Colors.red[300],
        scaffoldBackgroundColor: Color(0xFFF8F8F8),
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red[300],
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[300],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red[300],
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[300]!, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.red[300]),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.red[50]!,
          selectedColor: Colors.red[100]!,
          secondarySelectedColor: Colors.red[50]!,
          labelStyle: TextStyle(color: Colors.red[800]),
          secondaryLabelStyle: TextStyle(color: Colors.white),
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(
              welcomeMessage: RemoteConfigService().getWelcomeMessage(),
            ),
        '/register': (context) => RegisterScreen(),
        '/donor': (context) => DonorDashboard(),
        '/collector': (context) => CollectorDashboard(),
      },
    );
  }
}
