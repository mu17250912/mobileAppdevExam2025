import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'config/design_system.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/document_selection_screen.dart';
import 'screens/document_form_screen.dart';
import 'screens/document_preview_screen.dart';
import 'screens/document_history_screen.dart';
import 'screens/document_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/form_validation_error_screen.dart';
import 'screens/empty_state_screen.dart';
import 'screens/about_app_screen.dart';
import 'services/app_state.dart';
import 'dart:ui';

// Add this import for the animated bottom navigation bar
// If you want to use a package like convex_bottom_bar, add it to pubspec.yaml and import here
// import 'package:convex_bottom_bar/convex_bottom_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configure Firestore settings for better performance
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    // Enable debug logging in development
    if (kDebugMode) {
      print('[Main] Firebase initialized successfully');
    }
    
    runApp(const QuickDocsApp());
  } catch (e) {
    print('[Main] Firebase initialization failed: $e');
    // Still run the app but with error handling
    runApp(const QuickDocsApp());
  }
}

class QuickDocsApp extends StatelessWidget {
  const QuickDocsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const MainScaffold(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/document-selection',
          builder: (context, state) => const DocumentSelectionScreen(),
        ),
        GoRoute(
          path: '/document-form',
          builder: (context, state) => DocumentFormScreen(),
        ),
        GoRoute(
          path: '/document-preview',
          builder: (context, state) => const DocumentPreviewScreen(),
        ),
        GoRoute(
          path: '/document-history',
          builder: (context, state) => const MainScaffold(child: DocumentHistoryScreen()),
        ),
        GoRoute(
          path: '/document-detail',
          builder: (context, state) => const DocumentDetailScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const MainScaffold(child: SettingsScreen()),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const MainScaffold(child: NotificationsScreen()),
        ),
        GoRoute(
          path: '/form-validation-error',
          builder: (context, state) => const FormValidationErrorScreen(),
        ),
        GoRoute(
          path: '/empty-state',
          builder: (context, state) => const EmptyStateScreen(),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutAppScreen(),
        ),
      ],
      // Add error handling for routing
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Navigation Error', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('${state.error}', textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );

    return ChangeNotifierProvider(
      // Pass Firebase initialization status to AppState
      create: (_) => AppState(isFirebaseInitialized: true),
      child: MaterialApp.router(
        title: 'QuickDocs',
        debugShowCheckedModeBanner: false, // Remove debug banner
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.green,
            accentColor: AppColors.secondary,
            backgroundColor: AppColors.background,
          ).copyWith(
            secondary: AppColors.secondary,
            background: AppColors.background,
            surface: AppColors.surface,
            error: AppColors.error,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          // Add some performance optimizations
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routerConfig: _router,
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({Key? key, required this.child}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const List<_DrawerItem> _drawerItems = [
    _DrawerItem('Dashboard', Icons.dashboard, '/dashboard'),
    _DrawerItem('History', Icons.history, '/document-history'),
    _DrawerItem('Notifications', Icons.notifications, '/notifications'),
    _DrawerItem('Settings', Icons.settings, '/settings'),
  ];

  void _onDrawerItemTap(String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  void _onLogout() {
    Navigator.of(context).pop();
    // You may want to call a logout method from AppState here
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('QuickDocs', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade200, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Icon(Icons.description, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text('QuickDocs', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Documents Made Easy', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              ..._drawerItems.map((item) => ListTile(
                    leading: Icon(item.icon, color: Colors.green.shade700),
                    title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () => _onDrawerItemTap(item.route),
                  )),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                onTap: _onLogout,
              ),
            ],
          ),
        ),
      ),
      body: widget.child,
    );
  }
}

class _DrawerItem {
  final String label;
  final IconData icon;
  final String route;
  const _DrawerItem(this.label, this.icon, this.route);
}

// Add this helper class for better error handling
class FirebaseErrorHandler {
  static void handleError(dynamic error, String operation) {
    if (kDebugMode) {
      print('[Firebase Error] $operation: $error');
    }
    
    // You can add crash reporting here later
    // FirebaseCrashlytics.instance.recordError(error, null);
  }
}