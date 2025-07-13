import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'register_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Icon(Icons.account_circle, size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text('Welcome to SmartBudget',
                        style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text('Sign in or create an account to continue',
                        style: GoogleFonts.poppins(fontSize: 15, color: theme.textTheme.bodyMedium?.color),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: Text('Sign in with Google', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      final cred = await AuthService().signInWithGoogle();
                      if (cred == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Google sign-in failed', style: theme.textTheme.bodyMedium)),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.email),
                    label: Text('Sign up / Login with Email', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 