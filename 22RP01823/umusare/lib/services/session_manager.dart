import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'user_service.dart';

class SessionManager {
  static bool _isInitialized = false;

  // Initialize session on app startup
  static Future<void> initializeSession(BuildContext context) async {
    if (_isInitialized) return;

    try {
      // Load user from local storage
      final user = await UserService.loadUserFromStorage();
      
      if (user != null && UserService.isLoggedIn) {
        // User is logged in, redirect to home
        if (context.mounted) {
          context.go('/home');
        }
      } else {
        // User is not logged in, redirect to login
        if (context.mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      print('Error initializing session: $e');
      // On error, redirect to login
      if (context.mounted) {
        context.go('/login');
      }
    }

    _isInitialized = true;
  }

  // Check if session is valid
  static bool isSessionValid() {
    return UserService.isLoggedIn && !UserService.isSessionDestroyed;
  }

  // Force logout and clear all data
  static Future<void> forceLogout(BuildContext context) async {
    UserService.destroySession();
    
    if (context.mounted) {
      // Clear navigation stack and redirect to login
      context.go('/login');
    }
  }

  // Handle session timeout
  static Future<void> handleSessionTimeout(BuildContext context) async {
    UserService.destroySession();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Clear navigation stack and redirect to login
      context.go('/login');
    }
  }

  // Reset session state (for testing)
  static void resetSession() {
    UserService.resetSessionState();
    _isInitialized = false;
  }
} 