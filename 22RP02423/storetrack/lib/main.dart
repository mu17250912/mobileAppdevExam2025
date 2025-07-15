import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/sales_service.dart';
import 'services/premium_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/cashier_dashboard.dart';
import 'screens/product_management.dart';
import 'screens/add_product_screen.dart';
import 'screens/sales_interface.dart';
import 'screens/shopping_cart_screen.dart';
import 'screens/premium_features_screen.dart';
import 'screens/coming_soon_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StoreTrackApp());
}

class StoreTrackApp extends StatelessWidget {
  const StoreTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ProductService()),
        ChangeNotifierProvider(create: (_) => SalesService()),
        ChangeNotifierProvider(create: (_) => PremiumService()),
      ],
      child: MaterialApp(
        title: 'StoreTrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667eea),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Segoe UI',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF667eea),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/admin-dashboard': (context) => const AdminDashboard(),
          '/cashier-dashboard': (context) => const CashierDashboard(),
          '/product-management': (context) => const ProductManagement(),
          '/add-product': (context) => const AddProductScreen(),
          '/sales-interface': (context) => const SalesInterface(),
          '/shopping-cart': (context) => const ShoppingCartScreen(),
          '/premium-features': (context) => const PremiumFeaturesScreen(),
          '/coming-soon': (context) => const ComingSoonScreen(
            featureId: '',
            featureTitle: '',
            featureDescription: '',
            featureIcon: Icons.star,
          ),
          '/sales-history': (context) => const SalesHistoryScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
