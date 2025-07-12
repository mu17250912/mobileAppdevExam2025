import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFDEE9), Color(0xFFB5FFFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              left: -60,
              child: _buildCircle(220, Colors.white.withOpacity(0.18)),
            ),
            Positioned(
              top: 80,
              right: -60,
              child: _buildCircle(140, Colors.white.withOpacity(0.18)),
            ),
            Positioned(
              bottom: 40,
              left: -40,
              child: _buildCircle(180, Colors.white.withOpacity(0.18)),
            ),
            Positioned(
              bottom: -60,
              right: -60,
              child: _buildCircle(200, Colors.white.withOpacity(0.18)),
            ),
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag, size: 80, color: Color(0xFF3DDAD7)),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to TradeWear',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Shop and sell easily from your smartphone',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF263238),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Discover, buy, and sell the latest fashion trends easily from your smartphone. TradeWear makes it simple for everyone to get started and manage their wardrobe on the go.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF7B8D93),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Color dots (for style)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(Colors.redAccent),
                        _buildDot(Colors.tealAccent.shade400),
                        _buildDot(Colors.cyanAccent.shade400),
                        _buildDot(Colors.greenAccent.shade100),
                        _buildDot(Colors.amberAccent.shade100),
                        _buildDot(Colors.pinkAccent.shade100),
                      ],
                    ),
                    const SizedBox(height: 36),
                    // Get Started Button
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: const Color(0xFF3DDAD7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 8,
                        ),
                        onPressed: () {
                          // TODO: Navigate to next screen (e.g., login or role selection)
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const LoginScreen(isSeller: false)),
                          );
                        },
                        child: const Text(
                          'Get Started',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Features row (optional, for style)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _FeatureIcon(
                          icon: Icons.palette,
                          label: 'Design',
                        ),
                        SizedBox(width: 40),
                        _FeatureIcon(
                          icon: Icons.flash_on,
                          label: 'Fast',
                        ),
                        SizedBox(width: 40),
                        _FeatureIcon(
                          icon: Icons.star,
                          label: 'Amazing',
                        ),
                      ],
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

  static Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget _buildDot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 36, color: Color(0xFF263238)),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF7B8D93),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 