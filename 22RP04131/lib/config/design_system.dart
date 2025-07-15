// Design system for QuickDocs
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color secondary = Color(0xFFFFB300);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green600 = Color(0xFF2E7D32);
  static const Color green800 = Color(0xFF1B5E20);
  static const Color orange100 = Color(0xFFFFE0B2);
  static const Color orange500 = Color(0xFFFF9800);
  static const Color blue100 = Color(0xFFBBDEFB);
  static const Color blue600 = Color(0xFF1976D2);
  static const Color purple500 = Color(0xFF9C27B0);
  static const Color red50 = Color(0xFFFFEBEE);
  static const Color red300 = Color(0xFFE57373);
  static const Color red600 = Color(0xFFE53935);
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);
  static const Color gray200 = Color(0xFFEEEEEE); // Added for document preview
  static const Color orange600 = Color(0xFFFB8C00); // Added for document preview
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppBorderRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xl = 24;
  static const double circle = 999;
}

class AppElevation {
  static const double low = 2;
  static const double medium = 4;
  static const double high = 8;
}

class AppTypography {
  static const String fontFamily = 'Poppins';
  static const TextStyle headlineLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 40/32, fontFamily: fontFamily);
  static const TextStyle headlineMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 36/28, fontFamily: fontFamily);
  static const TextStyle headlineSmall = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 32/24, fontFamily: fontFamily);
  static const TextStyle titleLarge = TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 28/22, fontFamily: fontFamily);
  static const TextStyle titleMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 24/16, fontFamily: fontFamily);
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 24/16, fontFamily: fontFamily);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 20/14, fontFamily: fontFamily);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 16/12, fontFamily: fontFamily);
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 20/14, fontFamily: fontFamily);
  static const TextStyle labelSmall = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 16/11, fontFamily: fontFamily);
} 