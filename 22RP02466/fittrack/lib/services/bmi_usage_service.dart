import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'premium_service.dart';

class BMIUsageService {
  static const String _dailyCalculationsKey = 'daily_bmi_calculations';
  static const String _lastCalculationDateKey = 'last_calculation_date';
  static const int _maxFreeCalculationsPerDay = 3;

  /// Track a BMI calculation and return whether user needs to upgrade
  static Future<bool> trackCalculation() async {
    // Check if user is premium for calculations
    final isCalculationsPremium = await PremiumService.isCalculationsPremium();
    if (isCalculationsPremium) {
      return false; // Premium users have unlimited calculations
    }
    
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Get last calculation date
    final lastCalculationDate = prefs.getString(_lastCalculationDateKey);
    
    // If it's a new day, reset the counter
    if (lastCalculationDate != todayString) {
      await prefs.setString(_lastCalculationDateKey, todayString);
      await prefs.setInt(_dailyCalculationsKey, 1);
      return false; // First calculation of the day, no upgrade needed
    }
    
    // Get current daily count
    final currentCount = prefs.getInt(_dailyCalculationsKey) ?? 0;
    final newCount = currentCount + 1;
    
    // Save the new count
    await prefs.setInt(_dailyCalculationsKey, newCount);
    
    // Check if user needs to upgrade (more than 3 calculations per day)
    return newCount > _maxFreeCalculationsPerDay;
  }

  /// Get current daily calculation count
  static Future<int> getDailyCalculationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final lastCalculationDate = prefs.getString(_lastCalculationDateKey);
    
    // If it's a new day, return 0
    if (lastCalculationDate != todayString) {
      return 0;
    }
    
    return prefs.getInt(_dailyCalculationsKey) ?? 0;
  }

  /// Get remaining free calculations for today
  static Future<int> getRemainingFreeCalculations() async {
    // Check if user is premium for calculations
    final isCalculationsPremium = await PremiumService.isCalculationsPremium();
    if (isCalculationsPremium) {
      return -1; // -1 indicates unlimited for premium users
    }
    
    final currentCount = await getDailyCalculationCount();
    final remaining = _maxFreeCalculationsPerDay - currentCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if user needs to upgrade for calculations
  static Future<bool> needsUpgradeForCalculations() async {
    // Check if user is premium for calculations
    final isCalculationsPremium = await PremiumService.isCalculationsPremium();
    if (isCalculationsPremium) {
      return false; // Premium users don't need to upgrade
    }
    
    final currentCount = await getDailyCalculationCount();
    return currentCount >= _maxFreeCalculationsPerDay;
  }

  /// Reset daily calculation count (for testing or admin purposes)
  static Future<void> resetDailyCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailyCalculationsKey);
    await prefs.remove(_lastCalculationDateKey);
  }

  /// Get calculation statistics
  static Future<Map<String, dynamic>> getCalculationStats() async {
    final currentCount = await getDailyCalculationCount();
    final remaining = await getRemainingFreeCalculations();
    final needsUpgrade = await needsUpgradeForCalculations();
    
    return {
      'currentCount': currentCount,
      'remainingFree': remaining,
      'maxFree': _maxFreeCalculationsPerDay,
      'needsUpgrade': needsUpgrade,
    };
  }
} 