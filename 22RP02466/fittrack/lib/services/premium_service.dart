import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const String _premiumStatusKey = 'isPremiumUser';
  static const String _calculationsPremiumKey = 'calculationsPremium';
  static const String _advicePremiumKey = 'advicePremium';

  /// Check if user is premium for calculations
  static Future<bool> isCalculationsPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_calculationsPremiumKey) ?? false;
  }

  /// Check if user is premium for advice
  static Future<bool> isAdvicePremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_advicePremiumKey) ?? false;
  }

  /// Check if user is premium (legacy method for backward compatibility)
  static Future<bool> isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumStatusKey) ?? false;
  }

  /// Set premium status for calculations
  static Future<void> setCalculationsPremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_calculationsPremiumKey, isPremium);
  }

  /// Set premium status for advice
  static Future<void> setAdvicePremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_advicePremiumKey, isPremium);
  }

  /// Set general premium status (legacy method)
  static Future<void> setPremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumStatusKey, isPremium);
  }

  /// Upgrade user to calculations premium
  static Future<void> upgradeToCalculationsPremium() async {
    await setCalculationsPremium(true);
  }

  /// Upgrade user to advice premium
  static Future<void> upgradeToAdvicePremium() async {
    await setAdvicePremium(true);
  }

  /// Upgrade user to premium (legacy method - unlocks both)
  static Future<void> upgradeToPremium() async {
    await setCalculationsPremium(true);
    await setAdvicePremium(true);
    await setPremiumStatus(true);
  }

  /// Downgrade user from premium
  static Future<void> downgradeFromPremium() async {
    await setCalculationsPremium(false);
    await setAdvicePremium(false);
    await setPremiumStatus(false);
  }

  /// Reset all premium status (for testing)
  static Future<void> resetPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_premiumStatusKey);
    await prefs.remove(_calculationsPremiumKey);
    await prefs.remove(_advicePremiumKey);
  }
} 