import 'package:flutter/material.dart';
import '../main.dart'; // For AppColors

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/logo.png',
      'title': 'Welcome to CeremoCar',
      'desc': 'Centralized platform for stylish, reliable event car bookings.'
    },
    {
      'image': 'assets/images/BMW 3 Series.jpeg',
      'title': 'Compare & Customize',
      'desc': 'Browse, compare, and personalize your car for any event.'
    },
    {
      'image': 'assets/images/Mercedes GLE.jpeg',
      'title': 'Book & Enjoy',
      'desc': 'Book online, pay securely, and enjoy your special day stress-free.'
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  void _skip() {
    _finishOnboarding();
  }

  void _finishOnboarding() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: (ModalRoute.of(context)?.canPop ?? false)
          ? AppBar(
              backgroundColor: theme.colorScheme.primary,
              elevation: 0,
              leading: BackButton(),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Image.asset(page['image']!, height: 160),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page['title']!,
                          style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.primary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['desc']!,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? theme.colorScheme.secondary : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: const Text('SKIP'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _nextPage,
                    child: Text(_currentPage == _pages.length - 1 ? 'DONE' : 'NEXT', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 