import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class SessionTestWidget extends StatelessWidget {
  const SessionTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF145A32),
      appBar: AppBar(
        title: const Text('Session Test'),
        backgroundColor: const Color(0xFF145A32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Is Logged In: ${UserService.isLoggedIn}'),
                    Text('Session Destroyed: ${UserService.isSessionDestroyed}'),
                    Text('User ID: ${UserService.userId ?? 'None'}'),
                    Text('User Name: ${UserService.userName ?? 'None'}'),
                    Text('User Email: ${UserService.userEmail ?? 'None'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _testNormalLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Normal Logout'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _testSessionDestruction(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Session Destruction'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _testBackNavigation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Back Navigation'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _testProtectedPageAccess(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Protected Page Access'),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Test Normal Logout: Clears user data but allows back navigation\n'
                      '2. Test Session Destruction: Completely destroys session and prevents back navigation\n'
                      '3. Test Back Navigation: Try to go back after logout (should redirect to login)\n'
                      '4. Test Protected Page Access: Try to access protected pages after logout',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testNormalLogout(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.clearSession();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Normal logout completed. Back navigation may still work.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testSessionDestruction(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.signOut();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session destroyed! Back navigation is now blocked.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Wait a moment then redirect to login
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testBackNavigation(BuildContext context) {
    if (UserService.isSessionDestroyed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session is destroyed! Redirecting to login...'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Redirect to login
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session is still active. You can navigate back.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _testProtectedPageAccess(BuildContext context) {
    if (!UserService.isLoggedIn || UserService.isSessionDestroyed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied! Redirecting to login...'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Try to access a protected page - should redirect to login
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access granted! You can visit protected pages.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
} 