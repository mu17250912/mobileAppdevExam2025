import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'theme': mode == ThemeMode.dark ? 'dark' : 'light',
      }, SetOptions(merge: true));
    }
    // Save to SharedPreferences for instant local effect
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> _loadTheme() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final theme = doc.data()?['theme'] ?? 'light';
      _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } else {
      // Load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('theme') ?? 'light';
      _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> reloadTheme() async {
    await _loadTheme();
  }
} 