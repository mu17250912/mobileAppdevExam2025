import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4F8A8B); // Teal
  static const Color accent = Color(0xFFFBD46D); // Yellow
  static const Color background = Color(0xFFF6F6F6); // Light Gray
  static const Color text = Color(0xFF222831); // Dark Gray
  static const Color error = Color(0xFFD32F2F); // Red
}

class AppTheme {
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.accent;
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.bold,
    fontSize: 22,
    color: AppColors.text,
  );
  static const TextStyle subheading = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: AppColors.text,
  );
  static const TextStyle body = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.normal,
    fontSize: 16,
    color: AppColors.text,
  );
  static const TextStyle button = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.white,
  );
  static const TextStyle error = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: AppColors.error,
  );
} 