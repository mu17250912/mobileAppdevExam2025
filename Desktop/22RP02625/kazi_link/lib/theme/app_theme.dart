import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: Color(0xFF1976D2),
    secondary: Color(0xFFFFC107),
    background: Color(0xFFF5F7FA),
    error: Color(0xFFD32F2F),
  ),
  textTheme: GoogleFonts.poppinsTextTheme(),
  scaffoldBackgroundColor: Color(0xFFF5F7FA),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF1976D2),
    secondary: Color(0xFFFFC107),
    background: Color(0xFF121212),
    error: Color(0xFFD32F2F),
  ),
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  scaffoldBackgroundColor: Color(0xFF121212),
);