import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_session_screen.dart';
import 'screens/set_goals_screen.dart';
import 'screens/find_partner_screen.dart';
import 'screens/join_session_screen.dart';
import 'screens/session_details_screen.dart';
import 'screens/update_profile_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/connection_sent_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/joined_sessions_screen.dart';
import 'screens/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(StudySyncApp());
}

// Example function to add a session to Firestore
Future<void> addSession(Map<String, dynamic> sessionData) async {
  await FirebaseFirestore.instance.collection('sessions').add(sessionData);
}

class StudySyncApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudySync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFEAD3D3), // light pink
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/signup': (context) => SignUpScreen(),
        '/signin': (context) => SignInScreen(),
        '/connection-sent': (context) => ConnectionSentScreen(),
        '/home': (context) => HomeScreen(),
        '/create-session': (context) => CreateSessionScreen(),
        '/find-partner': (context) => FindPartnerScreen(),
        '/session-details': (context) => SessionDetailsScreen(),
        '/update-profile': (context) => UpdateProfileScreen(),
        '/set-goals': (context) => SetGoalsScreen(),
        '/joined-sessions': (context) => JoinedSessionsScreen(),
        '/notification': (context) => NotificationScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/join-session') {
          final partner = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => JoinSessionScreen(partner: partner),
          );
        }
        return null;
      },
    );
  }
} 