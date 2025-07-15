/// Professional Theme System for SafeRide
///
/// This file contains all theme-related configurations including colors,
/// typography, and component styles for a consistent user experience.
library;

import 'package:flutter/material.dart';
import '../utils/app_config.dart';

class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      cardTheme: _cardTheme,
      chipTheme: _chipTheme,
      dividerTheme: _dividerTheme,
      iconTheme: _iconTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      snackBarTheme: _snackBarTheme,
      dialogTheme: _dialogTheme,
      bottomSheetTheme: _bottomSheetTheme,
      tabBarTheme: _tabBarTheme,
      switchTheme: _switchTheme,
      checkboxTheme: _checkboxTheme,
      radioTheme: _radioTheme,
      sliderTheme: _sliderTheme,
      progressIndicatorTheme: _progressIndicatorTheme,
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      textTheme: _textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: _appBarTheme.copyWith(
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme.copyWith(
        fillColor: _darkColorScheme.surface,
        labelStyle: TextStyle(color: _darkColorScheme.onSurface),
        hintStyle:
            TextStyle(color: _darkColorScheme.onSurface.withOpacity(0.6)),
      ),
      cardTheme: _cardTheme.copyWith(
        color: _darkColorScheme.surface,
      ),
      chipTheme: _chipTheme,
      dividerTheme: _dividerTheme,
      iconTheme: _iconTheme.copyWith(
        color: Colors.white,
      ),
      bottomNavigationBarTheme: _bottomNavigationBarTheme.copyWith(
        backgroundColor: _darkColorScheme.surface,
        selectedItemColor: _darkColorScheme.primary,
        unselectedItemColor: _darkColorScheme.onSurface.withOpacity(0.6),
      ),
      floatingActionButtonTheme: _floatingActionButtonTheme,
      snackBarTheme: _snackBarTheme,
      dialogTheme: _dialogTheme.copyWith(
        backgroundColor: _darkColorScheme.surface,
      ),
      bottomSheetTheme: _bottomSheetTheme.copyWith(
        backgroundColor: _darkColorScheme.surface,
      ),
      tabBarTheme: _tabBarTheme,
      switchTheme: _switchTheme,
      checkboxTheme: _checkboxTheme,
      radioTheme: _radioTheme,
      sliderTheme: _sliderTheme,
      progressIndicatorTheme: _progressIndicatorTheme,
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }

  // Color Schemes
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppConfig.primaryColor,
    onPrimary: Colors.white,
    secondary: AppConfig.secondaryColor,
    onSecondary: Colors.white,
    tertiary: AppConfig.accentColor,
    onTertiary: Colors.white,
    error: AppConfig.errorColor,
    onError: Colors.white,
    surface: Color(0xFFFAFAFA),
    onSurface: Color(0xFF424242),
    surfaceContainerHighest: Colors.white,
    surfaceContainer: Color(0xFFF5F5F5),
    onSurfaceVariant: Color(0xFF757575),
    outline: Color(0xFFE0E0E0),
    outlineVariant: Color(0xFFEEEEEE),
    shadow: Color(0x1F000000),
    scrim: Color(0x52000000),
    inverseSurface: Color(0xFF303030),
    onInverseSurface: Colors.white,
    inversePrimary: AppConfig.primaryColor,
    surfaceTint: AppConfig.primaryColor,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppConfig.primaryColor,
    onPrimary: Colors.white,
    secondary: AppConfig.secondaryColor,
    onSecondary: Colors.white,
    tertiary: AppConfig.accentColor,
    onTertiary: Colors.white,
    error: AppConfig.errorColor,
    onError: Colors.white,
    surface: Color(0xFF121212),
    onSurface: Colors.white,
    surfaceContainerHighest: Color(0xFF1E1E1E),
    surfaceContainer: Color(0xFF2D2D2D),
    onSurfaceVariant: Color(0xFFBDBDBD),
    outline: Color(0xFF424242),
    outlineVariant: Color(0xFF303030),
    shadow: Color(0x1F000000),
    scrim: Color(0x52000000),
    inverseSurface: Color(0xFFFAFAFA),
    onInverseSurface: Color(0xFF424242),
    inversePrimary: AppConfig.primaryColor,
    surfaceTint: AppConfig.primaryColor,
  );

  // Text Theme
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: Color(0xFF424242),
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: Color(0xFF424242),
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: Color(0xFF424242),
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: Color(0xFF424242),
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: Color(0xFF424242),
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: Color(0xFF424242),
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: Color(0xFF424242),
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: Color(0xFF424242),
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color(0xFF424242),
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: Color(0xFF424242),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: Color(0xFF424242),
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: Color(0xFF757575),
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Color(0xFF424242),
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: Color(0xFF424242),
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: Color(0xFF757575),
    ),
  );

  // App Bar Theme
  static const AppBarTheme _appBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: Colors.white,
    foregroundColor: AppConfig.primaryColor,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppConfig.primaryColor,
    ),
    iconTheme: IconThemeData(
      color: AppConfig.primaryColor,
      size: 24,
    ),
    actionsIconTheme: IconThemeData(
      color: AppConfig.primaryColor,
      size: 24,
    ),
  );

  // Elevated Button Theme
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConfig.spacingL,
        vertical: AppConfig.spacingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.cardRadius),
      ),
      minimumSize: const Size(0, AppConfig.buttonHeight),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Outlined Button Theme
  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConfig.spacingL,
        vertical: AppConfig.spacingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.cardRadius),
      ),
      minimumSize: const Size(0, AppConfig.buttonHeight),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Text Button Theme
  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConfig.spacingM,
        vertical: AppConfig.spacingS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.cardRadius),
      ),
      minimumSize: const Size(0, AppConfig.buttonHeight),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Input Decoration Theme
  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF5F5F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConfig.cardRadius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConfig.cardRadius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConfig.cardRadius),
      borderSide: const BorderSide(
        color: AppConfig.primaryColor,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConfig.cardRadius),
      borderSide: const BorderSide(
        color: AppConfig.errorColor,
        width: 2,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConfig.cardRadius),
      borderSide: const BorderSide(
        color: AppConfig.errorColor,
        width: 2,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppConfig.spacingM,
      vertical: AppConfig.spacingM,
    ),
    labelStyle: const TextStyle(
      color: Color(0xFF757575),
      fontSize: 16,
    ),
    hintStyle: const TextStyle(
      color: Color(0xFFBDBDBD),
      fontSize: 16,
    ),
  );

  // Card Theme
  static const CardThemeData _cardTheme = CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppConfig.cardRadius)),
    ),
    margin: EdgeInsets.all(AppConfig.spacingS),
    color: Colors.white,
  );

  // Chip Theme
  static const ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: Color(0xFFF5F5F5),
    selectedColor: AppConfig.primaryColor,
    disabledColor: Color(0xFFE0E0E0),
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    secondaryLabelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: AppConfig.spacingM,
      vertical: AppConfig.spacingS,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  );

  // Divider Theme
  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: Color(0xFFE0E0E0),
    thickness: 1,
    space: 1,
  );

  // Icon Theme
  static const IconThemeData _iconTheme = IconThemeData(
    color: AppConfig.primaryColor,
    size: 24,
  );

  // Bottom Navigation Bar Theme
  static const BottomNavigationBarThemeData _bottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppConfig.primaryColor,
    unselectedItemColor: Color(0xFF757575),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );

  // Floating Action Button Theme
  static const FloatingActionButtonThemeData _floatingActionButtonTheme =
      FloatingActionButtonThemeData(
    backgroundColor: AppConfig.primaryColor,
    foregroundColor: Colors.white,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  // Snack Bar Theme
  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: Color(0xFF323232),
    contentTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppConfig.cardRadius)),
    ),
    behavior: SnackBarBehavior.floating,
  );

  // Dialog Theme
  static const DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppConfig.cardRadius)),
    ),
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFF424242),
    ),
    contentTextStyle: TextStyle(
      fontSize: 16,
      color: Color(0xFF424242),
    ),
  );

  // Bottom Sheet Theme
  static const BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConfig.cardRadius),
      ),
    ),
  );

  // Tab Bar Theme
  static const TabBarThemeData _tabBarTheme = TabBarThemeData(
    labelColor: AppConfig.primaryColor,
    unselectedLabelColor: Color(0xFF757575),
    indicatorSize: TabBarIndicatorSize.tab,
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );

  // Switch Theme
  static final SwitchThemeData _switchTheme = SwitchThemeData(
    thumbColor:
        MaterialStateProperty.resolveWith((states) => AppConfig.primaryColor),
    trackColor:
        MaterialStateProperty.resolveWith((states) => const Color(0xFFE0E0E0)),
  );

  // Checkbox Theme
  static final CheckboxThemeData _checkboxTheme = CheckboxThemeData(
    fillColor:
        MaterialStateProperty.resolveWith((states) => AppConfig.primaryColor),
    checkColor: MaterialStateProperty.resolveWith((states) => Colors.white),
  );

  // Radio Theme
  static final RadioThemeData _radioTheme = RadioThemeData(
    fillColor:
        MaterialStateProperty.resolveWith((states) => AppConfig.primaryColor),
  );

  // Slider Theme
  static const SliderThemeData _sliderTheme = SliderThemeData(
    activeTrackColor: AppConfig.primaryColor,
    inactiveTrackColor: Color(0xFFE0E0E0),
    thumbColor: AppConfig.primaryColor,
    overlayColor: Color(0x1F1976D2),
  );

  // Progress Indicator Theme
  static const ProgressIndicatorThemeData _progressIndicatorTheme =
      ProgressIndicatorThemeData(
    color: AppConfig.primaryColor,
    linearTrackColor: Color(0xFFE0E0E0),
    circularTrackColor: Color(0xFFE0E0E0),
  );

  // Page Transitions Theme
  static const PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    },
  );
}
