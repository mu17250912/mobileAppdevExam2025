import 'package:flutter/material.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Colors from the screenshot
    const backgroundColor = Color(0xFF0D3B24);
    const logoCircleColor = Color(0xFF2B3C70); // Deep blue for logo circle background
    const buttonColor = Color(0xFFE6E6E6); // Light gray button
    const arrowColor = Color(0xFF1DB954); // Green arrow
    const activeDotColor = Color(0xFFBDBDBD); // Light gray
    const inactiveDotColor = Color(0xFF757575); // Darker gray

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Logo with circular background
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: logoCircleColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 80,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Internlink',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(1, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            const Text(
              'Apply For  Internship',
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            // Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Connect with Opportunities',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Connect with Opportunities\nPersonalized, secure, and streamlined internship tracking',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Continue Button
            Center(
              child: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  icon: Icon(
                    Icons.chevron_right,
                    color: Color(0xFF00E05B), // Bright green
                    size: 40,
                  ),
                  splashRadius: 28,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 10,
                  decoration: BoxDecoration(
                    color: activeDotColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: inactiveDotColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
        ),
      ),
    );
  }
} 