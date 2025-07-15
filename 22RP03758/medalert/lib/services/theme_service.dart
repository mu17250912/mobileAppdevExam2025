import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'theme_mode';
  static const String _highContrastKey = 'high_contrast';
  static const String _largeTextKey = 'large_text';
  static const String _voiceEnabledKey = 'voice_enabled';

  bool _isDarkMode = false;
  bool _isHighContrast = false;
  bool _isLargeText = false;
  bool _isVoiceEnabled = true;

  bool get isDarkMode => _isDarkMode;
  bool get isHighContrast => _isHighContrast;
  bool get isLargeText => _isLargeText;
  bool get isVoiceEnabled => _isVoiceEnabled;

  // Load theme preferences
  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      _isHighContrast = prefs.getBool(_highContrastKey) ?? false;
      _isLargeText = prefs.getBool(_largeTextKey) ?? false;
      _isVoiceEnabled = prefs.getBool(_voiceEnabledKey) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  // Save theme preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      await prefs.setBool(_highContrastKey, _isHighContrast);
      await prefs.setBool(_largeTextKey, _isLargeText);
      await prefs.setBool(_voiceEnabledKey, _isVoiceEnabled);
    } catch (e) {
      debugPrint('Error saving theme preferences: $e');
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _savePreferences();
    notifyListeners();
  }

  // Set dark mode
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _savePreferences();
    notifyListeners();
  }

  // Toggle high contrast
  Future<void> toggleHighContrast() async {
    _isHighContrast = !_isHighContrast;
    await _savePreferences();
    notifyListeners();
  }

  // Set high contrast
  Future<void> setHighContrast(bool isHighContrast) async {
    _isHighContrast = isHighContrast;
    await _savePreferences();
    notifyListeners();
  }

  // Toggle large text
  Future<void> toggleLargeText() async {
    _isLargeText = !_isLargeText;
    await _savePreferences();
    notifyListeners();
  }

  // Set large text
  Future<void> setLargeText(bool isLargeText) async {
    _isLargeText = isLargeText;
    await _savePreferences();
    notifyListeners();
  }

  // Toggle voice enabled
  Future<void> toggleVoiceEnabled() async {
    _isVoiceEnabled = !_isVoiceEnabled;
    await _savePreferences();
    notifyListeners();
  }

  // Set voice enabled
  Future<void> setVoiceEnabled(bool isVoiceEnabled) async {
    _isVoiceEnabled = isVoiceEnabled;
    await _savePreferences();
    notifyListeners();
  }

  // Get theme data based on current settings
  ThemeData getThemeData() {
    ThemeData baseTheme = _isDarkMode ? _getDarkTheme() : _getLightTheme();
    
    if (_isHighContrast) {
      baseTheme = _applyHighContrast(baseTheme);
    }
    
    if (_isLargeText) {
      baseTheme = _applyLargeText(baseTheme);
    }
    
    return baseTheme;
  }

  // Get light theme
  ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  // Get dark theme
  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[900],
      ),
    );
  }

  // Apply high contrast to theme
  ThemeData _applyHighContrast(ThemeData theme) {
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.yellow,
        onSecondary: Colors.black,
        error: Colors.red,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }

  // Apply large text to theme
  ThemeData _applyLargeText(ThemeData theme) {
    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        headlineLarge: theme.textTheme.headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: theme.textTheme.headlineMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: theme.textTheme.headlineSmall?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: theme.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: theme.textTheme.titleMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: theme.textTheme.titleSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 18,
        ),
        bodyMedium: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
        ),
        bodySmall: theme.textTheme.bodySmall?.copyWith(
          fontSize: 14,
        ),
        labelLarge: theme.textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: theme.textTheme.labelMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Get accessibility text scale factor
  double get textScaleFactor {
    if (_isLargeText) {
      return 1.3;
    }
    return 1.0;
  }

  // Get accessibility color scheme
  ColorScheme get accessibilityColorScheme {
    final baseScheme = _isDarkMode ? _getDarkTheme().colorScheme : _getLightTheme().colorScheme;
    
    if (_isHighContrast) {
      return baseScheme.copyWith(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.yellow,
        onSecondary: Colors.black,
        error: Colors.red,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      );
    }
    
    return baseScheme;
  }

  // Get accessibility icon theme
  IconThemeData get accessibilityIconTheme {
    return IconThemeData(
      size: _isLargeText ? 28 : 24,
      color: _isHighContrast ? Colors.black : null,
    );
  }

  // Get accessibility button style
  ButtonStyle get accessibilityButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: _isHighContrast ? Colors.black : null,
      foregroundColor: _isHighContrast ? Colors.white : null,
      padding: EdgeInsets.symmetric(
        horizontal: _isLargeText ? 32 : 24,
        vertical: _isLargeText ? 16 : 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: _isHighContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
      ),
    );
  }

  // Get accessibility card style
  CardTheme get accessibilityCardTheme {
    return CardTheme(
      elevation: _isHighContrast ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isHighContrast ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
      ),
    );
  }

  // Reset all accessibility settings
  Future<void> resetAccessibilitySettings() async {
    _isDarkMode = false;
    _isHighContrast = false;
    _isLargeText = false;
    _isVoiceEnabled = true;
    await _savePreferences();
    notifyListeners();
  }

  // Get accessibility summary
  String getAccessibilitySummary() {
    final settings = <String>[];
    
    if (_isDarkMode) settings.add('Dark Mode');
    if (_isHighContrast) settings.add('High Contrast');
    if (_isLargeText) settings.add('Large Text');
    if (_isVoiceEnabled) settings.add('Voice Enabled');
    
    if (settings.isEmpty) {
      return 'Default settings';
    }
    
    return settings.join(', ');
  }
} 