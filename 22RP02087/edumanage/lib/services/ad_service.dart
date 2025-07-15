import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static const String _adConsentKey = 'ad_consent';
  bool _isInitialized = false;

  // Check if user has given ad consent
  Future<bool> hasAdConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adConsentKey) ?? false;
  }

  // Set ad consent
  Future<void> setAdConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adConsentKey, consent);
  }
} 