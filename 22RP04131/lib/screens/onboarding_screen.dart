import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.description,
      iconBg: AppColors.green100,
      iconColor: AppColors.primary,
      title: 'Create invoices in seconds',
      description: 'Generate professional invoices quickly and easily with our intuitive interface',
    ),
    _OnboardingSlide(
      icon: Icons.attach_money,
      iconBg: AppColors.orange100,
      iconColor: AppColors.orange500,
      title: 'Generate quotes on the go',
      description: 'Create professional quotations anywhere, anytime with mobile convenience',
    ),
    _OnboardingSlide(
      icon: Icons.share,
      iconBg: AppColors.blue100,
      iconColor: AppColors.blue600,
      title: 'Export & share as PDF instantly',
      description: 'Share your documents via WhatsApp, email, or download as PDF',
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    final slide = _slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: slide.iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon, size: 64, color: slide.iconColor),
                        ),
                        const SizedBox(height: 32),
                        Text(slide.title, style: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(slide.description, style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == _currentPage ? AppColors.primary : AppColors.gray300,
                    shape: BoxShape.circle,
                  ),
                )),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: AppTypography.labelLarge,
                  ),
                  onPressed: _next,
                  child: Text(_currentPage == _slides.length - 1 ? 'Get Started' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  const _OnboardingSlide({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
  });
} 