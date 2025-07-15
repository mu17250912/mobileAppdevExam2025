import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Welcome to COLORS',
                    style: TextStyle(
                      fontSize: 44,
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
                    'Create Beautiful Experiences',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF263238),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Discover a vibrant world of creativity and innovation. Our platform brings together stunning visuals, intuitive design, and powerful features to help you create amazing experiences.',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF7B8D93),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Color dots
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      elevation: 8,
                      backgroundColor: null,
                      foregroundColor: Colors.white,
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (states) => null,
                      ),
                    ),
                    onPressed: () {
                      // TODO: Navigate to next screen
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFA8B8B), Color(0xFF43E97B)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'GET STARTED',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Features row
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