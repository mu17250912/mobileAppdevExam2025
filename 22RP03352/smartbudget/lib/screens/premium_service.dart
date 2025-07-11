import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const String _premiumKey = 'is_premium';
  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }
  static Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
  }
} 