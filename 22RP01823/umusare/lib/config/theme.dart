import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // App Colors
  static const Color primaryGreen = Color(0xFF145A32);
  static const Color secondaryGreen = Color(0xFF1ABC9C);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color warningYellow = Color(0xFFF39C12);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF6F8F9);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF2C3E50);
  static const Color lightTextSecondary = Color(0xFF7F8C8D);
  static const Color lightDivider = Color(0xFFECF0F1);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkDivider = Color(0xFF2C2C2C);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: primaryGreen,
        scaffoldBackgroundColor: lightBackground,
        cardColor: lightSurface,
        dividerColor: lightDivider,
        
        // App Bar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // Color Scheme
        colorScheme: const ColorScheme.light(
          primary: primaryGreen,
          secondary: secondaryGreen,
          surface: lightSurface,
          background: lightBackground,
          error: errorRed,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: lightTextPrimary,
          onBackground: lightTextPrimary,
          onError: Colors.white,
        ),

        // Text Theme
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          displayLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: lightTextPrimary,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: lightTextPrimary,
          ),
          displaySmall: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: lightTextPrimary,
          ),
          headlineLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: lightTextPrimary,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: lightTextPrimary,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: lightTextPrimary,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: lightTextPrimary,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: lightTextPrimary,
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: lightTextSecondary,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: lightTextPrimary,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            color: lightTextPrimary,
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            color: lightTextSecondary,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          color: lightSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black12,
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),

        // Switch Theme
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return primaryGreen;
            }
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return primaryGreen.withOpacity(0.3);
            }
            return Colors.grey.withOpacity(0.3);
          }),
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: lightSurface,
          selectedItemColor: primaryGreen,
          unselectedItemColor: lightTextSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: secondaryGreen,
        scaffoldBackgroundColor: darkBackground,
        cardColor: darkSurface,
        dividerColor: darkDivider,
        
        // App Bar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          foregroundColor: darkTextPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: darkTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: darkTextPrimary),
        ),

        // Color Scheme
        colorScheme: const ColorScheme.dark(
          primary: secondaryGreen,
          secondary: primaryGreen,
          surface: darkSurface,
          background: darkBackground,
          error: errorRed,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: darkTextPrimary,
          onBackground: darkTextPrimary,
          onError: Colors.white,
        ),

        // Text Theme
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          displayLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: darkTextPrimary,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkTextPrimary,
          ),
          displaySmall: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkTextPrimary,
          ),
          headlineLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkTextPrimary,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkTextPrimary,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkTextPrimary,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: darkTextPrimary,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkTextSecondary,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: darkTextPrimary,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            color: darkTextPrimary,
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            color: darkTextSecondary,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          color: darkSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black26,
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryGreen,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: secondaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),

        // Switch Theme
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return secondaryGreen;
            }
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return secondaryGreen.withOpacity(0.3);
            }
            return Colors.grey.withOpacity(0.3);
          }),
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkSurface,
          selectedItemColor: secondaryGreen,
          unselectedItemColor: darkTextSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get theme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
} 