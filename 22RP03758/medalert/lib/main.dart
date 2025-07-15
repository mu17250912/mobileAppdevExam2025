import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/medication_list_screen.dart';
import 'screens/medication_adherence_screen.dart';
import 'screens/medication_calendar_screen.dart';
import 'screens/medication_form_screen.dart';
import 'screens/caregiver_dashboard_screen.dart';
import 'screens/caregiver_assignment_screen.dart';
import 'screens/caregiver_info_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/multi_user_profiles_screen.dart';
import 'screens/patient_analytics_screen.dart';
import 'screens/caregiver_analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/referral_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/offline_service.dart';
import 'services/settings_service.dart';
import 'services/monetization_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/sustainability_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyA06BeNwH5f0xp7A61Of1ccJ_X0X4LPFyo',
          authDomain: 'medalert-689ce.firebaseapp.com',
          projectId: 'medalert-689ce',
          storageBucket: 'medalert-689ce.firebasestorage.app',
          messagingSenderId: '997303059485',
          appId: '1:997303059485:web:9298d9cec50f3a0865b2f4',
          measurementId: 'G-ZKDXSXEMHH',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    
    debugPrint('Firebase initialized successfully');
    
    // Initialize services
    await NotificationService().initialize();
    await OfflineService().initialize();
    await MonetizationService().initialize();
    await FirebaseAnalyticsService().initialize();
    await SustainabilityService().initialize();
    // FirestoreService is a singleton, no initialization needed
    
    debugPrint('App initialization completed');
  } catch (e) {
    debugPrint('Error during app initialization: $e');
  }
  
  runApp(const MedAlertApp());
}

class MedAlertApp extends StatelessWidget {
  const MedAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => SettingsService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'MedAlert',
            debugShowCheckedModeBanner: false,
            theme: themeService.getThemeData(),
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/patient_home': (context) => const PatientHomeScreen(),
              '/medications': (context) => const MedicationListScreen(),
              '/medication_adherence': (context) => const MedicationAdherenceScreen(),
              '/medication_calendar': (context) => const MedicationCalendarScreen(),
              '/medication_form': (context) => const MedicationFormScreen(),
              '/caregiver_dashboard': (context) => const CaregiverDashboardScreen(),
              '/caregiver_assignment': (context) => const CaregiverAssignmentScreen(),
              '/caregiver_info': (context) => const CaregiverInfoScreen(),
              '/emergency_contacts': (context) => const EmergencyContactsScreen(),
              '/multi_user_profiles': (context) => const MultiUserProfilesScreen(),
              '/patient_analytics': (context) => const PatientAnalyticsScreen(),
              '/caregiver_analytics': (context) => const CaregiverAnalyticsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/profile_edit': (context) => const ProfileEditScreen(),
              '/subscription': (context) => const SubscriptionScreen(),
              '/insights': (context) => const InsightsScreen(),
              '/referral': (context) => const ReferralScreen(),
            },
          );
        },
      ),
    );
  }
}
