import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF7B3FF2); // Logo purple
const Color kAccentColor = Color(0xFFB39DDB); // Lighter purple
const Color kBackgroundColor = Color(0xFFF6F5FB); // Soft background

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    primary: kPrimaryColor,
    secondary: kAccentColor,
    background: kBackgroundColor,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: kBackgroundColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kPrimaryColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kPrimaryColor, width: 2),
    ),
    labelStyle: const TextStyle(color: kPrimaryColor),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      color: kPrimaryColor,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
);
