import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/user_service.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final String? redirectTo;

  const AuthGuard({
    super.key,
    required this.child,
    this.redirectTo = '/login',
  });

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in and session is not destroyed
    if (UserService.shouldRedirectToLogin()) {
      // Redirect to login after a brief delay to allow the widget to build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          // Use replace to prevent back navigation
          context.go(redirectTo!);
        }
      });
      
      // Show loading screen while redirecting
      return Scaffold(
        backgroundColor: const Color(0xFF145A32),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 80,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Checking authentication...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User is logged in, show the protected content
    return child;
  }
}

// Enhanced AuthGuard that prevents back navigation and strictly blocks access
class SecureAuthGuard extends StatelessWidget {
  final Widget child;
  final String? redirectTo;

  const SecureAuthGuard({
    super.key,
    required this.child,
    this.redirectTo = '/login',
  });

  @override
  Widget build(BuildContext context) {
    // Strict check for authentication - any issue redirects to login
    if (!UserService.isLoggedIn || UserService.isSessionDestroyed) {
      // Immediately redirect to login and clear navigation stack
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          // Use go to completely clear the navigation stack
          context.go(redirectTo!);
        }
      });
      
      // Show strict access denied screen
      return Scaffold(
        backgroundColor: const Color(0xFF145A32),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 80,
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.lock,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please log in to access this page',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Redirecting to login...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User is logged in and session is valid, show the protected content
    return child;
  }
}

// Widget to show when user is not authenticated
class UnauthenticatedWidget extends StatelessWidget {
  final VoidCallback? onLoginPressed;

  const UnauthenticatedWidget({
    super.key,
    this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF145A32),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 100,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Authentication Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please log in to access this feature.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onLoginPressed ?? () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF145A32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 