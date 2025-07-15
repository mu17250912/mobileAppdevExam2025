import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  final bool requireAuth;

  const AuthGuard({
    super.key,
    required this.child,
    this.requireAuth = true,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Show loading while checking authentication
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Verifying authentication...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // If authentication is required and user is not authenticated
        if (widget.requireAuth && !authService.isAuthenticated) {
          print('🚫 AuthGuard: Access denied - user not authenticated');
          return const LoginScreen();
        }

        // If authentication is required and user is authenticated but session is invalid
        if (widget.requireAuth && authService.isAuthenticated) {
          // Check session validity asynchronously
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkSessionValidity(context, authService);
          });
        }

        // User is authenticated or authentication is not required
        print('✅ AuthGuard: Access granted');
        return widget.child;
      },
    );
  }

  Future<void> _checkSessionValidity(BuildContext context, AuthService authService) async {
    try {
      final isValid = await authService.isSessionValid();
      if (!mounted) return;
      if (!isValid) {
        print('❌ AuthGuard: Session invalid, redirecting to login');
        await authService.forceReAuthentication();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ AuthGuard: Error checking session validity: $e');
      if (!mounted) return;
      await authService.forceReAuthentication();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
} 