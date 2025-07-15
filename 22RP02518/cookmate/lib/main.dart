import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'views/splash_screen.dart';
import 'views/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'views/home_screen.dart';
import 'models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'views/login_screen.dart'; // Remove or comment out if not used

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(CookMateApp());
}

class CookMateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CookMate',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: SplashToAuth(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashToAuth extends StatefulWidget {
  @override
  State<SplashToAuth> createState() => _SplashToAuthState();
}

class _SplashToAuthState extends State<SplashToAuth> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainAuthLogic()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => SplashScreen();
}

// Extract the main auth logic into its own widget
class MainAuthLogic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return FutureBuilder<
              Map<String, dynamic>?>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get()
                .then((doc) => doc.data()),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final appUser = AppUser.fromFirebaseUserAndData(
                  snapshot.data!, userSnapshot.data);
              return HomeScreen(currentUser: appUser);
            },
          );
        }
        return AuthScreen(); // Use AuthScreen for login
      },
    );
  }
}
