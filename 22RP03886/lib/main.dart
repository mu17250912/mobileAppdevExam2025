import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/task_provider.dart';
import 'providers/note_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/analytics_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/task_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/register_screen.dart';
import 'screens/logout_screen.dart';
import 'screens/subscription_management_screen.dart';
import 'screens/analytics_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Daily Planner',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreenWrapper(),
        routes: {
          '/auth': (context) => AuthScreen(),
          '/register': (context) => RegisterScreen(),
          '/home': (context) => HomeScreen(),
          '/tasks': (context) => TaskScreen(),
          '/notes': (context) => NotesScreen(),
          '/profile': (context) => ProfileScreen(),
          '/subscription': (context) => SubscriptionScreen(),
          '/payment': (context) => PaymentScreen(
            plan: 'monthly',
            price: '5',
            onPaymentSuccess: () {
              Navigator.pop(context);
            },
          ),
          '/calendar': (context) => CalendarScreen(),
          '/logout': (context) => LogoutScreen(),
          '/subscription-management': (context) => SubscriptionManagementScreen(),
          '/analytics-dashboard': (context) => AnalyticsDashboardScreen(),
        },
      ),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  @override
  _SplashScreenWrapperState createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Wait for 3 seconds to show splash screen
    await Future.delayed(Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Check if user is authenticated
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.userProfile;
    
    if (user != null && user.displayName != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen();
  }
}
