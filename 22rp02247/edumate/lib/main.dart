import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/notes/notes_screen.dart';
import 'screens/flashcards/flashcards_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/flashcard_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/progress_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDZcB6J1ROXbf_9PR22mK6ZTGX3zjmJ2YY",
        authDomain: "edumate-d9a45.firebaseapp.com",
        projectId: "edumate-d9a45",
        storageBucket: "edumate-d9a45.firebasestorage.app",
        messagingSenderId: "324809597451",
        appId: "1:324809597451:web:5c9e8e7a3cd335eb231d0e",
        measurementId: "G-L7B548LKC7",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  // Initialize Firebase Analytics
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  
  runApp(const EduMateApp());
}

class EduMateApp extends StatelessWidget {
  const EduMateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: MaterialApp(
        title: 'EduMate',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/notes': (_) => const NotesScreen(),
          '/flashcards': (_) => const FlashcardsScreen(),
          '/quiz': (_) => const QuizScreen(),
          '/progress': (_) => const ProgressScreen(),
        },
      ),
    );
  }
}