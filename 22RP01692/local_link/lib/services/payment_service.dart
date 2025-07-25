import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final user = FirebaseAuth.instance.currentUser;

  /// Simulates MTN Mobile Money payment processing
  /// In a real implementation, this would integrate with MTN Mobile Money API
  Future<PaymentResult> processMTNMobileMoneyPayment({
    required String phoneNumber,
    required double amount,
    required String description,
    required String currency,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate payment validation
      if (!_isValidPhoneNumber(phoneNumber)) {
        return PaymentResult(
          success: false,
          message: 'Invalid phone number format. Please use format: 07XXXXXXXX',
          transactionId: null,
        );
      }

      if (amount < 100) {
        return PaymentResult(
          success: false,
          message: 'Minimum payment amount is 100 FRW',
          transactionId: null,
        );
      }

      // Simulate payment processing with 95% success rate
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      final isSuccess = random < 95; // 95% success rate

      if (!isSuccess) {
        return PaymentResult(
          success: false,
          message: 'Payment failed. Please try again or check your balance.',
          transactionId: null,
        );
      }

      // Generate simulated transaction ID
      final transactionId = 'MTN${DateTime.now().millisecondsSinceEpoch}';

      // Record payment in Firestore
      await _recordPayment(
        phoneNumber: phoneNumber,
        amount: amount,
        description: description,
        currency: currency,
        transactionId: transactionId,
        paymentMethod: 'MTN Mobile Money',
      );

      return PaymentResult(
        success: true,
        message: 'Payment successful! Transaction ID: $transactionId',
        transactionId: transactionId,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment error: $e',
        transactionId: null,
      );
    }
  }

  /// Simulates Airtel Money payment processing
  Future<PaymentResult> processAirtelMoneyPayment({
    required String phoneNumber,
    required double amount,
    required String description,
    required String currency,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate payment validation
      if (!_isValidPhoneNumber(phoneNumber)) {
        return PaymentResult(
          success: false,
          message: 'Invalid phone number format. Please use format: 07XXXXXXXX',
          transactionId: null,
        );
      }

      if (amount < 100) {
        return PaymentResult(
          success: false,
          message: 'Minimum payment amount is 100 FRW',
          transactionId: null,
        );
      }

      // Simulate payment processing with 90% success rate
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      final isSuccess = random < 90; // 90% success rate

      if (!isSuccess) {
        return PaymentResult(
          success: false,
          message: 'Payment failed. Please try again or check your balance.',
          transactionId: null,
        );
      }

      // Generate simulated transaction ID
      final transactionId = 'AIRTEL${DateTime.now().millisecondsSinceEpoch}';

      // Record payment in Firestore
      await _recordPayment(
        phoneNumber: phoneNumber,
        amount: amount,
        description: description,
        currency: currency,
        transactionId: transactionId,
        paymentMethod: 'Airtel Money',
      );

      return PaymentResult(
        success: true,
        message: 'Payment successful! Transaction ID: $transactionId',
        transactionId: transactionId,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment error: $e',
        transactionId: null,
      );
    }
  }

  /// Simulates card payment processing
  Future<PaymentResult> processCardPayment({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolderName,
    required double amount,
    required String description,
    required String currency,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 3));

      // Simulate card validation
      if (!_isValidCardNumber(cardNumber)) {
        return PaymentResult(
          success: false,
          message: 'Invalid card number',
          transactionId: null,
        );
      }

      if (!_isValidExpiryDate(expiryDate)) {
        return PaymentResult(
          success: false,
          message: 'Invalid expiry date',
          transactionId: null,
        );
      }

      if (!_isValidCVV(cvv)) {
        return PaymentResult(
          success: false,
          message: 'Invalid CVV',
          transactionId: null,
        );
      }

      if (amount < 100) {
        return PaymentResult(
          success: false,
          message: 'Minimum payment amount is 100 FRW',
          transactionId: null,
        );
      }

      // Simulate payment processing with 85% success rate
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      final isSuccess = random < 85; // 85% success rate

      if (!isSuccess) {
        return PaymentResult(
          success: false,
          message: 'Payment failed. Please check your card details and try again.',
          transactionId: null,
        );
      }

      // Generate simulated transaction ID
      final transactionId = 'CARD${DateTime.now().millisecondsSinceEpoch}';

      // Record payment in Firestore
      await _recordPayment(
        phoneNumber: null,
        amount: amount,
        description: description,
        currency: currency,
        transactionId: transactionId,
        paymentMethod: 'Credit/Debit Card',
        cardLastDigits: cardNumber.substring(cardNumber.length - 4),
      );

      return PaymentResult(
        success: true,
        message: 'Payment successful! Transaction ID: $transactionId',
        transactionId: transactionId,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment error: $e',
        transactionId: null,
      );
    }
  }

  /// Records payment in Firestore
  Future<void> _recordPayment({
    String? phoneNumber,
    required double amount,
    required String description,
    required String currency,
    required String transactionId,
    required String paymentMethod,
    String? cardLastDigits,
  }) async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('payments')
        .add({
      'userId': user!.uid,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'description': description,
      'currency': currency,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'cardLastDigits': cardLastDigits,
      'status': 'completed',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update user's virtual balance
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({
      'virtualBalance': FieldValue.increment(amount),
    });
  }

  /// Validates phone number format (Rwanda format)
  bool _isValidPhoneNumber(String phoneNumber) {
    // Remove any spaces or special characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid Rwanda mobile number
    // Format: 07XXXXXXXX (10 digits starting with 07)
    return cleanNumber.length == 10 && cleanNumber.startsWith('07');
  }

  /// Validates card number (Luhn algorithm)
  bool _isValidCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    // Luhn algorithm validation
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cleanNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  /// Validates expiry date
  bool _isValidExpiryDate(String expiryDate) {
    final parts = expiryDate.split('/');
    if (parts.length != 2) return false;
    
    try {
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);
      
      if (month < 1 || month > 12) return false;
      
      final now = DateTime.now();
      final currentYear = now.year % 100;
      final currentMonth = now.month;
      
      if (year < currentYear || (year == currentYear && month < currentMonth)) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validates CVV
  bool _isValidCVV(String cvv) {
    return cvv.length >= 3 && cvv.length <= 4 && RegExp(r'^\d+$').hasMatch(cvv);
  }

  /// Get payment history for user
  Stream<QuerySnapshot> getPaymentHistory() {
    if (user == null) {
      return Stream.empty();
    }
    
    return FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get payment statistics
  Future<Map<String, dynamic>> getPaymentStats() async {
    if (user == null) {
      return {};
    }

    final payments = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: user!.uid)
        .where('status', isEqualTo: 'completed')
        .get();

    double totalAmount = 0;
    int totalPayments = payments.docs.length;
    Map<String, int> paymentMethods = {};

    for (final doc in payments.docs) {
      final data = doc.data();
      totalAmount += (data['amount'] ?? 0).toDouble();
      
      final method = data['paymentMethod'] ?? 'Unknown';
      paymentMethods[method] = (paymentMethods[method] ?? 0) + 1;
    }

    return {
      'totalAmount': totalAmount,
      'totalPayments': totalPayments,
      'paymentMethods': paymentMethods,
    };
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;

  PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
  });
} 