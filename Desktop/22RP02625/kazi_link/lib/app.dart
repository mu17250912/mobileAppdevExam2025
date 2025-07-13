import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/reviews/reviews_screen.dart';
import 'screens/jobs/job_list_screen.dart';
import 'screens/messaging/messaging_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/chat_provider.dart';

class KaziLinkApp extends StatelessWidget {
  const KaziLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'KaziLink',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/role-selection': (context) => const RoleSelectionScreen(),
              '/auth': (context) => const AuthScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/reviews': (context) => const ReviewsScreen(),
              '/jobs': (context) => const JobListScreen(),
              '/messaging': (context) => const MessagingScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/payment': (context) => const PaymentScreen(),
              // ...other routes
            },
          );
        },
      ),
    );
  }
} 