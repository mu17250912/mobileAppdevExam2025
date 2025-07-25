import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/auth/auth_screen.dart' as auth;

class AppRouter {
  static Widget getInitialRoute() {
    // Always start with home screen for quick testing
    return const HomeScreen();
  }

  static Map<String, WidgetBuilder> get routes => {
    '/auth': (context) => const auth.AuthScreen(),
    '/login': (context) => const auth.AuthScreen(), // Placeholder for login screen
    // Add other routes as needed
  };
} 