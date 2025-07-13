import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'landing_page.dart';
import 'login_screen.dart';
import 'user_type_selection_screen.dart';
import 'splash_screen.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isCheckingUserType = false;
  String? _lastCheckedUserId;
  // Remove _showSplash and all splash delay logic

  @override
  void initState() {
    super.initState();
    print('AuthGate: initState called');
  }

  Future<void> _checkUserType(User? user) async {
    if (user == null) return;
    if (_lastCheckedUserId == user.uid) return; // Already checked this user
    _lastCheckedUserId = user.uid;
    print('AuthGate: _checkUserType for user: ${user.email}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() { _isCheckingUserType = true; });
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUserData();
      print('AuthGate: UserProvider loaded, userType: ${userProvider.userType}');
      if (userProvider.userType == null || userProvider.userType!.isEmpty) {
        print('AuthGate: User has no type, navigating to UserTypeSelectionScreen');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const UserTypeSelectionScreen()),
            );
          });
        }
      } else {
        print('AuthGate: User has type: ${userProvider.userType}, navigating to HomeScreen');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          });
        }
      }
    } catch (e) {
      print('AuthGate: Error checking user type: $e');
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() { _isCheckingUserType = false; });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show splash while waiting for auth state
          return const SplashScreen();
        }
        if (snapshot.connectionState == ConnectionState.active && user != null) {
          _checkUserType(user);
        }
        if (_isCheckingUserType) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }
        if (user != null) {
          // While waiting for navigation, show loading
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up your account...'),
                ],
              ),
            ),
          );
        }
        return LandingPage(
          onGetStarted: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        );
      },
    );
  }
} 