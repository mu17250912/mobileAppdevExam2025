import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;

import 'services/analytics_service.dart';
import 'services/performance_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _buttonController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _trackScreenView();
  }

  void _initializeAnimations() {
    // Background animation
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    );

    // Content animation
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.elasticOut,
    );

    // Button animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _buttonAnimation = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      _buttonController.forward();
    });
  }

  Future<void> _trackScreenView() async {
    try {
      await AnalyticsService.trackScreenView('welcome_screen');
      await PerformanceService.trackScreenLoad('welcome_screen');
    } catch (e) {
      // Ignore tracking errors
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4CAF50),
                      Color.lerp(const Color(0xFF2E7D32), const Color(0xFF1B5E20), _backgroundAnimation.value)!,
                    ],
                  ),
                ),
              );
            },
          ),
          // Animated floating background elements
          ...List.generate(15, (index) => _buildBackgroundElement(index)),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glassmorphic card
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight: size.height * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        // Glassmorphism effect
                        backgroundBlendMode: BlendMode.overlay,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo and title
                          ScaleTransition(
                            scale: _contentAnimation,
                            child: FadeTransition(
                              opacity: _contentAnimation,
                              child: Column(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.10),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.agriculture,
                                      size: 54,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Welcome to',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'UMUHINZI Smart',
                                    style: TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Agricultural Marketplace',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Features list
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(_contentAnimation),
                            child: FadeTransition(
                              opacity: _contentAnimation,
                              child: Column(
                                children: [
                                  _buildFeatureItem(
                                    Icons.store,
                                    'Connect with Dealers',
                                    'Find trusted agricultural suppliers',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildFeatureItem(
                                    Icons.science,
                                    'Smart Recommendations',
                                    'AI-powered fertilizer suggestions',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildFeatureItem(
                                    Icons.payment,
                                    'Secure Payments',
                                    'Safe and reliable transactions',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Buttons
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(_buttonAnimation),
                            child: FadeTransition(
                              opacity: _buttonAnimation,
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () => _navigateToRegister(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF4CAF50),
                                        elevation: 8,
                                        shadowColor: Colors.black.withOpacity(0.18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text(
                                        'Get Started',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: OutlinedButton(
                                      onPressed: () => _navigateToLogin(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white, width: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text(
                                        'I already have an account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundElement(int index) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final random = math.Random(index);
        final x = random.nextDouble() * MediaQuery.of(context).size.width;
        final y = random.nextDouble() * MediaQuery.of(context).size.height;
        final size = random.nextDouble() * 6 + 3;
        final opacity = random.nextDouble() * 0.2 + 0.1;
        
        return Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: _backgroundController.value * 2 * math.pi * (index % 2 == 0 ? 1 : -1),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
                  ),
                ),
        );
      },
    );
  }

  void _navigateToRegister(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
