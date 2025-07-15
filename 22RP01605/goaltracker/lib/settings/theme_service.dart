import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _templateKey = 'selected_template';

  static final Map<String, Map<String, dynamic>> _templates = {
    'Elegant Purple': {
      'primaryColor': Colors.deepPurple,
      'backgroundColor': Colors.deepPurple.shade50,
      'appBarColor': Colors.deepPurple,
      'cardColor': Colors.white,
      'textColor': Colors.black,
      'icon': Icons.palette,
      'description': 'Elegant purple theme with professional design',
    },
    'Modern Blue': {
      'primaryColor': Colors.blue,
      'backgroundColor': Colors.blue.shade50,
      'appBarColor': Colors.blue,
      'cardColor': Colors.white,
      'textColor': Colors.black,
      'icon': Icons.dark_mode,
      'description': 'Contemporary blue theme with modern aesthetics',
    },
    'Fresh Green': {
      'primaryColor': Colors.green,
      'backgroundColor': Colors.green.shade50,
      'appBarColor': Colors.green,
      'cardColor': Colors.white,
      'textColor': Colors.black,
      'icon': Icons.light_mode,
      'description': 'Clean green theme with minimalist approach',
    },
  };

  static Future<String> getCurrentTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_templateKey) ?? 'Elegant Purple';
  }

  static Future<void> setTemplate(String templateName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_templateKey, templateName);
  }

  static Map<String, dynamic> getTemplateData(String templateName) {
    return _templates[templateName] ?? _templates['Elegant Purple']!;
  }

  static List<String> getAvailableTemplates() {
    return _templates.keys.toList();
  }

  static List<Map<String, dynamic>> getAllTemplates() {
    return _templates.entries
        .map((entry) => {'name': entry.key, ...entry.value})
        .toList();
  }

  // Helper methods to get theme colors
  static Future<Color> getPrimaryColor() async {
    final template = await getCurrentTemplate();
    return getTemplateData(template)['primaryColor'];
  }

  static Future<Color> getBackgroundColor() async {
    final template = await getCurrentTemplate();
    return getTemplateData(template)['backgroundColor'];
  }

  static Future<Color> getAppBarColor() async {
    final template = await getCurrentTemplate();
    return getTemplateData(template)['appBarColor'];
  }

  static Future<Color> getCardColor() async {
    final template = await getCurrentTemplate();
    return getTemplateData(template)['cardColor'];
  }

  static Future<Color> getTextColor() async {
    final template = await getCurrentTemplate();
    return getTemplateData(template)['textColor'];
  }
}
