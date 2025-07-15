import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;

import 'services/auth_service.dart';
import 'services/analytics_service.dart';
import 'services/performance_service.dart';
import 'welcome_screen.dart';
import 'screens/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;
  String _loadingText = 'Initializing...';
  int _loadingStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoadingSequence();
  }

  void _initializeAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    );

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
  }

  void _startLoadingSequence() async {
    final loadingSteps = [
      'Initializing...',
      'Loading services...',
      'Connecting to database...',
      'Preparing marketplace...',
      'Ready!',
    ];

    for (int i = 0; i < loadingSteps.length; i++) {
      if (mounted) {
        setState(() {
          _loadingText = loadingSteps[i];
          _loadingStep = i;
        });
      }
      await Future.delayed(Duration(milliseconds: 800 + (i * 200)));
    }

    // Check authentication status
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Wait for auth service to initialize
      while (authService.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Track splash screen completion
      await AnalyticsService.trackScreenView('splash_screen');
      await PerformanceService.trackScreenLoad('splash_screen');

      // Start fade out animation
      _fadeController.forward();

      // Navigate after fade animation
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        // Check if user is properly authenticated
        if (authService.isAuthenticated && authService.currentUser != null) {
          print('✅ User authenticated, navigating to dashboard');
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const DashboardScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          print('ℹ️ User not authenticated, navigating to welcome screen');
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const WelcomeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error during auth check: $e');
      // Fallback navigation to welcome screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF2E7D32),
                    const Color(0xFF1B5E20),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Animated background particles
                  ...List.generate(20, (index) => _buildParticle(index)),
                  
                  // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with animation
                        ScaleTransition(
                          scale: _logoAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.agriculture,
                              size: 60,
                              color: Color(0xFF4CAF50),
                ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // App name with animation
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(_textAnimation),
                          child: FadeTransition(
                            opacity: _textAnimation,
                            child: const Text(
                  'UMUHINZI Smart',
                  style: TextStyle(
                                fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                                letterSpacing: 1.2,
                  ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Tagline
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(_textAnimation),
                          child: FadeTransition(
                            opacity: _textAnimation,
                            child: const Text(
                              'Agricultural Marketplace',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Loading indicator
                        Column(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.8),
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _loadingText,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Progress dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index <= _loadingStep
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                  ),
                                );
                              }),
                            ),
                          ],
                ),
              ],
            ),
          ),
        ],
      ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final random = math.Random(index);
        final x = random.nextDouble() * MediaQuery.of(context).size.width;
        final y = random.nextDouble() * MediaQuery.of(context).size.height;
        final size = random.nextDouble() * 4 + 2;
        final opacity = random.nextDouble() * 0.3 + 0.1;
        
        return Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: _logoController.value * 2 * math.pi * (index % 2 == 0 ? 1 : -1),
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
} 