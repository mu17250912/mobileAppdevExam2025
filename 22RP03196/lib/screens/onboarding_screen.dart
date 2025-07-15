import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _pageIndex = 0;
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Track your workouts',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Stay motivated daily',
      'icon': Icons.directions_run,
    },
  ];

  void _nextPage() {
    setState(() {
      if (_pageIndex < _pages.length - 1) {
        _pageIndex++;
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(32),
              child: Icon(
                _pages[_pageIndex]['icon'],
                color: Colors.white,
                size: 100,
              ),
            ),
            SizedBox(height: 32),
            Text(
              _pages[_pageIndex]['title'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: i == _pageIndex ? Colors.white : Colors.white54,
                  shape: BoxShape.circle,
                ),
              )),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF22A6F2),
                padding: EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                textStyle: TextStyle(fontSize: 18),
                elevation: 2,
              ),
              child: Text(_pageIndex == _pages.length - 1 ? 'Start' : 'Next', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
} 