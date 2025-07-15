import 'package:flutter/material.dart';
import 'auth/role_selection_screen.dart';
import 'package:simple_animations/simple_animations.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  void _goToRoleSelection() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated particles background
          const AnimatedParticlesBackground(),
          // Main content centered
          Center(
            child: SingleChildScrollView(
          child: Column(
                mainAxisSize: MainAxisSize.min,
            children: [
                  // Animated logo
                  AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 36),
                  // Shimmering app name
                  ShimmerText(
                    text: 'RentMate',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
              ),
                  const SizedBox(height: 12),
                  FadeIn(
                    delay: 1.2,
                    child: Text(
                      'Find Your Perfect Home',
                style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.92),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Get Started Button
                  FadeIn(
                    delay: 1.5,
                    child: ElevatedButton(
                      onPressed: _goToRoleSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF667eea),
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      child: const Text('Get Started'),
                ),
              ),
            ],
        ),
      ),
          ),
        ],
      ),
    );
  }
}

// Animated particles background using simple_animations
class AnimatedParticlesBackground extends StatelessWidget {
  const AnimatedParticlesBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return MirrorAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 6),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return CustomPaint(
          painter: _ParticlesPainter(value),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;
  final int particleCount = 30;
  final Random random = Random(42);
  _ParticlesPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particleCount; i++) {
      final angle = 2 * pi * i / particleCount + progress * 2 * pi;
      final radius = size.width * 0.35 + 20 * sin(progress * 2 * pi + i);
      final x = size.width / 2 + radius * cos(angle);
      final y = size.height / 2 + radius * sin(angle);
      final color = Colors.white.withOpacity(0.08 + 0.08 * sin(progress * 2 * pi + i));
      canvas.drawCircle(Offset(x, y), 16 + 8 * sin(progress * 2 * pi + i), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

// Shimmer effect for app name
class ShimmerText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const ShimmerText({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: -2.0, end: 2.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.4),
                Colors.white,
                Colors.white.withOpacity(0.4),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1 + value, -1),
              end: Alignment(1 + value, 1),
            ).createShader(bounds);
          },
          child: Text(text, style: style),
        );
      },
    );
  }
}

// Fade in widget with delay
class FadeIn extends StatelessWidget {
  final double delay;
  final Widget child;
  const FadeIn({super.key, required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      delay: Duration(milliseconds: (delay * 1000).toInt()),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
} 