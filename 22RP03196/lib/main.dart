import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/user/reminders_screen.dart';
import 'screens/user/free_workouts_screen.dart';
import 'screens/user/favorites_workouts_screen.dart';
import 'screens/user/notifications_screen.dart';
import 'screens/user/areas_screen.dart';
import 'screens/user/notifications_stats_screen.dart';
import 'screens/premium/go_premium_screen.dart';
import 'screens/premium/premium_pricing_screen.dart';
import 'screens/premium/premium_checkout_screen.dart';
import 'screens/premium/premium_success_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/workout_step_screen.dart';
import 'screens/user/workout_rating_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'screens/user/book_trainer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Firebase Analytics
  final analytics = FirebaseAnalytics.instance;
  // Log app open event
  await analytics.logAppOpen();
  runApp(FitnessApp(analytics: analytics));
}

class FitnessApp extends StatelessWidget {
  final FirebaseAnalytics analytics;
  const FitnessApp({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FITINITY',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22A6F2)),
        useMaterial3: true,
      ),
      navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(),
        '/plans': (context) => PlansScreen(),
        '/reminders': (context) => RemindersScreen(),
        '/free_workouts': (context) => FreeWorkoutsScreen(),
        '/favorites_workouts': (context) => FavoritesWorkoutsScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/areas': (context) => AreasScreen(),
        '/notifications_stats': (context) => NotificationsStatsScreen(),
        '/go_premium': (context) => GoPremiumScreen(),
        '/premium_pricing': (context) => PremiumPricingScreen(),
        '/premium_checkout': (context) => PremiumCheckoutScreen(),
        '/premium_success': (context) => PremiumSuccessScreen(),
        '/profile': (context) => ProfileScreen(),
        '/workout_step': (context) => WorkoutStepScreen(),
        '/workout_rating': (context) => WorkoutRatingScreen(),
        '/book_trainer': (context) => BookTrainerScreen(),
      },
    );
  }
}
