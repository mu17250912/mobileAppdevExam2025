import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login.dart';
import 'screens/employee_dashboard.dart';
import 'screens/manager_dashboard.dart';
import 'screens/employee_notifications.dart';
import 'screens/manager_notifications.dart';
import 'screens/employee_reports.dart';
import 'screens/manager_reports_viewer.dart';
import 'screens/employee_settings.dart';
import 'screens/manager_profile_settings.dart';
import 'screens/manager_employee_list.dart';
import 'screens/manager_task_list.dart';
import 'screens/manager_create_edit_task.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
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
      path: '/home',
      builder: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const LoginScreen();
        }
        // TODO: Replace with real role logic
        return const EmployeeDashboard();
      },
    ),
    GoRoute(
      path: '/tasks',
      builder: (context, state) {
        // TODO: Replace with real role logic
        return const ManagerTaskList();
      },
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) {
        // TODO: Replace with real role logic
        return const ManagerReportsViewer();
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) {
        // TODO: Replace with real role logic
        return const ManagerNotifications();
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) {
        // TODO: Replace with real role logic
        return const ManagerProfileSettings();
      },
    ),
    GoRoute(
      path: '/employees',
      builder: (context, state) => const ManagerEmployeeList(),
    ),
    GoRoute(
      path: '/create-task',
      builder: (context, state) => const ManagerCreateEditTask(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'OrgBridge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
