import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_account_screen.dart';
import 'models/user.dart';
import 'screens/dashboard_page.dart';  // <-- Import your new dashboard page
import 'services/water_log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WaterSaverApp());
}

class WaterSaverApp extends StatefulWidget {
  const WaterSaverApp({Key? key}) : super(key: key);

  @override
  State<WaterSaverApp> createState() => _WaterSaverAppState();
}

class _WaterSaverAppState extends State<WaterSaverApp> {
  User? _user;
  bool _splashDone = false;
  bool _loggedIn = false;
  bool _showOnboarding = false;
  bool _showCreateAccount = false;
  bool _isNewlyRegistered = false;
  final WaterLogService _waterLogService = WaterLogService();

  void _finishSplash() {
    setState(() {
      _splashDone = true;
    });
  }

  void _onLogin(User user) {
    setState(() {
      _user = user;
      _loggedIn = true;
      _showOnboarding = false;
      _isNewlyRegistered = false;
    });
  }

  void _onOnboardingComplete(User user) {
    setState(() {
      _user = user;
      _showOnboarding = false;
      _isNewlyRegistered = false;
    });
  }

  void _onCreateAccount() {
    setState(() {
      _showCreateAccount = true;
    });
  }

  void _onAccountCreated(User user) {
    setState(() {
      _user = user;
      _showCreateAccount = false;
      _showOnboarding = false;
      _isNewlyRegistered = false;
      _loggedIn = true;
    });
  }

  void _onBackToLogin() {
    setState(() {
      _showCreateAccount = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquTrack',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: !_splashDone
          ? SplashScreen(onFinish: _finishSplash)
          : _showCreateAccount
              ? CreateAccountScreen(
                  onAccountCreated: _onAccountCreated,
                  onBackToLogin: _onBackToLogin,
                )
              : _showOnboarding
                  ? OnboardingScreen(email: _user?.email ?? '', onComplete: _onOnboardingComplete)
                  : !_loggedIn
                      ? LoginScreen(
                          onLogin: _onLogin,
                          onCreateAccount: _onCreateAccount,
                        )
                      : DashboardPage(
                          user: _user!,
                          waterLogService: _waterLogService,
                        ),
    );
  }
}
