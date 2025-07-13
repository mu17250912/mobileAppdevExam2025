import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E7D32); // Green (from logo)
  static const Color primaryLight = Color(0xFF4CAF50); // Lighter Green
  static const Color primaryDark = Color(0xFF1B5E20); // Darker Green

  // Background Colors
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color cardBackground = Color(0xFFFFFFFF); // White

  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Black
  static const Color textSecondary = Color(0xFF2E7D32); // Green for emphasis
  static const Color textLight = Color(0xFFBDBDBD); // Light Gray

  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange (rarely used)
  static const Color error = Color(0xFFF44336); // Red (rarely used)
  static const Color info = Color(0xFF2196F3); // Blue (rarely used)

  // Border Colors
  static const Color border = Color(0xFFE0E0E0); // Light Gray
  static const Color divider = Color(0xFFEEEEEE); // Very Light Gray

  // Shadow Colors
  static const Color shadow = Color(0x1A000000); // Black with 10% opacity

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Material Color Swatch
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF2E7D32, // Primary color value
    <int, Color>{
      50: Color(0xFFE8F5E8),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50), // Primary
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32), // Primary Dark
      900: Color(0xFF1B5E20),
    },
  );
} 