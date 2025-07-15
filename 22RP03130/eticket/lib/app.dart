import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_in_screen.dart';
import 'splash_screen.dart';
import 'admin_home_screen.dart';
import 'organizer_home_screen.dart';
import 'user_home_screen.dart';
import 'role_selection_screen.dart';
// Import your home screens for each role
// import 'user_home_screen.dart';
// import 'organizer_home_screen.dart';
// import 'admin_home_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext ctx) {
    if (_showSplash) {
      return const MaterialApp(home: SplashScreen(), debugShowCheckedModeBanner: false);
    }
    return MaterialApp(
      home: AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SignInScreen();
        }
        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final data = snap.data!.data();
            if (data == null || !data.containsKey('role')) {
              return RoleSelectionScreen(user: user);
            }
            final role = data['role'];
            if (role == 'admin') {
              return AdminHomeScreen();
            } else if (role == 'organizer') {
              return OrganizerHomeScreen();
            } else if (role == 'user') {
              return UserHomeScreen();
            } else {
              return Scaffold(body: Center(child: Text('Unknown role: $role')));
            }
          },
        );
      },
    );
  }
} 