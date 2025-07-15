import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/add_student_form.dart';
import 'screens/add_grades_screen.dart';
import 'screens/take_attendance_screen.dart';
import 'screens/add_course_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/premium_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/freemium_service.dart';
import 'services/security_service.dart';
import 'services/reliability_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  print('main started');
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    // MobileAds.instance.initialize(); // AdMob initialization deleted as requested
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AppInitializer());
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  Future<void> _initializeApp() async {
    print('AppInitializer: _initializeApp started');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Enable Firestore offline persistence for mobile only
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    } else {
      try {
        await FirebaseFirestore.instance.enablePersistence();
      } catch (e) {
        print('Firestore persistence error (web): $e');
        // Ignore if already enabled or not supported
      }
    }
    // Set persistence for web only if supported
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (e) {
        debugPrint('Error setting Firebase Auth persistence: $e');
      }
    }
    // Initialize services
    final freemiumService = FreemiumService();
    // Removed: final adService = AdService();
    // Removed: await adService.initialize();
    // Removed: await AnalyticsService.initialize();
    // Initialize reliability monitoring
    await ReliabilityService.initialize();
    print('AppInitializer: _initializeApp finished');
  }

  @override
  Widget build(BuildContext context) {
    print('AppInitializer: build called');
    return FutureBuilder<void>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('AppInitializer: waiting for initialization');
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          print('AppInitializer: initialization error: ${snapshot.error}');
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'Initialization error: \n\n${snapshot.error.toString()}',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        } else {
          print('AppInitializer: initialization complete, building MyApp');
          return const MyApp();
        }
      },
    );
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduManage',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/student_dashboard': (context) => const StudentDashboard(),
        '/add_student': (context) => const AddStudentForm(),
        '/add_grades': (context) => const AddGradesScreen(),
        '/take_attendance': (context) => const TakeAttendanceScreen(),
        '/add_course': (context) => const AddCourseScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/premium': (context) => const PremiumScreen(),
        '/students': (context) => const StudentsPage(),
        '/grades': (context) => const GradesPage(),
        '/courses': (context) => const CoursesPage(),
        '/attendances': (context) => const AttendancesPage(),
      },
    );
  }
}

class StudentsPage extends StatelessWidget {
  const StudentsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: const Center(child: Text('Students Page')),
    );
  }
}

class GradesPage extends StatelessWidget {
  const GradesPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grades')),
      body: const Center(child: Text('Grades Page')),
    );
  }
}

class CoursesPage extends StatelessWidget {
  const CoursesPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: const Center(child: Text('Courses Page')),
    );
  }
}

class AttendancesPage extends StatelessWidget {
  const AttendancesPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendances')),
      body: const Center(child: Text('Attendances Page')),
    );
  }
}

