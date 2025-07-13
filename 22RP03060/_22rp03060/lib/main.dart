import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/events/create_event_screen.dart';
import 'services/auth_service.dart';
import 'services/ads_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Test Firebase configuration
    print('Current platform: ${defaultTargetPlatform}');
    print('Is web: $kIsWeb');
    final options = DefaultFirebaseOptions.currentPlatform;
    print('Firebase options: ${options.appId}');
    print('Firebase project: ${options.projectId}');
    print('Firebase auth domain: ${options.authDomain}');

    // Initialize Google Mobile Ads
    await AdsService().initialize();

  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  runApp(const EventEaseApp());
}

class EventEaseApp extends StatelessWidget {
  const EventEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            routerConfig: _createRouter(authProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isSplash = state.matchedLocation == '/splash';
        final isAuthRoute = state.matchedLocation == '/login' || 
                           state.matchedLocation == '/register';
        
        // If on splash screen, let it handle its own navigation
        if (isSplash) return null;
        
        // If not authenticated and trying to access protected route, go to login
        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }
        
        // If authenticated and trying to access auth routes, go to home
        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/event/:id',
          builder: (context, state) {
            final eventId = state.pathParameters['id']!;
            return EventDetailScreen(eventId: eventId);
          },
        ),
        GoRoute(
          path: '/create-event',
          builder: (context, state) => const CreateEventScreen(),
        ),
      ],
    );
  }
}
