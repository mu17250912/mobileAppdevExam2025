import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/app_constants.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/property_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/add_property_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';

// Import new services
import 'services/analytics_service.dart';
import 'services/security_service.dart';
import 'services/subscription_service.dart';
import 'services/ad_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBOq_H5PYPsMMzaFmz4f16qEVf22XJ0_R0",
        authDomain: "umukomesiyoneri.firebaseapp.com",
        projectId: "umukomesiyoneri",
        storageBucket: "umukomesiyoneri.firebasestorage.app",
        messagingSenderId: "874478680782",
        appId: "1:874478680782:web:79b2ba9fae89a477ca6e9f",
        measurementId: "G-061VS8VTFX",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // Initialize Firebase Crashlytics
  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  // Initialize all services
  await _initializeServices();

  runApp(const CommissionerApp());
}

Future<void> _initializeServices() async {
  try {
    // Initialize Analytics Service
    await AnalyticsService().initialize();
    
    // Initialize Security Service
    await SecurityService().initialize();
    
    // Initialize Subscription Service (only on mobile)
    if (!kIsWeb) {
      await SubscriptionService().initialize();
    }
    
    // Initialize Ad Service (only on mobile)
    if (!kIsWeb) {
      await AdService().initialize();
    }
    
    debugPrint('All services initialized successfully');
  } catch (e) {
    debugPrint('Error initializing services: $e');
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }
}

class CommissionerApp extends StatelessWidget {
  const CommissionerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Load current user profile on app start
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthProvider>().loadCurrentUser();
          });
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(),
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
                ),
              ),
              cardTheme: CardThemeData(
                color: AppColors.card,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
              ),
            ),
            routes: {
              '/search': (context) => const SearchScreen(),
              // Add other named routes here if needed
            },
            home: StreamBuilder<fb_auth.User?>(
              stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  final authProvider = Provider.of<AuthProvider>(context);
                  final user = authProvider.currentUser;
                  if (user != null && (user.role == 'admin' || user.isCommissioner)) {
                    return const AdminDashboardScreen();
                  }
                  return const MainScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.textTertiary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.search_outlined, Icons.search, 'Search'),
                _buildNavItem(2, Icons.favorite_outline, Icons.favorite, 'Favorites'),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPropertyScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textInverse,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    Widget navContent = Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.primary : AppColors.textTertiary,
            size: AppSizes.iconMd,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.primary : AppColors.textTertiary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
    if (kIsWeb) {
      navContent = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: navContent,
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: navContent,
    );
  }
}
