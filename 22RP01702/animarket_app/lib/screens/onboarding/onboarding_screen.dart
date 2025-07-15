import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'onboarding_slide.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const OnboardingScreen({Key? key, this.onComplete}) : super(key: key);
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Find Animals Nearby',
      'description': 'Browse animals for sale in your area quickly and easily.',
      'emoji': '🔍',
    },
    {
      'title': 'Connect with Sellers',
      'description': 'Chat directly with farmers and negotiate deals.',
      'emoji': '💬',
    },
    {
      'title': 'Safe & Trusted',
      'description': 'Buy and sell with confidence on a secure platform.',
      'emoji': '🛡️',
    },
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    }
  }

  void _skip() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: OnboardingSlide(
                      title: slide['title']!,
                      description: slide['description']!,
                      emoji: slide['emoji']!,
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? kPrimaryGreen : kLightGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: Text('Skip', style: TextStyle(color: kGrayText)),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_currentPage == _slides.length - 1 ? 'Start' : 'Next', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
