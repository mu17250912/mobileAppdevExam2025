import 'package:flutter/material.dart';

class OnboardingSlide extends StatelessWidget {
  final String title;
  final String description;
  final String emoji;

  const OnboardingSlide({
    Key? key,
    required this.title,
    required this.description,
    required this.emoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: TextStyle(fontSize: 64)),
        SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          description,
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
