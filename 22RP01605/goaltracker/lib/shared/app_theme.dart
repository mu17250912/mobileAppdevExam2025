import 'package:flutter/material.dart';

class AppTheme {
  // Consistent gradient background colors
  static const List<Color> backgroundGradient = [
    Color(0xFF7C3AED), // Colors.deepPurple.shade400
    Color(0xFF5B21B6), // Colors.deepPurple.shade800
    Color(0xFF4C1D95), // Colors.purple.shade900
  ];

  // Background gradient decoration
  static BoxDecoration backgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: backgroundGradient,
    ),
  );

  // Scaffold with consistent background
  static Widget scaffoldWithBackground({
    required BuildContext context,
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
    Widget? drawer,
    Widget? floatingActionButton,
    bool? resizeToAvoidBottomInset,
  }) {
    return Scaffold(
      appBar: appBar,
      body: Container(decoration: backgroundDecoration, child: body),
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  // Card with consistent styling
  static Card createCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? elevation,
    Color? color,
  }) {
    return Card(
      margin: margin ?? const EdgeInsets.all(16),
      elevation: elevation ?? 8,
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  // Consistent text styles
  static TextStyle titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ) ??
        const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );
  }

  static TextStyle subtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white.withOpacity(0.9),
        ) ??
        const TextStyle(fontSize: 16, color: Colors.white);
  }

  static TextStyle bodyStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withOpacity(0.8),
        ) ??
        const TextStyle(fontSize: 14, color: Colors.white);
  }

  // Input decoration theme for high-contrast text fields
  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    labelStyle: const TextStyle(color: Colors.white),
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
    prefixIconColor: Colors.white,
    suffixIconColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.white, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(12),
    ),
    fillColor: Colors.white.withOpacity(0.08),
    filled: true,
  );
}
