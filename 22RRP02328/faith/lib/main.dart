import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Services
import 'services/notification_service.dart';
import 'services/storage_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/event_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/booking_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/user_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/messaging/chat_list_screen.dart';
import 'screens/messaging/chat_screen.dart';
import 'screens/subscription/subscription_plans_screen.dart';
import 'screens/subscription/subscription_details_screen.dart';
import 'screens/event/create_event_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'screens/payment/payment_history_screen.dart';
import 'screens/notification/notification_screen.dart';
import 'screens/booking/booking_history_screen.dart';

// Utils
import 'utils/constants.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with actual configuration
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDj1KILU-2oKxI1vYcJnk2HNGUrYPcLYxw",
      authDomain: "faith-2025.firebaseapp.com",
      projectId: "faith-2025",
      storageBucket: "faith-2025.firebasestorage.app",
      messagingSenderId: "966900733600",
      appId: "1:966900733600:android:621d65685f43c94a10dbc5",
    ),
  );
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize services
  await NotificationService.initialize();
  await StorageService.initialize();
  
  runApp(const FaithApp());
}

class FaithApp extends StatelessWidget {
  const FaithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: GetMaterialApp(
        title: 'Faith - Event Planning Platform',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
        getPages: [
          GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
          GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
          GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
          GetPage(name: AppRoutes.userDashboard, page: () => const UserDashboard()),
          GetPage(name: AppRoutes.adminDashboard, page: () => const AdminDashboard()),
          GetPage(name: '/chat-list', page: () => const ChatListScreen()),
          GetPage(name: '/chat', page: () => const ChatScreen(chatId: '')),
          GetPage(name: '/subscription-plans', page: () => const SubscriptionPlansScreen()),
          GetPage(name: '/subscription-details', page: () => const SubscriptionDetailsScreen()),
          GetPage(name: '/create-event', page: () => const CreateEventScreen()),
          GetPage(name: '/payment', page: () => const PaymentScreen()),
          GetPage(name: '/payment-history', page: () => const PaymentHistoryScreen()),
          GetPage(name: '/notifications', page: () => const NotificationScreen()),
          GetPage(name: '/booking-history', page: () => const BookingHistoryScreen()),
        ],
      ),
    );
  }
}
