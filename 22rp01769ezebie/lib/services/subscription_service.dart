import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive/hive.dart';

class SubscriptionService {
  static const String _subscriptionBoxName = 'subscriptions';
  static const String _premiumStatusKey = 'isPremium';
  static const String _activePlanKey = 'activePlan';
  static const String _subscriptionDateKey = 'subscriptionDate';
  static const String _expiryDateKey = 'expiryDate';

  static Future<void> initialize() async {
    await Hive.openBox('subscriptions');
  }

  // Check if user has active premium subscription
  static Future<bool> isPremium(String username) async {
    var box = Hive.box('subscriptions');
    if (box.containsKey(username)) {
      final sub = box.get(username) as Map?;
      if (sub != null && sub['isPremium'] == true) {
        final expiry = sub['expiryDate'] != null ? DateTime.parse(sub['expiryDate']) : null;
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          await removePremium(username);
          return false;
        }
        return true;
      }
    }
    // Firestore fallback
    // Remove any Firestore usage
    return false; // Placeholder, as Firestore is removed
  }

  // Get active plan details
  static Future<String?> getActivePlan(String username) async {
    var box = Hive.box('subscriptions');
    if (box.containsKey(username)) {
      final sub = box.get(username) as Map?;
      return sub?['activePlan'];
    }
    // Remove any Firestore usage
    return null; // Placeholder, as Firestore is removed
  }

  // Get subscription expiry date
  static Future<DateTime?> getExpiryDate(String username) async {
    var box = Hive.box('subscriptions');
    if (box.containsKey(username)) {
      final sub = box.get(username) as Map?;
      final expiryDate = sub?['expiryDate'];
      return expiryDate != null ? DateTime.parse(expiryDate) : null;
    }
    // Remove any Firestore usage
    return null; // Placeholder, as Firestore is removed
  }

  // Activate premium subscription
  static Future<void> activatePremium(String username, String planType) async {
    final now = DateTime.now();
    DateTime expiryDate;
    if (planType == 'monthly_premium') {
      expiryDate = now.add(Duration(days: 30));
    } else if (planType == 'annual_premium') {
      expiryDate = now.add(Duration(days: 365));
    } else {
      expiryDate = now.add(Duration(days: 30));
    }
    final data = {
      'isPremium': true,
      'activePlan': planType,
      'subscriptionDate': now.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
    // Remove any Firestore usage
    var box = Hive.box('subscriptions');
    box.put(username, data);
  }

  // Remove premium subscription
  static Future<void> removePremium(String username) async {
    // Remove any Firestore usage
    var box = Hive.box('subscriptions');
    box.delete(username);
  }

  // Get subscription status info
  static Future<Map<String, dynamic>> getSubscriptionInfo(String username) async {
    var box = Hive.box('subscriptions');
    if (box.containsKey(username)) {
      return Map<String, dynamic>.from(box.get(username));
    }
    // Remove any Firestore usage
    return {}; // Placeholder, as Firestore is removed
  }

  // Process payment (demo implementation)
  static Future<Map<String, dynamic>> processPayment({
    required String username,
    required String planType,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
  }) async {
    await Future.delayed(Duration(seconds: 2));
    bool paymentSuccess = false;
    String errorMessage = '';
    switch (paymentMethod.toLowerCase()) {
      case 'credit card':
        paymentSuccess = _validateCreditCard(paymentDetails);
        if (!paymentSuccess) errorMessage = 'Invalid credit card details';
        break;
      case 'paypal':
        paymentSuccess = _validatePayPal(paymentDetails);
        if (!paymentSuccess) errorMessage = 'PayPal payment failed';
        break;
      case 'apple pay':
        paymentSuccess = _validateApplePay(paymentDetails);
        if (!paymentSuccess) errorMessage = 'Apple Pay payment failed';
        break;
      case 'google pay':
        paymentSuccess = _validateGooglePay(paymentDetails);
        if (!paymentSuccess) errorMessage = 'Google Pay payment failed';
        break;
      default:
        paymentSuccess = false;
        errorMessage = 'Unsupported payment method';
    }
    if (paymentSuccess) {
      await activatePremium(username, planType);
      return {
        'success': true,
        'message': 'Payment successful! Premium activated.',
        'planType': planType,
      };
    } else {
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Payment validation methods (demo implementations)
  static bool _validateCreditCard(Map<String, dynamic> details) {
    final cardNumber = details['cardNumber']?.toString() ?? '';
    final expiryDate = details['expiryDate']?.toString() ?? '';
    final cvv = details['cvv']?.toString() ?? '';
    
    // Basic validation (in real app, use proper validation)
    return cardNumber.length >= 13 && 
           cardNumber.length <= 19 && 
           expiryDate.isNotEmpty && 
           cvv.length >= 3;
  }

  static bool _validatePayPal(Map<String, dynamic> details) {
    final email = details['email']?.toString() ?? '';
    return email.contains('@') && email.contains('.');
  }

  static bool _validateApplePay(Map<String, dynamic> details) {
    // Simulate Apple Pay validation
    return true; // Demo always succeeds
  }

  static bool _validateGooglePay(Map<String, dynamic> details) {
    // Simulate Google Pay validation
    return true; // Demo always succeeds
  }
} 