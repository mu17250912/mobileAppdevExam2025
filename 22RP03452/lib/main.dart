import 'package:flutter/material.dart';
import 'package:schoolmessenge/screens/splash_screen.dart';
import 'package:schoolmessenge/screens/role_selection_screen.dart';
import 'package:schoolmessenge/screens/teacher_login_screen.dart';
import 'package:schoolmessenge/screens/parent_login_screen.dart';
import 'package:schoolmessenge/screens/teacher_signup_screen.dart';
import 'package:schoolmessenge/screens/parent_signup_screen.dart';
import 'package:schoolmessenge/screens/teacher_dashboard.dart';
import 'package:schoolmessenge/screens/parent_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SchoolMessengerApp());
}

class SchoolMessengerApp extends StatelessWidget {
  const SchoolMessengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/role-selection',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/t-login',
          builder: (context, state) => const TeacherLoginScreen(),
        ),
        GoRoute(
          path: '/p-login',
          builder: (context, state) => const ParentLoginScreen(),
        ),
        GoRoute(
          path: '/t-signup',
          builder: (context, state) => const TeacherSignupScreen(),
        ),
        GoRoute(
          path: '/p-signup',
          builder: (context, state) => const ParentSignupScreen(),
        ),
        GoRoute(
          path: '/t-dashboard',
          builder: (context, state) {
            final userData = state.extra as Map<String, dynamic>?;
            if (userData != null) {
              return TeacherDashboard(userData: userData);
            }
            return const TeacherLoginScreen();
          },
        ),
        GoRoute(
          path: '/p-dashboard',
          builder: (context, state) {
            final userData = state.extra as Map<String, dynamic>?;
            if (userData != null) {
              return ParentDashboard(userData: userData);
            }
            return const ParentLoginScreen();
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'SchoolMessenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'NotoSans'),
      ),
      routerConfig: router,
    );
  }
}
