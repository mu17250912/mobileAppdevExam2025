import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Process payment
  Future<PaymentResult> processPayment({
    required String bookingId,
    required double amount,
    required String paymentMethod,
    required String currency,
  }) async {
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate success (90% success rate for demo)
      final isSuccess = DateTime.now().millisecond % 10 != 0;
      
      if (isSuccess) {
        // Save payment record
        await _savePaymentRecord(bookingId, amount, paymentMethod, currency);
        
        return PaymentResult(
          success: true,
          transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          message: 'Payment processed successfully',
        );
      } else {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Payment failed. Please try again.',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Payment error: $e',
      );
    }
  }

  // Get payment history
  Future<List<PaymentRecord>> getPaymentHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentHistoryJson = prefs.getString('payment_history_$userId');
      
      if (paymentHistoryJson != null) {
        final List<dynamic> historyList = jsonDecode(paymentHistoryJson);
        return historyList.map((json) => PaymentRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }

  // Get payment by booking ID
  Future<PaymentRecord?> getPaymentByBookingId(String bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allPaymentsJson = prefs.getString('all_payments');
      
      if (allPaymentsJson != null) {
        final List<dynamic> allPayments = jsonDecode(allPaymentsJson);
        final paymentJson = allPayments.firstWhere(
          (payment) => payment['bookingId'] == bookingId,
          orElse: () => null,
        );
        
        if (paymentJson != null) {
          return PaymentRecord.fromJson(paymentJson);
        }
      }
      return null;
    } catch (e) {
      print('Error getting payment by booking ID: $e');
      return null;
    }
  }

  // Refund payment
  Future<PaymentResult> refundPayment({
    required String bookingId,
    required double amount,
    required String reason,
  }) async {
    try {
      // Simulate refund processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate success
      return PaymentResult(
        success: true,
        transactionId: 'REFUND_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Refund processed successfully',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Refund error: $e',
      );
    }
  }

  // Save payment record
  Future<void> _savePaymentRecord(
    String bookingId,
    double amount,
    String paymentMethod,
    String currency,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create payment record
      final paymentRecord = PaymentRecord(
        id: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: bookingId,
        amount: amount,
        paymentMethod: paymentMethod,
        currency: currency,
        status: PaymentStatus.completed,
        createdAt: DateTime.now(),
      );
      
      // Save to all payments
      final allPaymentsJson = prefs.getString('all_payments');
      List<dynamic> allPayments = [];
      
      if (allPaymentsJson != null) {
        allPayments = jsonDecode(allPaymentsJson);
      }
      
      allPayments.add(paymentRecord.toJson());
      await prefs.setString('all_payments', jsonEncode(allPayments));
      
      // Save to user's payment history
      final userId = 'demo_user'; // In real app, get from auth
      final userHistoryJson = prefs.getString('payment_history_$userId');
      List<dynamic> userHistory = [];
      
      if (userHistoryJson != null) {
        userHistory = jsonDecode(userHistoryJson);
      }
      
      userHistory.add(paymentRecord.toJson());
      await prefs.setString('payment_history_$userId', jsonEncode(userHistory));
      
    } catch (e) {
      print('Error saving payment record: $e');
    }
  }

  // Get available payment methods
  List<PaymentMethod> getAvailablePaymentMethods() {
    return [
      PaymentMethod(
        id: 'mobile_money',
        name: 'Mobile Money',
        description: 'Pay with your mobile money account',
        icon: 'assets/icons/mobile_money.png',
        isAvailable: true,
      ),
      PaymentMethod(
        id: 'card',
        name: 'Credit/Debit Card',
        description: 'Pay with your credit or debit card',
        icon: 'assets/icons/card.png',
        isAvailable: true,
      ),
      PaymentMethod(
        id: 'bank_transfer',
        name: 'Bank Transfer',
        description: 'Direct bank transfer',
        icon: 'assets/icons/bank.png',
        isAvailable: true,
      ),
    ];
  }
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String message;

  PaymentResult({
    required this.success,
    this.transactionId,
    required this.message,
  });
}

class PaymentRecord {
  final String id;
  final String bookingId;
  final double amount;
  final String paymentMethod;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;

  PaymentRecord({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'currency': currency,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'],
      bookingId: json['bookingId'],
      amount: json['amount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      currency: json['currency'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isAvailable;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isAvailable,
  });
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
} 