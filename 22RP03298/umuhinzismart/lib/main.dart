import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

// Services
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'services/offline_service.dart';
import 'services/error_reporting_service.dart';
import 'services/performance_service.dart';
import 'services/premium_service.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'welcome_screen.dart';
import 'splash_screen.dart';
import 'widgets/auth_guard.dart';

// Configuration
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        Provider<AnalyticsService>(create: (_) => AnalyticsService()),
        Provider<ErrorReportingService>(create: (_) => ErrorReportingService()),
        Provider<PerformanceService>(create: (_) => PerformanceService()),
        Provider<OfflineService>(create: (_) => OfflineService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<PremiumService>(create: (_) => PremiumService()),
      ],
      child: MaterialApp(
        title: 'UMUHINZI Smart',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const AppInitializer(),
        onGenerateRoute: _generateRoute,
        builder: (context, child) {
          return _buildErrorHandler(child!);
        },
      ),
    );
  }

  Widget _buildErrorHandler(Widget child) {
    // Set up global error handler
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Report error to our service
      ErrorReportingService.reportError(
        errorType: 'widget_error',
        errorMessage: details.exception.toString(),
        error: details.exception,
        stackTrace: details.stack,
      );
      
      return Material(
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'re working on fixing the problem.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  SystemNavigator.pop();
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      );
    };
    
    return child;
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/dashboard':
        // Use AuthWrapper to ensure authentication
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      case '/welcome':
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
    }
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      requireAuth: true,
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.isLoading) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Verifying authentication...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Check if user is properly authenticated with valid credentials
          if (authService.isAuthenticated && authService.currentUser != null) {
            print('✅ AuthWrapper: User authenticated, showing dashboard');
            return const DashboardScreen();
          }
          
          // User is not authenticated, redirect to login
          print('ℹ️ AuthWrapper: User not authenticated, redirecting to login');
          return const LoginScreen();
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.wait([
        _initializeAnalytics(),
        _initializeErrorReporting(),
        _initializePerformance(),
        _initializeOffline(),
        _initializeNotifications(),
      ]);
      if (!mounted) return;
      setState(() => _initialized = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _initializeAnalytics() async {
    try {
      await AnalyticsService.trackFeatureUsage(
        feature: 'analytics_initialized',
        userRole: 'system',
      );
      print('✅ Analytics service initialized');
    } catch (e) {
      print('❌ Analytics initialization failed: $e');
    }
  }

  Future<void> _initializeErrorReporting() async {
    try {
      await ErrorReportingService.reportError(
        errorType: 'service_initialization',
        errorMessage: 'Error reporting service initialized',
        additionalData: {'status': 'initialized'},
      );
      print('✅ Error reporting service initialized');
    } catch (e) {
      print('❌ Error reporting initialization failed: $e');
    }
  }

  Future<void> _initializePerformance() async {
    try {
      await PerformanceService().trackFeatureUsage(
        feature: 'performance_monitoring',
        userRole: 'system',
      );
      print('✅ Performance service initialized');
    } catch (e) {
      print('❌ Performance initialization failed: $e');
    }
  }

  Future<void> _initializeOffline() async {
    try {
      final offlineService = OfflineService();
      await offlineService.syncPendingActions();
      print('✅ Offline service initialized');
    } catch (e) {
      print('❌ Offline initialization failed: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService.initialize();
      print('✅ Notification service initialized');
    } catch (e) {
      print('❌ Notification initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Initialization error: $_error'));
    }
    if (!_initialized) {
      return const SplashScreen();
    }
    // Now show your real app (e.g., LoginScreen, etc.)
    return const LoginScreen(); // or your main app screen
  }
}
