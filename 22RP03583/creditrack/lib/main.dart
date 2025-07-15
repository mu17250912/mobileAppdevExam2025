import 'package:flutter/material.dart';
import 'TRACK/splash_screen.dart';
import 'TRACK/login_screen.dart';
import 'TRACK/home_screen.dart';
import 'TRACK/loan_management_screen.dart';
import 'TRACK/add_borrower_screen.dart';
import 'TRACK/analytics_screen.dart' show AnalyticsScreen;
import 'TRACK/notifications_screen.dart' show NotificationsScreen, ContactsScreen, SettingsScreen;
import 'TRACK/signup_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Add these imports for the new screens
import 'TRACK/loan_management_screen.dart' show MessagesScreen;
import 'TRACK/contracts_screen.dart' show ContractsScreen;
import 'TRACK/payments_screen.dart' show PaymentsScreen;
import 'TRACK/profile_screen.dart';
import 'TRACK/contacts_screen.dart';
import 'TRACK/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Firebase if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(CreditTrackDemoApp());
}

class FirebaseErrorApp extends StatelessWidget {
  final String error;

  FirebaseErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Firebase Error')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Firebase Configuration Error',
                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Error: $error'),
              SizedBox(height: 16),
              Text('Please check:'),
              Text('1. Internet connection'),
              Text('2. Firebase project settings'),
              Text('3. Authentication is enabled in Firebase Console'),
            ],
          ),
        ),
      ),
    );
  }
}

class CreditTrackDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CreditTrack Demo',
       debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
      routes: {
        '/splash': (_) => SplashScreen(),
        '/login': (_) => LoginScreen(),
        '/home': (_) => HomeScreen(),
        '/loan': (_) => LoanManagementScreen(),
        '/add_borrower': (_) => AddBorrowerScreen(),
        '/analytics': (_) => AnalyticsScreen(),
        '/notifications': (_) => NotificationsScreen(),
        '/signup': (_) => SignupScreen(),
        '/contacts': (_) => ContactsScreen(),
        '/settings': (_) => SettingsScreen(),
        '/messages': (_) => MessagesScreen(),
        '/contracts': (_) => ContractsScreen(),
        '/payments': (_) => PaymentsScreen(),
        '/profile': (_) => ProfileScreen(),
      },
    );
  }
}

class DemoMenuScreen extends StatelessWidget {
  final List<Map<String, String>> screens = [
    {'title': 'Splash Screen', 'route': '/splash'},
    {'title': 'Login Screen', 'route': '/login'},
    {'title': 'Home Screen', 'route': '/home'},
    {'title': 'Loan Management', 'route': '/loan'},
    {'title': 'Add Borrower', 'route': '/add_borrower'},
    {'title': 'Analytics', 'route': '/analytics'},
    {'title': 'Notifications', 'route': '/notifications'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CreditTrack UI Demo')),
      body: ListView.builder(
        itemCount: screens.length,
        itemBuilder: (context, index) {
          final screen = screens[index];
          return ListTile(
            title: Text(screen['title']!),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, screen['route']!),
          );

        },
      ),
    );
  }
} 